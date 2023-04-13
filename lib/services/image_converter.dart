import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as imglib;

imglib.Image convertToImage(CameraImage image) {
  try {
    print('image.format.group=>${image.format.group}');
    if (image.format.group == ImageFormatGroup.yuv420) {
      return _convertYUV420(image);
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      return _convertBGRA8888(image);
    }
    throw Exception('Image format not supported');
  } catch (e) {
    print("ERROR:" + e.toString());
  }
  throw Exception('Image format not supported');
}

// imglib.Image convertFromFile(File file) {
//   try {
//     return imglib.Image.fromBytes(
//       width: 200,
//       height: 300,
//       bytes: file.readAsBytesSync(),
//     );
//   } catch (e) {
//     print("ERROR:" + e.toString());
//   }
//   throw Exception('Image format not supported');
// }

// // for mlkit 13
// final WriteBuffer allBytes = WriteBuffer();
// for (final Plane plane in image.planes) {
//   allBytes.putUint8List(plane.bytes);
// }
// final bytes = allBytes.done().buffer.asUint8List();

imglib.Image _convertBGRA8888(CameraImage image) {
  // for mlkit 13
  final WriteBuffer allBytes = WriteBuffer();
  allBytes.putUint8List(image.planes[0].bytes);
  // final bytes = allBytes.done().buffer.asUint8List();

  // InputImage.fromBytes(
  //   bytes: bytes,
  //   inputImageData: buildMetaData(image, rotation),
  // ),

  return imglib.Image.fromBytes(
    width: image.width,
    height: image.height,
    bytes: allBytes.done().buffer,
    //bytes: image.planes[0].bytes,
    format: imglib.Format.uint32,
  );
}

imglib.Image _convertYUV420(CameraImage image) {
  int width = image.width;
  int height = image.height;
  var img = imglib.Image(width: width, height: height);
  // const int hexFF = 0xFF000000;
  // final int uvyButtonStride = image.planes[1].bytesPerRow;
  // final int? uvPixelStride = image.planes[1].bytesPerPixel;
  // for (int x = 0; x < width; x++) {
  //   for (int y = 0; y < height; y++) {
  //     final int uvIndex =
  //         uvPixelStride! * (x / 2).floor() + uvyButtonStride * (y / 2).floor();
  //     final int index = y * width + x;
  //     final yp = image.planes[0].bytes[index];
  //     final up = image.planes[1].bytes[uvIndex];
  //     final vp = image.planes[2].bytes[uvIndex];
  //     int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
  //     int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
  //         .round()
  //         .clamp(0, 255);
  //     int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
  //     img.data[index] = hexFF | (b << 16) | (g << 8) | r;
  //   }
  // }

  return img;
}

imglib.Image convertCameraImage(CameraImage image, CameraLensDirection _dir) {
  int width = image.width;
  int height = image.height;

  var img = imglib.Image(width: width, height: height);
  // const int hexFF = 0xFF000000;

  final int uvyButtonStride = image.planes[1].bytesPerRow;
  final int uvPixelStride = image.planes[1].bytesPerPixel!;
  img.data = img.data!;

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
    }
  }
  var img1 = (_dir == CameraLensDirection.front)
      ? imglib.copyRotate(img, angle: -90)
      : imglib.copyRotate(img, angle: 90);
  return img1;
}
