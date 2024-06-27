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
          var name = row[0]?.value.toString();
          data.add({
            'Name': name,
            'Date of Birth': row[1]?.value.toString(),
            'Father/Spouse Name': row[2]?.value.toString(),
            'Contact Number': row[3]?.value.toString(),
            'Address': row[4]?.value.toString(),
            'Alternative Number': row[5]?.value.toString(),
            'Aadhar Number': row[6]?.value.toString(),
            'Height': int.tryParse(row[7]!.value.toString()) ?? 0,
            'Weight': int.tryParse(row[8]!.value.toString()) ?? 0,
            'High BP': int.tryParse(row[9]!.value.toString()) ?? 0,
            'Low BP': int.tryParse(row[10]!.value.toString()) ?? 0,
            'Heart Rate': int.tryParse(row[11]!.value.toString()) ?? 0,
            'SpO2': int.tryParse(row[12]!.value.toString()) ?? 0,
            'Temperature': int.tryParse(row[13]!.value.toString()) ?? 0,
            'Blood Glucose': int.tryParse(row[14]!.value.toString()) ?? 0,
          });
          names.add(name ?? 'Unknown');
        }
      }
    }

    setState(() {
      selectedName = names.isNotEmpty ? names[0] : null;
    });
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
            abnormalities.addAll([
              ['BMI', '${bmi.toStringAsFixed(1)}', ''],
              ['Underweight', 'Increase food intake, take nutrient-rich foods, take protein and weight gainer supplements. Get checked by a medical supervisor for any underlying infections or diseases that can cause low weight.', ''],
              ['Obesity', 'Control diet, eat less junk food, control salt and sugar levels. Perform exercises such as weight lifting and cardio exercise, practice active lifestyle. Get checked for thyroid and any possible infections that can cause weight gain.', ''],
            ]);
          }

          // Check for Blood Pressure
          int highBP = patientData['High BP'];
          int lowBP = patientData['Low BP'];
          if (_isAbnormal(highBP, 120, null) || _isAbnormal(lowBP, 80, null)) {
            abnormalities.addAll([
              ['Blood Pressure', 'Low-optimal ', 'Check blood glucose and thyroid levels. Wear compression stockings. Get checked by a medical supervisor for any infection alert.'],
            ]);
          }
          if (_isAbnormal(highBP, null, 140) || _isAbnormal(lowBP, null, 90)) {
            abnormalities.addAll([
              ['Blood Pressure', 'High', 'Reduce salt (sodium) intake, quit smoking and limit alcohol, include healty protein-rich foods such as fish, seafood, legumes, yoghurt, healthy fats and oils, etc.'],
            ]);
          }

          // Check for Heart Rate
          int heartRate = patientData['Heart Rate'];
          if (_isAbnormal(heartRate, 60, null)) {
            abnormalities.addAll([
              ['Heart Rate', 'Low', 'Eat magnesium-rich foods such as nuts, cereals, spinach, etc. Eat Omega-3-Fatty Acids rich foods such as walnuts, vegetable oils, seafood, etc. Cardioprotective foods such as green vegetables, fresh fruits, etc. Avoid stimulants like alcohol, beer, coffee, chocolate, etc.'],
            ]);
          }
          if (_isAbnormal(heartRate, null, 100)) {
            abnormalities.addAll([
              ['Heart Rate', 'High', 'Perform light and gentle exercises such as walking. Do regular medical checkups.'],
            ]);
          }

          if (abnormalities.isEmpty) {
            abnormalities.add(['No abnormalities detected.', 'Report is normal',]);
                        return pw.Text(
              'No abnormalities detected.',
              style: pw.TextStyle(fontWeight: pw.FontWeight.normal, fontSize: 14),
            );
          }

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Abnormalities:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
              ),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: const ['Parameter', 'Inference', 'Dietary Recommendations'],
                data: abnormalities,
              ),
            ],
          );
        },
      ),
    );
  }

  void _addRecommendations(pw.Document pdf, Map<String, dynamic> patientData) {
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          List<List<String>> recommendations = [];

          // Check for BMI recommendations
          double bmi = _calculateBMI(patientData['Height'], patientData['Weight']);
          if (_isAbnormal(bmi, 18.5, 30)) {
            if (bmi < 18.5) {
              recommendations.add([
                'BMI',
                'Underweight',
                'Increase food intake, take nutrient-rich foods, take protein and weight gainer supplements. Get checked by a medical supervisor for any underlying infections or diseases that can cause low weight.',
              ]);
            } else if (bmi >= 30) {
              recommendations.add([
                'BMI',
                'Obesity',
                'Control diet, eat less junk food, control salt and sugar levels. Perform exercises such as weight lifting and cardio exercise, practice active lifestyle. Get checked for thyroid and any possible infections that can cause weight gain.',
              ]);
            }
          }

          // Display recommendations in a formatted manner
          if (recommendations.isEmpty) {
            recommendations.add(['No recommendations needed.', '']);
          }

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Recommendations:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
              ),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: const ['Parameter', 'Recommendation'],
                data: recommendations,
              ),
            ],
          );
        },
      ),
    );
  }

  double _calculateBMI(dynamic height, dynamic weight) {
    if (height == null || weight == null) return 0.0;

    double heightInMeters = height / 100; // Convert height from cm to meters
    return weight / (heightInMeters * heightInMeters);
  }

  bool _isAbnormal(dynamic value, double? lowerRange, double? upperRange) {
    if (value == null || value is! num) return false;
    double parsedValue = value.toDouble();
    return (lowerRange != null && parsedValue < lowerRange) || (upperRange != null && parsedValue > upperRange);
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
              ),
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
                    Text(
                      'Medical Analyzer',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: const Color.fromARGB(221, 255, 255, 255)),
                    ),
                    const SizedBox(height: 50),
                    ElevatedButton(
                      onPressed: _pickFile,
                      child: Text('Select File to Analyze', style: TextStyle()),
                    ),
                    if (_file != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('Selected file: ${_file!.path}', style: TextStyle(color: const Color.fromARGB(255, 173, 173, 173))),
                      ),
                    const SizedBox(height: 50),
                    if (names.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(100, 0, 100, 0),
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Color.fromARGB(0, 33, 149, 243), width: 2),
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
                        child: Text('Download Report for $selectedName', style: TextStyle()),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

