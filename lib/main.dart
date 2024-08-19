// ignore_for_file: avoid_types_as_parameter_names, non_constant_identifier_names

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

    _addPatientInfo(pdf, patientData);
    _addAbnormalities(pdf, patientData);

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/patient_report_${patientData['Name']}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  Future<File> _generateParameterReport() async {
    final pdf = pw.Document();

    _addParameterAbnormalities(pdf, data, selectedParameter!);

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/parameter_report_$selectedParameter.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }


  void _addPatientInfo(pw.Document pdf, Map<String, dynamic> patientData) {
    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) {
          return [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
              'Patient Report',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),]),
            pw.SizedBox(height: 30),
            pw.Table.fromTextArray(
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
              <String>['Systolic BP', '${patientData['High BP']} mmHg'],
              <String>['Diastolic BP', '${patientData['Low BP']} mmHg'],
              <String>['Heart Rate', '${patientData['Heart Rate']} bpm'],
              <String>['SpO2', '${patientData['SpO2']} %'],
              <String>['Temperature', '${patientData['Temperature']} °F'],
              <String>['Blood Glucose', '${patientData['Blood Glucose']} mg/dL'],
            ],
          )
        ];},
      ),
    );
  }

  void _addAbnormalities(pw.Document pdf, Map<String, dynamic> patientData) {
    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) {
          List<List<String>> abnormalities = [];

          // Check for BMI
          double bmi = _calculateBMI(patientData['Height'], patientData['Weight']);
          if (_isAbnormal(bmi, 18.5, 30)) {
            if (bmi < 18.5) {
              abnormalities.add([
                'BMI',
                (bmi.toStringAsFixed(1)),
                'Underweight',
                'Increase food intake, take nutrient rich foods, take protein and weight gainer supplements. More carbs and protein, high PUFA sources to add calories in diet with essentiall vit and minerals. Take calorie-dense foods like smoothies, shakes, nuts and oilseeds, cheese, and full-cream dairy products. High biological value proteins like egg, lean meat, and fish. The diet must include whole grains, millet, pulses, and plenty of fruits and vegetables. Never skip major meals, especially breakfast. Breakfast should be the heaviest meal of the day. Take 5-6 small and frequent meals. ',
              ]);
            } 
             else if (bmi >= 18.5 || bmi <= 24.9) {
              abnormalities.add([
                'BMI',
                (bmi.toStringAsFixed(1)),
                'Healthy',
                'combination of simple and complex carbs, moderate fat and protein with fruits and vegetables. Physically active. Include combination of simple and complex carbohydrates. Include protein sources such as low-fat dairy products, egg, fish, lean meat, and pulses Physical activity should be maintained. Include plenty of seasonal fruits and vegetables, as it add fiber to your diet. Remove unsaturated fat from your diet such as palm oil, reheated oil, coconut oil, and red meat. Prefer omega 3 and omega 6 fatty acid-containing food products like nuts and oilseeds, olive oil, fish, fish oil, and eggs.',
              ]);
            } else if (bmi >= 25 || bmi <= 29.9) {
              abnormalities.add([
                'BMI',
                (bmi.toStringAsFixed(1)),
                'Overweight',
                'less carbs, high protein, low fat. More of fiber. Maintain hydration level and physically active. Avoid junk and fried food. Include more of complex carbs in your diet such as whole grains, whole cereals, millet etc. Inlclude more fibre in the diet such as fruits and vegetables. Add more of protein in the diet. Avoid fried, packaged, junk and, outside food. Avoid salad dressing and binge eating. Avoid using reheated oil, palm oil, and coconut oil. include walnuts, almonds, flaxseeds, chia seeds, sunflower, and watermelon seeds.  ',
              ]);
            } else if (bmi >= 30) {
              abnormalities.add([
                'BMI',
                (bmi.toStringAsFixed(1)),
                'Obesity',
                'Control diet, eat less junk food, control salt and sugar levels. Less carbs, high protein, low fat. More of fiber. Maintain hydration level and physically active. Avoid junk and fried food. Avoid simple carbs and prefer complex carbs over them like whole grain, whole cereals, millets or multigrain products. Avoid baked and packaged products. Maintain physical acitivity and remove calorie dense products from the diet such as juices, shakes, sugar and sugary products, carbonated drinks abd junk food. Prefer combination of healthy fats and oils such as mustard oil, olive oil, seeds, soyabean. Avoid egg yolks and red meat.',
              ]);
            }
          }

          // Check for Blood Pressure
          int highBP = patientData['High BP'];
          int lowBP = patientData['Low BP'];
          if (_isAbnormal(highBP, 120, null) || _isAbnormal(lowBP, 80, null)) {
            abnormalities.add([
              "Blood Pressure",
              '$highBP/$lowBP mmHg',
              'Hypotension',
              'Use more salts, drink more water, eat smaller meals and limit alcohol. Use saline solutions, and pickles, or add more salt to the diet. Add B12 and folate to the diet such as lean meat, fish, fish oil, cheese, dairy products, GLVs, fruits and vegetables, and beans. Reduce carbs intake. Drink plenty of fluid. Include caffeine such as coffee caffeinated drinks. ',
            ]);
          }else if (_isAbnormal(highBP, 120, 129) || _isAbnormal(lowBP, 80, 84)) {
            abnormalities.add([
              "Blood Pressure",
              '$highBP/$lowBP mmHg',
              'Normal',
              'Take a combination of simple and complex carbs. Moderate amount of protein and fat. Add fruits and vegetables to your diet. Take only 5-6 gm of salt a day. Low-fat dairy products to be included. Maintain hydration level and physical activity.',
            ]);
          }else if (_isAbnormal(highBP, 130, 139) || _isAbnormal(lowBP, 85, 90)) {
            abnormalities.add([
              "Blood Pressure",
              '$highBP/$lowBP mmHg',
              'High-normal',
              'Avoid extra salt, pickles, papad, and salad dressing. Prefer low-fat dairy products. Follow the DASH diet which Includes more fiber such as fruits, vegetables, whole grains, whole cereals, millets, and seeds. It includes fat-free or low-fat dairy products, fish, poultry, beans. Limit sugar and saturated fat such as meat, reheated oil, palm oil, and full-fat dairy products. Physical activity should be maintained. Maintain hydration level and avoid alcohol consumption. Reduce salt upto 2-3 gm per day.',
            ]);
          }
          else if (_isAbnormal(highBP, 0, 140) || _isAbnormal(lowBP, 0, 90)) {
            abnormalities.add([
              "Blood Pressure",
              '$highBP/$lowBP mmHg',
              'Hypertension',
              'Reduce salt (sodium) intake, quit smoking and limit alcohol, include healty protein-rich foods such as fish, seafood, legumes, yoghurt, healthy fats and oils, etc. Include more fibre to the diet such as whole grains, whole cereals, millets, fruits and vegetables to your diet. Physical activity should be maintained. Maintain hydration level and avoid alcohol consumption. Avoid refined, baked, packaged, fried, and junk food. Reduce salt consumption to 1500 mg per day. Avoid extra salty products, salad dressing. Instead you can use lemon or citrus food products.  ',
            ]);
          }

          // Check for Heart Rate
          int heartRate = patientData['Heart Rate'];
          if (_isAbnormal(heartRate, 60, null)) {
            abnormalities.add([
              'Heart Rate',
              '$heartRate bpm',
              'Bradycardia',
              'Eat magnesium rich foods such as nuts, cereals, spinach, etc. Foods rich in Omega-3-FA such as walnuts, vegetable oils, seafoods, etc. Cardioprotective foods suc has green vegetables, fresh fruits, etc. Food containing stimulants such as alcohol, beer, coffee, chocolate, etc should be avoided. Diet followed by low-fat, low-salt and moderate sugar. Included fruits and vegetables. And most important physically active. Include fruits and vegetables, nuts, and beans to your diet. Include omega-3 and omega-6 fatty acid food products such as egg white, fish, lean meat. Avoid excess intake of salt, salad dressings, pickles, packaged food and other salty products. Avoid alcohol, smoking, and stress. Inlucde essential minerals in your diet such as calcium, potassium and magnesium such as green leafy veg, seeds, dairy products, fruits, beans and legumes.',
            ]);
          }
          if (_isAbnormal(heartRate, 0, 100)) {
            abnormalities.add([
              'Heart Rate',
              '$heartRate bpm',
              'Tachycardia',
              'Maintain healthy body weight. Less carbs, less fat, low salt, moderate protein, and high fibre. Prefer omega-3 and omega-6 fatty acids such as olive oil, fish, fish oil, nuts and seeds such as almonds, walnuts, chia seeds, flaxseeds, sunflower seeds, pumpkin seeds and watermelon seeds. Limit potassium-rich foods such as banana, potato, lemon, coconut water, soybean, green leafy veg, egg yolk, and dried fruits Add more fibre to your diet such as fruits and veg. Avoid alcohol, caffeine and smoking. Add calcium, magnesium, vit D as important minerals. ',
            ]);
          }

          // Check for SpO2
          int spO2 = patientData['SpO2'];
          if (_isAbnormal(spO2, 95, 100)) {
            abnormalities.add([
              'SpO2',
              '$spO2 %',
              'Low Oxygen Saturation',
              'Include vitamins and minerals in your diet to regulate oxygen level such as iron, folic acid, and B12. Include fruits and vegetables such as citrus fruits, pomegranate, berries, kiwi, spinach, beans, beetroot, green leafy veg etc for iron.  Never skip major meals and be physically active. Plenty of fluid to be taken including juices, soups etc. Avoid alcohol, smoking and caffeine intake.',
            ]);
          }
          

          // Check for Temperature
          int temperature = patientData['Temperature'];
          if (_isAbnormal(temperature, 96, null)) {
            abnormalities.add([
              'Temperature',
              '$temperature °F',
              'low',
              'Include High calorie, high fat, high carbs and moderate protein diet.   Include high biological value protein such as eggs, fish, lean meat etc. Eat antioxidant rich food such as fruits like berries, citrus fruits.  Drink hot beverages like hot soups, caffeine and a bit of any alcoholic beverages.',
            ]);
          }
          else if (_isAbnormal(temperature, 0, 100)) {
            abnormalities.add([
              'Temperature',
              '$temperature °F',
              'high',
              'Include more simple carbs. Include soft or well-cooked food. Add fruits to your diet. Take plenty of fluids including soups, juices, coconut water, lemon water, smoothies, shakes etc. Add antioxidants (vit C and Vit E) such as citrus foods, green leafy veg etc. Add high protein sources such as pulses, eggs, dairy products, lean meat, fish etc. Include juices made of herbs and condiments.',
            ]);
          }

          // Check for Blood Glucose
           int bloodGlucose = patientData['Blood Glucose'];
                if (_isAbnormal(bloodGlucose, 70, null)) {
                  abnormalities.add([
                    'Blood Glucose',
                    '$bloodGlucose mg/dL',
                    'Hypoglycemia',
                    'IMPORTANT: Initially take 15 gm-25 gm or carbs, and then after 15 min, check the blood sugar level. Repeat the cycle if it still remains low. Give sugary drinks or juices slowly. You can add an apple, grapes, or orange for faster results.  Limit alcohol and caffeine. Add fruits to your diet. Include snacks in between the major meals. Take 5-6 small and frequent meals.',
                  ]);
                } else if (_isAbnormal(bloodGlucose, 0, 140)) {
                  abnormalities.add([
                    'Blood Glucose',
                    '$bloodGlucose mg/dL',
                    'Hyperglycemia',
                    'Complex carbs, high protein, moderate fat (omega-3 and omega-6 fatty acids), high fibre and plenty of fluid. Add more of fibre in the diet such as whole grain or multigrain cereals, millets, fruits, vegetables, and nuts and oilseeeds (almonds, walnuts, chia seeds, flaxseeds, watermelon seeds etc). Add protein sources such as pulses, low-fat dairy products, eggs, fish, and lean meat. Prefer mustard oil or olive oil for cooking and avoid reheated oil, coconut oil, and palm oil. Avoid sugar, honey, jaggery, juices, sugary and carbonated drinks. Avoid low glycemic index foods such as banana, litchi, mango, grapes, chiku, potato, sweet potato, and colocasia Reduce simple carbs and prefer complex carbs over them. Avoid refined products, bakery and fried foods (white rice, pasta, white bread, junk food). Do not stay hungry for more than 3 hours as it may lead to fluctuation of sugar levels. Prefer brisk walking.',
                  ]);
                }

          return [
            pw.Table.fromTextArray(
            headers: <String>[
              'Parameter',
              'Value',
              'Abnormality',
              'Recommendation',
            ],
            headerCount: 4,
           headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
  cellAlignment: pw.Alignment.center,
  data: abnormalities.map((Column) {
    return [
      Column[0],
      Column[1],
      Column[2],
      Column[3],
    ];
  }).toList(),
  columnWidths: {
     0: const pw.FlexColumnWidth(), // Use intrinsic width for each column
          1: const pw.FlexColumnWidth(), // Use intrinsic width for each column
          2: const pw.FlexColumnWidth(), // Use intrinsic width for each column
          3: const pw.FlexColumnWidth(),  // Recommendation column width to take remaining space
  },
  cellStyle: const pw.TextStyle(
    fontSize: 10,
  ),

        )];
        
      },
    ),
  );
}

  void _addParameterAbnormalities(pw.Document pdf, List<Map<String, dynamic>> data, String parameter) {
    pdf.addPage(
      pw.MultiPage(
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
                'BMI',
                (bmi.toStringAsFixed(1)),
                'Underweight',
              ]);
            } 
             else if (bmi >= 18.5 || bmi <= 24.9) {
              abnormalities.add([
                patientData['Name'],
                'BMI',
                (bmi.toStringAsFixed(1)),
                'Healthy',
              ]);
            } else if (bmi >= 25 || bmi <= 29.9) {
              abnormalities.add([
                patientData['Name'],
                'BMI',
                (bmi.toStringAsFixed(1)),
                'Overweight',
              ]);
            } else if (bmi >= 30) {
              abnormalities.add([
                patientData['Name'],
                'BMI',
                (bmi.toStringAsFixed(1)),
                'Obesity',
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
              'Blood Pressure',
              '$highBP/$lowBP mmHg',
              'Hypotension',
            ]);
          }else if (_isAbnormal(highBP, 120, 129) || _isAbnormal(lowBP, 80, 84)) {
            abnormalities.add([
              patientData['Name'],
              'Blood Pressure',
              '$highBP/$lowBP mmHg',
              'Normal',
            ]);
          }else if (_isAbnormal(highBP, 130, 139) || _isAbnormal(lowBP, 85, 90)) {
            abnormalities.add([
              patientData['Name'],
              'Blood Pressure',
              '$highBP/$lowBP mmHg',
              'High-normal',
            ]);
          }
          else if (_isAbnormal(highBP, 0, 140) || _isAbnormal(lowBP, 0, 90)) {
            abnormalities.add([
              patientData['Name'],
              'Blood Pressure',
              '$highBP/$lowBP mmHg',
              'Hypertension',
            ]);
          }
                break;
              case 'Heart Rate':
                int heartRate = patientData['Heart Rate'];
          if (_isAbnormal(heartRate, 60, null)) {
            abnormalities.add([
              patientData['Name'],
              'Heart Rate',
              '$heartRate bpm',
              'Bradycardia',
            ]);
          }
          if (_isAbnormal(heartRate, 0, 100)) {
            abnormalities.add([
              patientData['Name'],
              'Heart Rate',
              '$heartRate bpm',
              'Tachycardia',
            ]);
          }
                break;
              case 'SpO2':
                int spO2 = patientData['SpO2'];
          if (_isAbnormal(spO2, 95, 100)) {
            abnormalities.add([
              patientData['Name'],
              'SpO2',
              '$spO2 %',
              'Low Oxygen Saturation',
            ]);
          }
                break;
              case 'Temperature':
               int temperature = patientData['Temperature'];
          if (_isAbnormal(temperature, 96, null)) {
            abnormalities.add([
              patientData['Name'],
              'Temperature',
              '$temperature °F',
              'low',
            ]);
          }
          else if (_isAbnormal(temperature, 0, 100)) {
            abnormalities.add([
              patientData['Name'],
              'Temperature',
              '$temperature °F',
              'high',
            ]);
          }
                break;
              case 'Blood Glucose':
                int bloodGlucose = patientData['Blood Glucose'];
                if (_isAbnormal(bloodGlucose, 70, null)) {
                  abnormalities.add([
                    patientData['Name'],
                    'Blood Glucose',
                    '$bloodGlucose mg/dL',
                    'Hypoglycemia',                  ]);
                }
                break;
              default: abnormalities.add([
                'Nil',
                    'Nil',
                    'Nil',
                    'Nil',
                  
              ]);
                break;
            }
          }
          

          return [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [pw.Text(
              'Patient Report',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              
            ),]),
            pw.SizedBox(height: 30),
            pw.Table.fromTextArray(
  headers: <String>[
    'Name',
    'Parameter',
    'Value',
    'Abnormality',
  ],
  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
  cellAlignment: pw.Alignment.centerLeft,
  data: abnormalities.map((Column) {
    return [
      Column[0],
      Column[1],
      Column[2],
      Column[3],
      
    ];
  }).toList(),
  columnWidths: {
     0: const pw.FlexColumnWidth(), // Use intrinsic width for each column
          1: const pw.FlexColumnWidth(), // Use intrinsic width for each column
          2: const pw.FlexColumnWidth(),// Use intrinsic width for each column
          3: const pw.FlexColumnWidth(),  // Recommendation column width to take remaining space
  },
  cellStyle: const pw.TextStyle(
    fontSize: 10,
  ),
  cellPadding: const pw.EdgeInsets.all(10)
        )];
        
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

