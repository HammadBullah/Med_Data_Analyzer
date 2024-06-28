import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dash/flutter_dash.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:open_file/open_file.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        buttonTheme: const ButtonThemeData(
          buttonColor: Colors.orange,
          textTheme: ButtonTextTheme.primary,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.orange,
          ),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _file;
  List<Map<String, dynamic>> data = [];
  String? selectedName;
  List<String> names = [];
  String? selectedParameter;
  List<String> parameters = [
    'BMI',
    'Blood Pressure',
    'Heart Rate',
    'SpO2',
    'Temperature',
    'Blood Glucose',
  ];

  Future<void> _pickFile() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx']);
    if (result != null) {
      setState(() {
        _file = File(result.files.single.path!);
        _analyzeData();
      });
    }
  }

  void _analyzeData() {
  if (_file == null) return;

  var bytes = _file!.readAsBytesSync();
  var excel = Excel.decodeBytes(bytes);

  data.clear();
  names.clear();
  for (var table in excel.tables.keys) {
    for (var row in excel.tables[table]!.rows) {
      if (row.isNotEmpty) {
        var name = row[0]?.value?.toString(); // Handle potential null value
        data.add({
          'Name': name ?? 'Unknown', // Provide a default value if null
          'Date of Birth': row[1]?.value?.toString() ?? '',
          'Father/Spouse Name': row[2]?.value?.toString() ?? '',
          'Contact Number': row[3]?.value?.toString() ?? '',
          'Address': row[4]?.value?.toString() ?? '',
          'Alternative Number': row[5]?.value?.toString() ?? '',
          'Aadhar Number': row[6]?.value?.toString() ?? '',
          'Height': int.tryParse(row[7]?.value?.toString() ?? '') ?? 0,
          'Weight': int.tryParse(row[8]?.value?.toString() ?? '') ?? 0,
          'High BP': int.tryParse(row[9]?.value?.toString() ?? '') ?? 0,
          'Low BP': int.tryParse(row[10]?.value?.toString() ?? '') ?? 0,
          'Heart Rate': int.tryParse(row[11]?.value?.toString() ?? '') ?? 0,
          'SpO2': int.tryParse(row[12]?.value?.toString() ?? '') ?? 0,
          'Temperature': int.tryParse(row[13]?.value?.toString() ?? '') ?? 0,
          'Blood Glucose': int.tryParse(row[14]?.value?.toString() ?? '') ?? 0,
        });
        names.add(name ?? 'Unknown');
      }
    }
  }

  setState(() {
    selectedName = names.isNotEmpty ? names[0] : null;
  });
}

double _calculateBMI(int? heightCm, int? weightKg) {
  if (heightCm == null || weightKg == null || heightCm <= 0 || weightKg <= 0) {
    return 0.0; // Handle division by zero or null cases
  }
  double heightM = heightCm / 100;
  return weightKg / (heightM * heightM);
}

bool _isAbnormal(value, min, max) {
  if (value == null) return false; // Handle null case gracefully
  if (value < min) return true;
  if (max != null && value > max) return true;
  return false;
}

  Future<void> _generateReportForSelectedName() async {
    if (selectedName == null) return;

    var selectedData = data.firstWhere((element) => element['Name'] == selectedName);
    var reportFile = await _generateReport(selectedData);

    // Show a snackbar to indicate report generation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Report generated: ${reportFile.path}')),
    );

    // Open the generated report file
    await OpenFile.open(reportFile.path);
  }

  Future<void> _generateReportForSelectedParameter() async {
    if (selectedParameter == null) return;

    var reportFile = await _generateParameterReport();

    // Show a snackbar to indicate report generation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Report generated for $selectedParameter: ${reportFile.path}')),
    );

    // Open the generated report file
    await OpenFile.open(reportFile.path);
  }

  Future<File> _generateReport(Map<String, dynamic> patientData) async {
    final pdf = pw.Document();

    _addTitle(pdf);
    _addPatientInfo(pdf, patientData);
    _addAbnormalities(pdf, patientData);

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/patient_report_${patientData['Name']}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  Future<File> _generateParameterReport() async {
    final pdf = pw.Document();

    _addTitle(pdf);
    _addParameterAbnormalities(pdf, data, selectedParameter!);

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/parameter_report_${selectedParameter}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  void _addTitle(pw.Document pdf) {
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Text(
              'Patient Report',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
          );
        },
      ),
    );
  }

  void _addPatientInfo(pw.Document pdf, Map<String, dynamic> patientData) {
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Table.fromTextArray(
            headers: const <String>['Parameter', 'Value'],
            data: <List<String>>[
              <String>['Name', patientData['Name']!],
              <String>['Date of Birth', patientData['Date of Birth']!],
              <String>['Father/Spouse Name', patientData['Father/Spouse Name']!],
              <String>['Contact Number', patientData['Contact Number']!],
              <String>['Address', patientData['Address']!],
              <String>['Alternative Number', patientData['Alternative Number']!],
              <String>['Aadhar Number', patientData['Aadhar Number']!],
              <String>['Height', '${patientData['Height']} cm'],
              <String>['Weight', '${patientData['Weight']} kg'],
              <String>['High BP', '${patientData['High BP']} mmHg'],
              <String>['Low BP', '${patientData['Low BP']} mmHg'],
              <String>['Heart Rate', '${patientData['Heart Rate']} bpm'],
              <String>['SpO2', '${patientData['SpO2']} %'],
              <String>['Temperature', '${patientData['Temperature']} °F'],
              <String>['Blood Glucose', '${patientData['Blood Glucose']} mg/dL'],
            ],
          );
        },
      ),
    );
  }

  void _addAbnormalities(pw.Document pdf, Map<String, dynamic> patientData) {
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          List<List<String>> abnormalities = [];

          // Check for BMI
          double bmi = _calculateBMI(patientData['Height'], patientData['Weight']);
          if (_isAbnormal(bmi, 18.5, 30)) {
            if (bmi < 18.5) {
              abnormalities.add([
                'BMI',
                '${bmi.toStringAsFixed(1)}',
                'Underweight',
                'Increase food intake and ensure a balanced diet',
              ]);
            } else if (bmi >= 30) {
              abnormalities.add([
                'BMI',
                '${bmi.toStringAsFixed(1)}',
                'Obesity',
                'Adopt a healthier diet and regular exercise',
              ]);
            }
          }

          // Check for Blood Pressure
          int highBP = patientData['High BP'];
          int lowBP = patientData['Low BP'];
          if (_isAbnormal(highBP, 120, null) || _isAbnormal(lowBP, 80, null)) {
            abnormalities.add([
              'Blood Pressure',
              '${highBP}/${lowBP} mmHg',
              'Hypotension',
              'Use more salts, drink more water, eat smaller meals and limit alcohol. Check for your blood glucose level and thyroid level and wear compression stockings. Get yourself seen to a medical supervisor for any infection alert.',
            ]);
          }
          if (_isAbnormal(highBP, 0, 140) || _isAbnormal(lowBP, 0, 90)) {
            abnormalities.add([
              'Blood Pressure',
              '${highBP}/${lowBP} mmHg',
              'Hypertension',
              'Reduce salt (sodium) intake, quit smoking and limit alcohol, include healty protein-rich foods such as fish, seafood, legumes, yoghurt, healthy fats and oils, etc. Practice healthy excercise and weight control. Check your blood glucose and thyroid level. Get checked by a medical supervisor.',
            ]);
          }

          // Check for Heart Rate
          int heartRate = patientData['Heart Rate'];
          if (_isAbnormal(heartRate, 60, null)) {
            abnormalities.add([
              'Heart Rate',
              '${heartRate} bpm',
              'Bradycardia',
              'Eat magnesium rich foods such as nuts, cereals, spinach, etc. Foods rich in Omega-3-FA such as walnuts, vegetable oils, seafoods, etc. Cardioprotective foods suc has green vegetables, fresh fruits, etc. Food containing stimulants such as alcohol, beer, coffee, chocolate, etc should be avoided. Perform light and gentle excercises such as walking and do a regulat medical checkup.',
            ]);
          }
          if (_isAbnormal(heartRate, 0, 100)) {
            abnormalities.add([
              'Heart Rate',
              '${heartRate} bpm',
              'Tachycardia',
              'Consult a Doctor.',
            ]);
          }

          // Check for SpO2
          int spO2 = patientData['SpO2'];
          if (_isAbnormal(spO2, 95, 100)) {
            abnormalities.add([
              'SpO2',
              '${spO2} %',
              'Low Oxygen Saturation',
              'Seek medical attention',
            ]);
          }
          

          // Check for Temperature
          int temperature = patientData['Temperature'];
          if (_isAbnormal(temperature, 96, null)) {
            abnormalities.add([
              'Temperature',
              '${temperature} °F',
              'Abnormal Temperature',
              'Monitor and consult a healthcare provider if necessary',
            ]);
          }
          if (_isAbnormal(temperature, 0, 100)) {
            abnormalities.add([
              'Temperature',
              '${temperature} °F',
              'Abnormal Temperature',
              'Monitor and consult a healthcare provider if necessary',
            ]);
          }

          // Check for Blood Glucose
          int bloodGlucose = patientData['Blood Glucose'];
          if (_isAbnormal(bloodGlucose, 70, 140)) {
            abnormalities.add([
              'Blood Glucose',
              '${bloodGlucose} mg/dL',
              'Abnormal Blood Glucose',
              'Maintain a healthy diet and monitor glucose levels',
            ]);
          }

          return pw.Table.fromTextArray(
            headers: <String>[
              'Parameter',
              'Value',
              'Abnormality',
              'Suggestion',
            ],
            data: abnormalities,
          );
        },
      ),
    );
  }

  void _addParameterAbnormalities(pw.Document pdf, List<Map<String, dynamic>> data, String parameter) {
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          List<List<String>> abnormalities = [];
          for (var patientData in data) {
            switch (parameter) {
              case 'BMI':
                double bmi = _calculateBMI(patientData['Height'], patientData['Weight']);
                if (_isAbnormal(bmi, 18.5, 30)) {
                  if (bmi < 18.5) {
                    abnormalities.add([
                      patientData['Name'],
                      '${bmi.toStringAsFixed(1)}',
                      'Underweight',
                      'Increase food intake and ensure a balanced diet',
                    ]);
                  } else if (bmi >= 30) {
                    abnormalities.add([
                      patientData['Name'],
                      '${bmi.toStringAsFixed(1)}',
                      'Obesity',
                      'Adopt a healthier diet and regular exercise',
                    ]);
                  }
                }
                break;
              case 'Blood Pressure':
                int highBP = patientData['High BP'];
                int lowBP = patientData['Low BP'];
                if (_isAbnormal(highBP, 120, null) || _isAbnormal(lowBP, 80, null)) {
                  abnormalities.add([
                    patientData['Name'],
                    '${highBP}/${lowBP} mmHg',
              'Hypotension',
              'Use more salts, drink more water, eat smaller meals and limit alcohol. Check for your blood glucose level and thyroid level and wear compression stockings. Get yourself seen to a medical supervisor for any infection alert.',
                  ]);
                }else if(_isAbnormal(highBP, 0, 140) || _isAbnormal(lowBP, 0, 90)) {
                  abnormalities.add([
                    patientData['Name'],
                    '${highBP}/${lowBP} mmHg',
              'HyperTension',
              'Reduce salt (sodium) intake, quit smoking and limit alcohol, include healty protein-rich foods such as fish, seafood, legumes, yoghurt, healthy fats and oils, etc. Practice healthy excercise and weight control. Check your blood glucose and thyroid level. Get checked by a medical supervisor.',
                  ]);
                }
                break;
              case 'Heart Rate':
                int heartRate = patientData['Heart Rate'];
                if (_isAbnormal(heartRate, 60, null)) {
                  abnormalities.add([
                    patientData['Name'],
                    '${heartRate} bpm',
                    'low Heart Rate',
                    'Consult a healthcare provider',
                  ]);
                }else if (_isAbnormal(heartRate, 0, 100)) {
                  abnormalities.add([
                    patientData['Name'],
                    '${heartRate} bpm',
                    'High Heart Rate',
                    'Consult a healthcare provider',
                  ]);
                }
                break;
              case 'SpO2':
                int spO2 = patientData['SpO2'];
                if (_isAbnormal(spO2, 95, 100)) {
                  abnormalities.add([
                    patientData['Name'],
                    '${spO2} %',
                    'Low Oxygen Saturation',
                    'Seek medical attention',
                  ]);
                }
                break;
              case 'Temperature':
                int temperature = patientData['Temperature'];
                if (_isAbnormal(temperature, 96, null)) {
                  abnormalities.add([
                    patientData['Name'],
                    '${temperature} °F',
                    'Abnormal Temperature',
                    'Monitor and consult a healthcare provider if necessary',
                  ]);
                }else if(_isAbnormal(temperature, null, 100)) {
                  abnormalities.add([
                    patientData['Name'],
                    '${temperature} °F',
                    'High Temperature',
                    'Monitor and consult a healthcare provider if necessary',
                  ]);
                }
                break;
              case 'Blood Glucose':
                int bloodGlucose = patientData['Blood Glucose'];
                if (_isAbnormal(bloodGlucose, 70, 140)) {
                  abnormalities.add([
                    patientData['Name'],
                    '${bloodGlucose} mg/dL',
                    'Abnormal Blood Glucose',
                    'Maintain a healthy diet and monitor glucose levels',
                  ]);
                }
                break;
              default:
                break;
            }
          }
          return pw.Table.fromTextArray(
          headers: <String>[
            'Parameter',
            'Value',
            'Abnormality',
          ],
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellAlignment: pw.Alignment.centerLeft,
          data: abnormalities.map((row) {
            return [
              row[0], // Parameter
              row[1], // Value
              row[2], // Abnormality
              pw.Container(
                width: double.infinity,
                child: pw.Text(
                  row[3], // Suggestion
                  softWrap: true,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ];
          }).toList(),
          columnWidths: {
            0: pw.FixedColumnWidth(100), // Adjust column widths as needed
            1: pw.FixedColumnWidth(70),
            2: pw.FixedColumnWidth(120),
          },
          cellStyle: const pw.TextStyle(
          ),
          cellHeight: 30,
  
        );
        
      },
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [
                Color.fromARGB(255, 87, 29, 125),
                Color.fromARGB(255, 24, 10, 65), // Dark purple
              ],
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(119, 23, 186, 1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: SvgPicture.asset(
                        'assets/images/12085808_20944293.svg',
                        height: 500,
                        width: 400,
                      ),
                    ),
                  ],
                ),
              )),
              const Padding(
                padding: EdgeInsets.all(50),
                child: Dash(
                  direction: Axis.vertical,
                  length: 467,
                  dashLength: 5,
                  dashThickness: 1,
                  dashColor: Color.fromRGBO(119, 23, 186, 1),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(118, 23, 186, 0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: SvgPicture.asset(
                        'assets/images/Analyze.svg',
                        height: 100,
                        width: 100,
                      ),
                    ),
                    const Text(
                      'Medical Analyzer',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color.fromARGB(221, 255, 255, 255)),
                    ),
                    const SizedBox(height: 50),
                    ElevatedButton(
                      onPressed: _pickFile,
                      child: const Text('Select File to Analyze', style: TextStyle()),
                    ),
                    if (_file != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('Selected file: ${_file!.path}', style: const TextStyle(color: Color.fromARGB(255, 173, 173, 173))),
                      ),
                    const SizedBox(height: 50),
                    if (names.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(30, 0, 30, 0),
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Color.fromARGB(0, 33, 149, 243), width: 1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            border: OutlineInputBorder(
                              borderSide: const BorderSide(color: Color.fromARGB(0, 33, 149, 243), width: 2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            filled: true,
                            fillColor: Colors.orange,
                          ),
                          value: selectedName,
                          dropdownColor: Colors.deepPurple,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedName = newValue!;
                            });
                          },
                          items: names.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    const SizedBox(
                      height: 30,
                    ),
                    if (selectedName != null)
                      ElevatedButton(
                        onPressed: _generateReportForSelectedName,
                        child: Text('Download Report for $selectedName', style: const TextStyle()),
                      ),
                    const SizedBox(height: 16),

                  const SizedBox(height: 16),
                  DropdownButton<String>(
                    value: selectedParameter,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedParameter = newValue;
                      });
                    },
                    items: parameters
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _generateReportForSelectedParameter,
                    child: const Text('Generate Parameter Report'),
                  ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

