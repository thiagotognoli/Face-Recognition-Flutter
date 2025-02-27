import 'package:wakelock/wakelock.dart';

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:camera/camera.dart';
// import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:flutter/material.dart';
import 'detector_painters.dart';
import 'utils.dart';
import 'package:image/image.dart' as imglib;
// import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:quiver/collection.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MaterialApp(
    themeMode: ThemeMode.light,
    theme: ThemeData(brightness: Brightness.light),
    home: _MyHomePage(),
    title: "Face Recognition",
    debugShowCheckedModeBanner: false,
  ));
}

class _MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<_MyHomePage> with WidgetsBindingObserver {
  late File jsonFile;
  dynamic _scanResults;
  CameraController? _camera;
  var interpreter;
  bool _isDetecting = false;
  CameraLensDirection _direction = CameraLensDirection.front;
  dynamic data = {};
  double threshold = 1.0;
  double thresholdOpenEye = 0.3;
  double thresholdSmile = 0.7;

  late Directory tempDir;
  List? e1;
  bool _faceFound = false;
  final TextEditingController _name = new TextEditingController();
  @override
  void initState() {
    super.initState();

    Wakelock.enable();

    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    _initializeCamera();
  }

  Future loadModel() async {
    Delegate? delegate;
    try {
      if (Platform.isAndroid) {
        delegate = GpuDelegateV2(
            options: GpuDelegateOptionsV2(
          isPrecisionLossAllowed: false,
          inferencePreference: TfLiteGpuInferenceUsage.fastSingleAnswer,
          inferencePriority1: TfLiteGpuInferencePriority.minLatency,
          inferencePriority2: TfLiteGpuInferencePriority.auto,
          inferencePriority3: TfLiteGpuInferencePriority.auto,
        ));
      } else if (Platform.isIOS) {
        delegate = GpuDelegate(
          options: GpuDelegateOptions(
              allowPrecisionLoss: true,
              waitType: TFLGpuDelegateWaitType.active),
        );
      }
      var interpreterOptions = InterpreterOptions()..addDelegate(delegate!);

      interpreter = await Interpreter.fromAsset('mobilefacenet.tflite',
          options: interpreterOptions);
    } catch (e) {
      print('Failed to load model.');
      print(e);
    }
  }

  void _initializeCamera() async {
    Wakelock.enable();

    await loadModel();
    CameraDescription description = await getCamera(_direction);

    InputImageRotation rotation = rotationIntToImageRotation(
      description.sensorOrientation,
    );

    _camera = CameraController(description, ResolutionPreset.medium,
        enableAudio: false);
    await _camera?.initialize();
    await Future.delayed(Duration(milliseconds: 10));
    tempDir = await getApplicationDocumentsDirectory();
    String _embPath = tempDir.path + '/emb.json';
    jsonFile = new File(_embPath);
    if (jsonFile.existsSync()) data = json.decode(jsonFile.readAsStringSync());

    _camera?.startImageStream((CameraImage image) {
      if (_camera != null) {
        if (_isDetecting) return;
        _isDetecting = true;
        String res;
        dynamic finalResult = Multimap<String, Face>();
        detect(image, _getDetectionMethod(), rotation).then(
          (List<Face> result) async {
            if (result.length == 0)
              _faceFound = false;
            else
              _faceFound = true;
            print("face detected $_faceFound");
            // print(_faceFound);
            Face _face;
            imglib.Image convertedImage =
                _convertCameraImage(image, _direction);
            for (_face in result) {
              double x, y, w, h;
              x = (_face.boundingBox.left - 10);
              y = (_face.boundingBox.top - 10);
              w = (_face.boundingBox.width + 10);
              h = (_face.boundingBox.height + 10);
              imglib.Image croppedImage = imglib.copyCrop(convertedImage,
                  x: x.round(),
                  y: y.round(),
                  width: w.round(),
                  height: h.round());
              croppedImage =
                  imglib.copyResizeCropSquare(croppedImage, size: 112);
              int startTime = new DateTime.now().millisecondsSinceEpoch;
              res = _recog(croppedImage, _face);
              int endTime = new DateTime.now().millisecondsSinceEpoch;
              print("Inference took ${endTime - startTime}ms");
              finalResult.add(res, _face);
            }
            print(finalResult);
            setState(() {
              _scanResults = finalResult;
            });

            _isDetecting = false;
          },
        ).catchError(
          (_) {
            _isDetecting = false;
          },
        );
      }
    });
  }

  HandleDetection _getDetectionMethod() {
    final faceDetector = GoogleMlKit.vision.faceDetector(
      FaceDetectorOptions(
          performanceMode: FaceDetectorMode.accurate,
          enableClassification: true,
          enableContours: true,
          enableLandmarks: false,
          enableTracking: true),
    );
    return faceDetector.processImage;
  }

  // Size getImageSize() {
  //   assert(_camera != null, 'Camera controller not initialized');
  //   assert(_camera!.value.previewSize != null, 'Preview size is null');
  //   return Size(
  //     _camera!.value.previewSize!.height,
  //     _camera!.value.previewSize!.width,
  //   );
  // }

  @override
  void dispose() {
    Wakelock.disable();
    _camera?.dispose();
    super.dispose();
  }

  // #docregion AppLifecycle
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    if (_camera == null || !_camera!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _camera?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Widget _buildResults() {
    const Text noResultsText = const Text('');
    if (_scanResults == null ||
        _camera == null ||
        !_camera!.value.isInitialized) {
      return noResultsText;
    }
    CustomPainter painter;

    final Size imageSize = Size(
      _camera!.value.previewSize!.height,
      _camera!.value.previewSize!.width,
    );
    painter = FaceDetectorPainter(imageSize, _scanResults);
    return CustomPaint(
      painter: painter,
    );
  }

  Widget _buildImage() {
    if (_camera == null || !_camera!.value.isInitialized) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    return _camera == null
        ? const Center(child: null)
        : Container(
            constraints: const BoxConstraints.expand(),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    CameraPreview(_camera!, child: _buildResults())
                  ],
                ),
              ],
            ),
          );

    // return Container(
    //   constraints: const BoxConstraints.expand(),
    //   child: _camera == null
    //       ? const Center(child: null)
    //       : Stack(
    //           // fit: StackFit.expand,
    //           fit: StackFit.passthrough,
    //           children: <Widget>[
    //             CameraPreview(_camera!),
    //             _buildResults(),
    //           ],
    //         ),
    // );
  }

  void _toggleCameraDirection() async {
    if (_direction == CameraLensDirection.back) {
      _direction = CameraLensDirection.front;
    } else {
      _direction = CameraLensDirection.back;
    }
    try {
      await _camera?.stopImageStream();
    } catch (e) {}
    try {
      await _camera?.dispose();
    } catch (e) {}

    setState(() {
      _camera = null;
    });

    _initializeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face recognition'),
        actions: <Widget>[
          PopupMenuButton<Choice>(
            onSelected: (Choice result) {
              if (result == Choice.delete)
                _resetFile();
              else
                _viewLabels();
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<Choice>>[
              const PopupMenuItem<Choice>(
                child: Text('View Saved Faces'),
                value: Choice.view,
              ),
              const PopupMenuItem<Choice>(
                child: Text('Remove all faces'),
                value: Choice.delete,
              )
            ],
          ),
        ],
      ),
      body: _buildImage(),
      floatingActionButton:
          Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        FloatingActionButton(
          backgroundColor: (_faceFound) ? Colors.blue : Colors.blueGrey,
          child: Icon(Icons.add),
          onPressed: () {
            if (_faceFound) _addLabel();
          },
          heroTag: null,
        ),
        SizedBox(
          height: 10,
        ),
        FloatingActionButton(
          onPressed: _toggleCameraDirection,
          heroTag: null,
          child: _direction == CameraLensDirection.back
              ? const Icon(Icons.camera_front)
              : const Icon(Icons.camera_rear),
        ),
      ]),
    );
  }

  imglib.Image _convertCameraImage(
      CameraImage image, CameraLensDirection _dir) {
    int width = image.width;
    int height = image.height;
    // imglib -> Image package from https://pub.dartlang.org/packages/image
    var img = imglib.Image(width: width, height: height); // Create Image buffer
    const int hexFF = 0xFF000000;
    final int uvyButtonStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel!;
    img.data = img.data!;
    // if (img.data != null)
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        final int uvIndex =
            uvPixelStride * (x / 2).floor() + uvyButtonStride * (y / 2).floor();
        final int index = y * width + x;
        final yp = image.planes[0].bytes[index];
        final up = image.planes[1].bytes[uvIndex];
        final vp = image.planes[2].bytes[uvIndex];
        // Calculate pixel color
        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
            .round()
            .clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
        // color: 0x FF  FF  FF  FF
        //           A   B   G   R
        img.data!.setPixelRgb(
            x, y, r, g, b); // ![index] = hexFF | (b << 16) | (g << 8) | r;
        // img.data!.setPixelRgba(x, y, r, g, b, 0xFF);
      }
    }
    var img1 = (_dir == CameraLensDirection.front)
        ? imglib.copyRotate(img, angle: -90)
        : imglib.copyRotate(img, angle: 90);
    return img1;
  }

  String _recog(imglib.Image img, Face face) {
    List input = imageToByteListFloat32(img, 112, 128, 128);
    input = input.reshape([1, 112, 112, 3]);
    // List output = List.filled(192, 0, growable: false).reshape([1, 192]);
    List output = List.generate(1, (index) => List.filled(192, 0));
    interpreter.run(input, output);
    output = output.reshape([192]);
    e1 = List.from(output);

    return compare(e1!).toUpperCase() +
        " | ${(face.leftEyeOpenProbability ?? 0) > thresholdOpenEye ? "O" : "-"}${(face.smilingProbability ?? 0) > thresholdSmile ? "v" : "_"}${(face.rightEyeOpenProbability ?? 0) > thresholdOpenEye ? "O" : "-"} | tId: ${face.trackingId}";
  }

  String compare(List currEmb) {
    print("compare");
    if (data.length == 0) return "No Face saved";
    double minDist = 999;
    double currDist = 0.0;
    String predRes = "NOT RECOGNIZED";
    for (String label in data.keys) {
      currDist = euclideanDistance(data[label], currEmb);
      if (currDist <= threshold && currDist < minDist) {
        minDist = currDist;
        predRes = label;
      }
    }
    print(minDist.toString() + " " + predRes);
    return predRes;
  }

  void _resetFile() {
    data = {};
    jsonFile.deleteSync();
  }

  void _viewLabels() {
    setState(() {
      _camera = null;
    });
    String name;
    var alert = new AlertDialog(
      title: new Text("Saved Faces"),
      content: new ListView.builder(
          padding: new EdgeInsets.all(2),
          itemCount: data.length,
          itemBuilder: (BuildContext context, int index) {
            name = data.keys.elementAt(index);
            return new Column(
              children: <Widget>[
                new ListTile(
                  title: new Text(
                    name,
                    style: new TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
                new Padding(
                  padding: EdgeInsets.all(2),
                ),
                new Divider(),
              ],
            );
          }),
      actions: <Widget>[
        new TextButton(
          child: Text("OK"),
          onPressed: () {
            _initializeCamera();
            Navigator.pop(context);
          },
        )
      ],
    );
    showDialog(
        context: context,
        builder: (context) {
          return alert;
        });
  }

  void _addLabel() {
    setState(() {
      _camera = null;
    });
    print("Adding new face");
    var alert = new AlertDialog(
      title: new Text("Add Face"),
      content: new Row(
        children: <Widget>[
          new Expanded(
            child: new TextField(
              controller: _name,
              autofocus: true,
              decoration: new InputDecoration(
                  labelText: "Name", icon: new Icon(Icons.face)),
            ),
          )
        ],
      ),
      actions: <Widget>[
        new TextButton(
            child: Text("Save"),
            onPressed: () {
              _handle(_name.text.toUpperCase());
              _name.clear();
              Navigator.pop(context);
            }),
        new TextButton(
          child: Text("Cancel"),
          onPressed: () {
            _initializeCamera();
            Navigator.pop(context);
          },
        )
      ],
    );
    showDialog(
        context: context,
        builder: (context) {
          return alert;
        });
  }

  void _handle(String text) {
    data[text] = e1 ?? [];
    jsonFile.writeAsStringSync(json.encode(data));
    _initializeCamera();
  }
}
