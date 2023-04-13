import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
// import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as imglib;

// typedef HandleDetection = Future<dynamic> Function(FirebaseVisionImage image);
typedef HandleDetection = Future<List<Face>> Function(InputImage inputImage);

enum Choice { view, delete }

Future<CameraDescription> getCamera(CameraLensDirection dir) async {
  return await availableCameras().then(
    (List<CameraDescription> cameras) => cameras.firstWhere(
      (CameraDescription camera) => camera.lensDirection == dir,
    ),
  );
}

InputImageData buildMetaData(
  CameraImage image,
  InputImageRotation rotation,
) {
  return InputImageData(
    imageRotation: rotation,
    inputImageFormat: InputImageFormatValue.fromRawValue(image.format.raw) ??
        InputImageFormat.yuv_420_888,
    size: Size(image.width.toDouble(), image.height.toDouble()),
    planeData: image.planes.map(
      (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList(),
  );
}

Future<List<Face>> detect(
  CameraImage image,
  HandleDetection handleDetection,
  InputImageRotation rotation,
) async {
  // for mlkit 13
  final WriteBuffer allBytes = WriteBuffer();
  for (final Plane plane in image.planes) {
    allBytes.putUint8List(plane.bytes);
  }
  final bytes = allBytes.done().buffer.asUint8List();

  return handleDetection(
    InputImage.fromBytes(
      bytes: bytes,
      inputImageData: buildMetaData(image, rotation),
    ),
  );
}

InputImageRotation rotationIntToImageRotation(int rotation) {
  switch (rotation) {
    case 0:
      return InputImageRotation.rotation0deg;
    case 90:
      return InputImageRotation.rotation90deg;
    case 180:
      return InputImageRotation.rotation180deg;
    default:
      assert(rotation == 270);
      return InputImageRotation.rotation270deg;
  }
}

Float32List imageToByteListFloat32(
    imglib.Image image, int inputSize, double mean, double std) {
  var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
  var buffer = Float32List.view(convertedBytes.buffer);
  int pixelIndex = 0;
  for (var y = 0; y < inputSize; y++) {
    for (var x = 0; x < inputSize; x++) {
      var pixel = image.getPixel(x, y);
      buffer[pixelIndex++] = (pixel.rNormalized - 0.5) / 0.5;
      buffer[pixelIndex++] = (pixel.gNormalized - 0.5) / 0.5;
      buffer[pixelIndex++] = (pixel.bNormalized - 0.5) / 0.5;
    }
  }
  return convertedBytes.buffer.asFloat32List();
}

double euclideanDistance(List e1, List e2) {
  double sum = 0.0;
  for (int i = 0; i < e1.length; i++) {
    sum += pow((e1[i] - e2[i]), 2);
  }
  return sqrt(sum);
}
