import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite/tflite.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Detect Objects',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File _image;
  double _imageWidth;
  double _imageHeight;
  var _recognitions;

  loadModel() async {
    Tflite.close();
    try {
      String res;
      res = await Tflite.loadModel(
        model: "assets/mobilenet.tflite",
        labels: "assets/labels.txt",
      );
      print(res);
    } on PlatformException {
      print("Failed to load the model");
    }
  }

  Future predict(File image) async {
    var recognition = await Tflite.runModelOnImage(
      path: image.path,
      imageMean: 0.0,
      imageStd: 255.0,
      numResults: 2,
      threshold: 0.3,
      asynch: true,
    );
    print(recognition);
    setState(() {
      _recognitions = recognition;
    });
  }

  sendImage(File image) async {
    if (image == null) return;
    await predict(image);

    FileImage(image)
        .resolve(ImageConfiguration())
        .addListener((ImageStreamListener((ImageInfo info, bool _) {
          setState(() {
            _imageWidth = info.image.width.toDouble();
            _imageHeight = info.image.height.toDouble();
            _image = image;
          });
        })));
  }

  // select image from gallery
  selectFromGallery() async {
    var imageFile;
    final picker = ImagePicker();
    var image = await picker.getImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() {
      if (image != null) {
        imageFile = File(image.path);
      }
    });
    sendImage(imageFile);
  }

  selectFromCamera() async {
    var imageFile;
    final picker = ImagePicker();
    var image = await picker.getImage(source: ImageSource.camera);
    if (image == null) return;
    setState(() {
      if (image != null) {
        imageFile = File(image.path);
      }
    });
    sendImage(imageFile);
  }

  @override
  void initState() {
    super.initState();
    loadModel().then((val) {
      setState(() {});
    });
  }

  Widget printValue(rcg) {
    if (rcg == null) {
      return Text(
        "Input Image for detection",
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
        ),
      );
    } else if (rcg.isEmpty) {
      return Center(
        child: Text(
          "Could not recognize",
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Center(
        child: Text(
          "Detected:" + _recognitions[0]['label'].toString().toUpperCase(),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    double finalW;
    double finalH;

    if (_imageWidth == null && _imageHeight == null) {
      finalW = size.width;
      finalH = size.height;
    } else {
      double ratioW = size.width / _imageWidth;
      double ratioH = size.height / _imageHeight;

      finalW = _imageWidth * ratioW * 0.85;
      finalH = _imageHeight * ratioH * 0.50;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Object Detection"),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          printValue(_recognitions),
          _image == null
              ? Center(
                  child: Text(
                    "Select image from camera or gallery",
                    style: TextStyle(
                      fontSize: 25,
                    ),
                  ),
                )
              : Center(
                  child: Image.file(
                    _image,
                    fit: BoxFit.fill,
                    width: finalW,
                    height: finalH,
                  ),
                ),
          Row(
            children: [
              FlatButton.icon(
                onPressed: selectFromCamera,
                icon: Icon(Icons.camera),
                label: Text("Camera"),
              ),
              FlatButton.icon(
                onPressed: selectFromGallery,
                icon: Icon(Icons.file_upload),
                label: Text("Camera"),
              ),
            ],
          )
        ],
      ),
    );
  }
}
