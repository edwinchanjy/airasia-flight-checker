import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AirportAutocompleteInput extends StatefulWidget {
  const AirportAutocompleteInput({
    super.key,
    required this.title,
    required this.onSelected,
  });

  final String title;
  final void Function(String selectedAirport) onSelected;

  @override
  State<AirportAutocompleteInput> createState() =>
      _AirportAutocompleteInputState();
}

class _AirportAutocompleteInputState extends State<AirportAutocompleteInput> {
  // The query currently being searched for. If null, there is no pending
  // request.
  String? _searchingWithQuery;

  // The most recent options received from the API.
  late Iterable<Airport> _lastOptions = <Airport>[];

  @override
  Widget build(BuildContext context) {
    return Autocomplete<Airport>(
      displayStringForOption: (Airport option) => option.StationName,
      fieldViewBuilder:
          (
            BuildContext context,
            TextEditingController textEditingController,
            FocusNode focusNode,
            VoidCallback onFieldSubmitted,
          ) {
            return TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: 'Departure Station',
                hintText: "(e.g., KCH)",
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please select an airport';
                }
                // Check if the value matches any of the available options
                final matchingOption = _lastOptions.where(
                  (airport) =>
                      airport.StationName == value ||
                      airport.StationCode == value ||
                      airport.toString().contains(value),
                );
                if (matchingOption.isEmpty) {
                  return 'Please select a valid airport from the list';
                }
                return null;
              },
              onFieldSubmitted: (String value) {
                onFieldSubmitted();
              },
            );
          },
      optionsBuilder: (TextEditingValue textEditingValue) async {
        _searchingWithQuery = textEditingValue.text;
        final Iterable<Airport> options = await _GetAirportAPI.search(
          _searchingWithQuery!,
        );

        // If another search happened after this one, throw away these options.
        // Use the previous options instead and wait for the newer request to
        // finish.
        if (_searchingWithQuery != textEditingValue.text) {
          return _lastOptions;
        }
        _lastOptions = options;
        return options;
      },
      optionsViewBuilder:
          (
            BuildContext context,
            AutocompleteOnSelected<Airport> onSelected,
            Iterable<Airport> options,
          ) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: Container(
                  constraints: const BoxConstraints(
                    maxHeight: 200,
                    maxWidth: 300,
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Airport option = options.elementAt(index);
                      return InkWell(
                        onTap: () => onSelected(option),
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option.StationName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${option.CityName}, ${option.CountryName}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Code: ${option.StationCode}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
      onSelected: (Airport selection) {
        widget.onSelected.call(selection.StationCode);
      },
    );
  }
}

class _GetAirportAPI {
  static List<Airport> _kOptions = <Airport>[];

  static Future<Iterable<Airport>> search(String query) async {
    if (query == '') {
      return const Iterable<Airport>.empty();
    }

    final url = Uri.parse(
      'https://flights.airasia.com/travel/stations/search/airports?locale=en-gb&query=${query.toLowerCase()}',
    );

    final response = await http.get(url);

    final data = jsonDecode(response.body);

    if (data is! List) {
      return [];
    }

    final List<Airport> airports = data
        .map((json) => Airport.fromJson(json as Map<String, dynamic>))
        .toList();

    _kOptions = airports;

    return _kOptions;
  }
}

// ignore_for_file: non_constant_identifier_names
// ignoring this because the API returns these names in camelCase

@immutable
class Airport {
  const Airport({
    this.AAFlight,
    this.AirportName,
    this.AlternativeName,
    this.PinYin, // line 109 to 115 seems useless, but keeping for consistency
    this.Tag,
    this.TimeZone,
    this.id,
    this.isActive,
    this.md5hash,
    this.Provider,
    required this.iconName,
    required this.CityCode,
    required this.CityName,
    required this.CountryCode,
    required this.CountryName,
    required this.StationCode,
    required this.StationName,
    required this.Weightage,
    required this.Lat,
    required this.Long,
    required this.StationType,
    required this.Dest,
    this.Stations,
  });

  // Add factory constructor
  factory Airport.fromJson(Map<String, dynamic> json) {
    return Airport(
      AAFlight: (json['AAFlight'] == "true") as bool?,
      AirportName: json['AirportName'] as String?,
      AlternativeName: json['AlternativeName'] as String?,
      PinYin: json['PinYin'] as String?,
      Tag: json['Tag'] as String?,
      TimeZone: json['TimeZone'] as String?,
      id: json['id'] as String?,
      isActive: (json['isActive'] == "true") as bool?,
      md5hash: json['md5hash'] as String?,
      Provider: json['Provider'] as String?,
      iconName: json['iconName'] as String? ?? '',
      CityCode: json['CityCode'] as String? ?? '',
      CityName: json['CityName'] as String? ?? '',
      CountryCode: json['CountryCode'] as String? ?? '',
      CountryName: json['CountryName'] as String? ?? '',
      StationCode: json['StationCode'] as String? ?? '',
      StationName: json['StationName'] as String? ?? '',
      Weightage: (json['Weightage'] as num?)?.toDouble() ?? 0.0,
      Lat: (json['Lat'] as num?)?.toDouble() ?? 0.0,
      Long: (json['Long'] as num?)?.toDouble() ?? 0.0,
      StationType: json['StationType'] as String? ?? '',
      Dest: json['Dest'] as String? ?? '',
      Stations: json['Stations'] != null
          ? (json['Stations'] as List)
                .map(
                  (station) =>
                      Airport.fromJson(station as Map<String, dynamic>),
                )
                .toList()
          : null,
    );
  }

  final bool? AAFlight;
  final String? AirportName;
  final String? AlternativeName;
  final String? PinYin;
  final String? Tag;
  final String? TimeZone;
  final String? id;
  final bool? isActive;
  final String? md5hash;
  final String? Provider;
  final String iconName;
  final String CityCode;
  final String CityName;
  final String CountryCode;
  final String CountryName;
  final String StationCode;
  final String StationName;
  final double Weightage;
  final double Lat;
  final double Long;
  final String StationType;
  final String Dest;
  final List<Airport>? Stations;

  @override
  String toString() {
    return '${(Stations != null && Stations!.isNotEmpty) ? "$CityName (All Airports)" : AirportName}';
  }
}
