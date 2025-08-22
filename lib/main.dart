import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EarthDex',
      theme: ThemeData(primarySwatch: Colors.green),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _image;
  String _result = "No result yet";

  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _result = "Identifying...";
      });
      await _identifySpecies(_image!);
    }
  }

  // Capture image from camera
  Future<void> _captureImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _result = "Identifying...";
      });
      await _identifySpecies(_image!);
    }
  }

  // Call iNaturalist API
  Future<void> _identifySpecies(File imageFile) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse("https://api.inaturalist.org/v1/computervision/score_image"),
    );

    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    var response = await request.send();
    var responseData = await http.Response.fromStream(response);

    if (response.statusCode == 200) {
      var data = jsonDecode(responseData.body);
      var results = data['results'];

      if (results.isNotEmpty) {
        var species = results[0]['taxon']['preferred_common_name'] ??
            results[0]['taxon']['name'];
        var confidence = results[0]['score'];
        setState(() {
          _result = "Species: $species\nConfidence: ${(confidence * 100).toStringAsFixed(2)}%";
        });
      } else {
        setState(() {
          _result = "No species identified.";
        });
      }
    } else {
      setState(() {
        _result = "Error: ${response.statusCode}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("EarthDex - Pokedex for Earth")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image != null
                ? Image.file(_image!, height: 200)
                : Icon(Icons.photo, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(_result, textAlign: TextAlign.center),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text("Pick from Gallery"),
            ),
            ElevatedButton(
              onPressed: _captureImage,
              child: Text("Capture from Camera"),
            ),
          ],
        ),
      ),
    );
  }
}
