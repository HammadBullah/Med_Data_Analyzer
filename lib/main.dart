import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dash/flutter_dash.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
            foregroundColor: Colors.white, backgroundColor: Colors.orange,
          ),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

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
    if (result!= null) {
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
            'Height': int.tryParse(row[7]!.value.toString())?? 0, // Convert to int
            'Weight': int.tryParse(row[8]!.value.toString())?? 0, // Convert to int
            'High BP': int.tryParse(row[9]!.value.toString())?? 0, // Convert to int
            'Low BP': int.tryParse(row[10]!.value.toString())?? 0, // Convert to int
            'Heart Rate': int.tryParse(row[11]!.value.toString())?? 0, // Convert to int
            'SpO2': int.tryParse(row[12]!.value.toString())?? 0, // Convert to int
            'Temperature': int.tryParse(row[13]!.value.toString())?? 0, // Convert to int
            'Blood Glucose': int.tryParse(row[14]!.value.toString())?? 0, // Convert to int
          });
          names.add(name?? 'Unknown');
        }
      }
    }

    setState(() {
      selectedName = names.isNotEmpty? names[0] : null;
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
    _addRecommendations(pdf, patientData);

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
            child:pw.Text(
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
          return pw.Table.fromTextArray(
            headers: const <String>['Parameter', 'Value', 'Normal Range'],
            data: <List<String>>[
              <String>['Height', '${patientData['Height']} cm', '150-190 cm'],
              <String>['Weight', '${patientData['Weight']} kg', '50-90 kg'],
              <String>['High BP', '${patientData['High BP']} mmHg', '120-140 mmHg'],
              <String>['Low BP', '${patientData['Low BP']} mmHg', '60-120 mmHg'],
              <String>['Heart Rate', '${patientData['Heart Rate']} bpm', '60-100 bpm'],
              <String>['SpO2', '${patientData['SpO2']} %', '95-100 %'],
              <String>['Temperature', '${patientData['Temperature']} °F', '92-98.6 °F'],
              <String>['Blood Glucose', '${patientData['Blood Glucose']} mg/dL', '70-140 mg/dL'],
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
          return pw.Table.fromTextArray(
            headers: const <String>['Parameter', 'Recommendation'],
            data: <List<String>>[
              if (_isAbnormal(patientData['Height'], 150, 190))
                <String>['Height', 'Consult a physician.'],
              if (_isAbnormal(patientData['Weight'], 50, 90))
                <String>['Weight', 'Consult a physician.'],
              if (_isAbnormal(patientData['High BP'], 120, 140))
                <String>['High BP', 'Consult a Cardiologist and reduce salt intake.'],
              if (_isAbnormal(patientData['Low BP'], 60, 120))
                <String>['Low BP', 'Consult a General Physician and increase fluid and salt intake.'],
              if (_isAbnormal(patientData['Heart Rate'], 60, 100))
                <String>['Heart Rate', 'Consult a Cardiologist and ensure regular exercise.'],
              if (_isAbnormal(patientData['SpO2'], 95, null))
                <String>['SpO2', 'Consult a Pulmonologist and practice deep breathing exercises.'],
              if (_isAbnormal(patientData['Temperature'], 92, 98.6))
                <String>['Temperature', 'Consult a General Physician and maintain hydration and rest.'],
              if (_isAbnormal(patientData['Blood Glucose'], 70, 140))
                <String>['Blood Glucose', 'Consult an Endocrinologist and follow a balanced diet with low sugar intake.'],
              if (!_hasAnyAbnormalities(patientData))
                <String>['', 'No abnormalities found. No recommendations.'],
            ].where((element) => element!= null).toList(),
          );
        },
      ),
    );
  }

  bool _isAbnormal(dynamic value, double? lowerRange, double? upperRange) {
    if (value == null || value is! num) return false;
    double parsedValue = value.toDouble();
    return (lowerRange!= null && parsedValue < lowerRange) || (upperRange!= null && parsedValue > upperRange);
  }

  bool _hasAnyAbnormalities(Map<String, dynamic> patientData) {
    return _isAbnormal(patientData['Height'], 150, 190) ||
        _isAbnormal(patientData['Weight'], 50, 90) ||
        _isAbnormal(patientData['High BP'], 120, 140) ||
        _isAbnormal(patientData['Low BP'], 60, 120) ||
        _isAbnormal(patientData['Heart Rate'], 60, 100) ||
        _isAbnormal(patientData['SpO2'], 95, null) ||
        _isAbnormal(patientData['Temperature'], 92, 98.6) ||
        _isAbnormal(patientData['Blood Glucose'], 70, 140);
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
                // Vibrant magenta
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
                    if (_file!= null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                                                child: Text('Selected file: ${_file!.path}', style: TextStyle(color: const Color.fromARGB(255, 173, 173, 173))),
                      ),
                    const SizedBox(height: 50),
                    if (names.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(100,0,100,0),
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
                              child: Text(value, style: const TextStyle(color: Colors.white),),
                            );
                          }).toList(),
                        ),
                      ),
                    const SizedBox(height: 30,),
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
