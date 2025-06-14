import 'package:flutter/material.dart';
import 'package:flutter_flight_checker/ui/airport_autocomplete_input.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FlightSearchScreen extends StatefulWidget {
  const FlightSearchScreen({super.key});

  @override
  State<FlightSearchScreen> createState() => _FlightSearchScreenState();
}

class _FlightSearchScreenState extends State<FlightSearchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _departStationController = TextEditingController(text: 'KUL');
  final _arrivalStationController = TextEditingController(text: 'KCH');
  final _beginDateController = TextEditingController(text: '20/06/2025');
  final _endDateController = TextEditingController(text: '31/08/2025');
  final _currencyController = TextEditingController(text: 'MYR');
  String _response = '';
  String _bearerToken = '';
  bool _isLoading = false;

  String _extractToken(String body) {
    final chunk1 = body.split('{"pageProps":{"jwtToken":"')[1];
    final chunk2 = chunk1.split('"')[0];

    final jwtToken = chunk2;

    return jwtToken;
  }

  Future<void> _searchFlights() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _response = '';
    });

    final url = Uri.parse(
      'https://flights.airasia.com/fp/lfc/v1/lowfare'
      '?departStation=${_departStationController.text.split(',').first.trim()}' // trim to get only the code
      '&arrivalStation=${_arrivalStationController.text.split(',').first.trim()}' // trim to get only the code
      '&beginDate=${_beginDateController.text}'
      '&endDate=${_endDateController.text}'
      '&currency=${_currencyController.text}'
      '&isDestinationCity=true'
      '&isOriginCity=true',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $_bearerToken",
          "channel_hash":
              "c5e9028b4295dcf4d7c239af8231823b520c3cc15b99ab04cde71d0ab18d65bc",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _response = const JsonEncoder.withIndent('  ').convert(data);
        });
      } else {
        setState(() {
          _response = 'Error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getToken() async {
    final url = Uri.parse('https://www.airasia.com/en/gb');

    try {
      final response = await http.get(
        url,
        headers: {
          "Origin": 'https://www.airasia.com',
          "Access-Control-Allow-Origin": '*',
          'Content-Type': 'application/json',
          "User-Agent":
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36',
        },
      );

      if (response.statusCode == 200) {
        _bearerToken = _extractToken(response.body);
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    _getToken();

    super.initState();
  }

  @override
  void dispose() {
    _departStationController.dispose();
    _arrivalStationController.dispose();
    _beginDateController.dispose();
    _endDateController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AirAsia Flight Search')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 400,
                    child: AirportAutocompleteInput(
                      title: 'Departure Station (e.g., KCH)',
                      onSelected: (String selection) {
                        _departStationController.text = selection;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 400,
                    child: AirportAutocompleteInput(
                      title: 'Arrival Station (e.g., KUL)',
                      onSelected: (String selection) {
                        _arrivalStationController.text = selection;
                      },
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _beginDateController,
                decoration: const InputDecoration(
                  labelText: 'Begin Date (DD/MM/YYYY)',
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _endDateController,
                decoration: const InputDecoration(
                  labelText: 'End Date (DD/MM/YYYY)',
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _currencyController,
                decoration: const InputDecoration(
                  labelText: 'Currency (e.g., MYR)',
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _searchFlights,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Search Flights'),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: SingleChildScrollView(
                    child: Text(
                      _response.isEmpty ? 'No response yet' : _response,
                      style: const TextStyle(fontFamily: 'Courier New'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
