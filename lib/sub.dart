import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SubstituteMedicinePage extends StatefulWidget {
  @override
  _SubstituteMedicinePageState createState() => _SubstituteMedicinePageState();
}

class _SubstituteMedicinePageState extends State<SubstituteMedicinePage> {
  final TextEditingController _medicineController = TextEditingController();
  String? rxcui;
  List<Map<String, String>> substitutes = [];
  bool isLoading = false;
  bool hasSearched = false;

  // Base URL for RxNorm API
  final String _rxNormBaseUrl = "https://rxnav.nlm.nih.gov/REST";

  Future<void> fetchSubstituteMedicines(String medicine) async {
    setState(() {
      isLoading = true;
      rxcui = null;
      substitutes.clear();
      hasSearched = true; // Set to true when a search is initiated
    });

    try {
      // Step 1: Fetch RxCUI for the entered medicine
      final rxcuiResponse = await http.get(
        Uri.parse("$_rxNormBaseUrl/rxcui.json?name=$medicine"),
      );
      if (rxcuiResponse.statusCode != 200) {
        throw Exception(
            "Failed to fetch RxCUI. Status code: ${rxcuiResponse.statusCode}");
      }

      final rxcuiData = jsonDecode(rxcuiResponse.body);
      final fetchedRxcui = rxcuiData["idGroup"]["rxnormId"]?.first;

      if (fetchedRxcui == null) {
        throw Exception("No RxCUI found for the entered medicine.");
      }

      setState(() {
        rxcui = fetchedRxcui;
      });

      // Step 2: Fetch substitutes using the related API
      final relatedResponse = await http.get(
        Uri.parse("$_rxNormBaseUrl/rxcui/$fetchedRxcui/related.json?tty=SCD"),
      );
      if (relatedResponse.statusCode != 200) {
        throw Exception(
            "Failed to fetch related medicines. Status code: ${relatedResponse.statusCode}");
      }

      final relatedData = jsonDecode(relatedResponse.body);
      final conceptGroups = relatedData["relatedGroup"]["conceptGroup"] ?? [];

      final substitutesList = <Map<String, String>>[];
      for (var group in conceptGroups) {
        if (group["conceptProperties"] != null) {
          substitutesList.addAll(
            (group["conceptProperties"] as List<dynamic>).map((item) {
              final Map<String, dynamic> property =
                  item as Map<String, dynamic>;
              return {
                "name": property["name"]?.toString() ?? "Unknown",
                "rxcui": property["rxcui"]?.toString() ?? "Unknown",
              };
            }).toList(),
          );
        }
      }

      setState(() {
        substitutes = substitutesList;
      });
    } catch (e) {
      debugPrint("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String toTitleCase(String input) {
    return input
        .split(' ')
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : '')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Substitute Medicine Finder'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _medicineController,
              decoration: InputDecoration(
                labelText: 'Enter Medicine Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_medicineController.text.isNotEmpty) {
                  fetchSubstituteMedicines(_medicineController.text.trim());
                }
              },
              child: Text('Suggest'),
            ),
            SizedBox(height: 16),
            if (isLoading)
              Center(child: CircularProgressIndicator())
            else if (hasSearched) ...[
              if (rxcui != null)
                Card(
                  color: Colors.blue[50],
                  margin: EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RxCUI:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.blue[900],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          rxcui!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Card(
                color: Colors.green[50],
                margin: EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: substitutes.isNotEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Substitute Medicines:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.green[900],
                              ),
                            ),
                            SizedBox(height: 8),
                            ...substitutes.asMap().entries.map((entry) {
                              final index =
                                  entry.key + 1; // Numbering starts at 1
                              final substitute = entry.value;
                              final name =
                                  toTitleCase(substitute["name"] ?? "Unknown");
                              return Text(
                                "$index. $name (RxCUI: ${substitute["rxcui"] ?? "Unknown"})",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.green[800],
                                ),
                              );
                            }),
                          ],
                        )
                      : Text(
                          'No substitutes found.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.red[800],
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
