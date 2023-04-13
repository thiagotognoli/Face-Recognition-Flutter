// // Copyright 2013 The Flutter Authors. All rights reserved.
// // Use of this source code is governed by a BSD-style license that can be
// // found in the LICENSE file.

// import 'dart:async';
// import 'dart:io';

// import 'package:camera/camera.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/scheduler.dart';
// import 'package:flutter/services.dart';
// import 'package:provider/provider.dart';
// import 'package:video_player/video_player.dart';
// import 'package:camera_controller_plus/camera_controller_plus.dart';

// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// // import '../models/camera_controller.dart';
// import '../helpers/layout_responsive.dart';
// import '../states/arp.dart';
// import '../states/infos_camera.dart';
// import '../states/infos_time.dart';
// import '../utils/log.dart';
// import '../widgets/app_bar.dart';
// import '../widgets/beautifull_date.dart';

// /// Camera example home widget.
// class RegisterPhoto extends StatelessWidget {
//   static const String routeName = "/RegisterPhoto";

//   const RegisterPhoto({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     double width = LayoutResponsive.calcWidth(context);
//     final ThemeData theme = Theme.of(context);
//     final localization = AppLocalizations.of(context)!;
//     final bool isHeightMinimun = LayoutResponsive.isHeightMinimun(context);

//     return Scaffold(
//       appBar: const AppBarClockin()
//           .build(context), //title: Text(localization.registerPointWithPhoto),
//       floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
//       body: SafeArea(
//         child: Camera(
//           // camerasDirectionFilter: <CameraLensDirection>[
//           //   CameraLensDirection.front,
//           //   CameraLensDirection.external
//           // ],
//           enableFeatureTake: false,
//           previewHeader: Container(
//             margin: EdgeInsets.all(width / 25),
//             alignment: AlignmentDirectional.centerEnd,
//             child: Column(
//               children: [
//                 Hero(
//                   tag: 'beatifuldata',
//                   flightShuttleBuilder: (
//                     BuildContext flightContext,
//                     Animation<double> animation,
//                     HeroFlightDirection flightDirection,
//                     BuildContext fromHeroContext,
//                     BuildContext toHeroContext,
//                   ) {
//                     return DefaultTextStyle(
//                       style: const TextStyle(),
//                       child: BeautifulDate(
//                         width: isHeightMinimun ? width / 2 : width / 2,
//                         showAnalogClock: false,
//                         showWeekDay: false,
//                         outlineText: true,
//                       ),
//                     );
//                   },
//                   child: BeautifulDate(
//                     width: isHeightMinimun ? width / 2 : width / 2,
//                     showAnalogClock: false,
//                     showWeekDay: false,
//                     outlineText: true,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           footer: Container(
//             margin: const EdgeInsets.all(10),
//             child: Row(
//               // crossAxisAlignment: CrossAxisAlignment.center,
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 FloatingActionButton.extended(
//                   heroTag: "btnClockinRegisterCancel",
//                   // tooltip: localization.cancel,
//                   label: Text(
//                     localization.cancel,
//                     style: const TextStyle(fontSize: 18, height: 1.25),
//                   ),
//                   onPressed: () {
//                     Navigator.pop(context);
//                   },
//                   backgroundColor: theme.colorScheme.error,
//                   icon: const Icon(
//                     Icons.cancel_outlined,
//                   ),
//                 ),
//                 FloatingActionButton.extended(
//                   heroTag: "register",
//                   // tooltip: localization.confirm,
//                   label: Text(
//                     localization.confirm,
//                     style: const TextStyle(fontSize: 18, height: 1.25),
//                   ),
//                   backgroundColor: theme.primaryColor,
//                   icon: const Icon(
//                     Icons.task_alt,
//                   ),
//                   onPressed: () async {
//                     var arp = context.read<Arp>();
//                     var point = await arp
//                         .markPoint(context.read<InfosTime>().getBestDateTime());
//                     arp.syncPoint(point);

//                     Navigator.pop(context);
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// /// Returns a suitable camera icon for [direction].

// class Camera extends StatefulWidget {
//   static const String routeName = "/RegisterPhoto";

//   final List<CameraLensDirection>? camerasDirectionFilter;

//   final Widget? previewHeader;
//   final Widget? footer;

//   _CameraState? cameraState;

//   final bool enableFeatureTake;

//   /// Default Constructor
//   Camera(
//       {Key? key,
//       this.camerasDirectionFilter,
//       this.previewHeader,
//       this.footer,
//       this.enableFeatureTake = true})
//       : super(key: key);

//   @override
//   _CameraState createState() {
//     cameraState = _CameraState(
//         camerasDirectionFilter: camerasDirectionFilter,
//         previewHeader: previewHeader,
//         enableFeatureTake: enableFeatureTake,
//         footer: footer);
//     return cameraState!;
//   }
// }

// class _CameraState extends State<Camera>
//     with WidgetsBindingObserver, TickerProviderStateMixin {
//   CameraControllerPlus? controller;
//   XFile? imageFile;
//   XFile? videoFile;
//   VideoPlayerController? videoController;
//   VoidCallback? videoPlayerListener;
//   bool enableAudio = true;
//   double _minAvailableExposureOffset = 0.0;
//   double _maxAvailableExposureOffset = 0.0;
//   double _currentExposureOffset = 0.0;
//   late AnimationController _flashModeControlRowAnimationController;
//   late Animation<double> _flashModeControlRowAnimation;
//   late AnimationController _exposureModeControlRowAnimationController;
//   late Animation<double> _exposureModeControlRowAnimation;
//   late AnimationController _focusModeControlRowAnimationController;
//   late Animation<double> _focusModeControlRowAnimation;
//   double _minAvailableZoom = 1.0;
//   double _maxAvailableZoom = 1.0;
//   double _currentScale = 1.0;
//   double _baseScale = 1.0;

//   // Counting pointers (number of user fingers on screen)
//   int _pointers = 0;

//   final List<CameraLensDirection>? camerasDirectionFilter;
//   final Widget? previewHeader;
//   final Widget? footer;

//   final bool enableFeatureVideo;
//   final bool enableFeatureAudio;
//   final bool enableFeaturePhoto;
//   final bool enableFeatureIconsCameras;
//   final bool enableFeatureTake;

//   bool camerasInitialized = false;
//   List<CameraDescription> cameras = <CameraDescription>[];

//   _CameraState({
//     this.camerasDirectionFilter,
//     this.previewHeader,
//     this.footer,
//     this.enableFeatureTake = true,
//     this.enableFeatureAudio = false,
//     this.enableFeatureVideo = false,
//     this.enableFeaturePhoto = true,
//     this.enableFeatureIconsCameras = false,
//   });

//   @override
//   void initState() {
//     super.initState();

//     enableAudio = enableFeatureAudio && enableAudio;

//     () async {
//       List<CameraDescription> stateCameras = await InfosCamera.initCameras(
//           camerasDirectionFilter: camerasDirectionFilter);
//       if (stateCameras.isNotEmpty) {
//         for (final CameraDescription cameraDescription in stateCameras) {
//           onNewCameraSelected(cameraDescription);
//           break;
//         }
//       }
//       setState(() {
//         camerasInitialized = true;
//         cameras = stateCameras;
//       });
//     }();

//     _ambiguate(WidgetsBinding.instance)?.addObserver(this);

//     _flashModeControlRowAnimationController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );
//     _flashModeControlRowAnimation = CurvedAnimation(
//       parent: _flashModeControlRowAnimationController,
//       curve: Curves.easeInCubic,
//     );
//     _exposureModeControlRowAnimationController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );
//     _exposureModeControlRowAnimation = CurvedAnimation(
//       parent: _exposureModeControlRowAnimationController,
//       curve: Curves.easeInCubic,
//     );
//     _focusModeControlRowAnimationController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );
//     _focusModeControlRowAnimation = CurvedAnimation(
//       parent: _focusModeControlRowAnimationController,
//       curve: Curves.easeInCubic,
//     );
//   }

//   @override
//   void dispose() {
//     _ambiguate(WidgetsBinding.instance)?.removeObserver(this);
//     _flashModeControlRowAnimationController.dispose();
//     _exposureModeControlRowAnimationController.dispose();
//     controller?.dispose();
//     super.dispose();
//   }

//   // #docregion AppLifecycle
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     final CameraControllerPlus? cameraController = controller;

//     // App state changed before we got the chance to initialize.
//     if (cameraController == null || !cameraController.value.isInitialized) {
//       return;
//     }

//     if (state == AppLifecycleState.inactive) {
//       cameraController.dispose();
//     } else if (state == AppLifecycleState.resumed) {
//       onNewCameraSelected(cameraController.description);
//     }
//   }

//   // #enddocregion AppLifecycle

//   double calcMarginTopCommands(BuildContext context) {
//     final double maxMarginTopCommands =
//         MediaQuery.of(context).size.height - 250;
//     double marginTopCommands = maxMarginTopCommands;
//     marginTopCommands = (controller != null)
//         ? controller!
//             .calcCameraPreviewWidgetHeight(MediaQuery.of(context).size.width)
//         : -1;
//     return (marginTopCommands == -1 || marginTopCommands > maxMarginTopCommands)
//         ? maxMarginTopCommands
//         : marginTopCommands;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final ThemeData theme = Theme.of(context);
//     final localization = AppLocalizations.of(context)!;

//     return Stack(
//       children: <Widget>[
//         Column(children: <Widget>[
//           // Expanded(
//           // child:
//           // Container(
//           // decoration: BoxDecoration(
//           //   color: Colors.black,
//           //   border: Border.all(
//           //     color: controller != null &&
//           //             controller!.value.isRecordingVideo
//           //         ? Colors.redAccent
//           //         : Colors.grey,
//           //     width: 3.0,
//           //   ),
//           // ),
//           // child: Padding(
//           //   padding: const EdgeInsets.all(1.0),
//           // child: Center(
//           // child:
//           _cameraPreviewWidget(theme, localization),
//           // ),
//           // ),
//           // ),
//           // )
//         ]),
//         Column(children: <Widget>[
//           ...(previewHeader != null) ? <Widget>[previewHeader!] : <Widget>[],
//         ]),
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.end,
//           mainAxisAlignment: MainAxisAlignment.end,
//           children: <Widget>[
//             // Expanded(child: Container()),
//             _captureControlRowWidget(theme),
//             _modeControlRowWidget(theme),
//             Padding(
//               padding: const EdgeInsets.all(5.0),
//               child: Row(
//                 children: <Widget>[
//                   _cameraTogglesRowWidget(theme),
//                   _thumbnailWidget(theme),
//                 ],
//               ),
//             ),
//             ...(footer != null) ? <Widget>[footer!] : <Widget>[],
//           ],
//         ),
//       ],
//     );
//   }

//   /// Display the preview from the camera (or a message if the preview is not available).
//   Widget _cameraPreviewWidget(ThemeData theme, AppLocalizations localization) {
//     final CameraControllerPlus? cameraController = controller;

//     if (cameraController == null || !cameraController.value.isInitialized) {
//       // Expanded(child: Container()),
//       return Expanded(
//         child: Center(
//           child: Text(
//             localization.waitingCamera,
//             style: TextStyle(
//               color: theme.primaryColor,
//               fontSize: 24.0,
//               fontWeight: FontWeight.w900,
//             ),
//           ),
//         ),
//       );
//     } else {
//       return Listener(
//         onPointerDown: (_) => _pointers++,
//         onPointerUp: (_) => _pointers--,
//         child: CameraPreview(
//           controller!,
//           child: LayoutBuilder(
//               builder: (BuildContext context, BoxConstraints constraints) {
//             return GestureDetector(
//               behavior: HitTestBehavior.opaque,
//               onScaleStart: _handleScaleStart,
//               onScaleUpdate: _handleScaleUpdate,
//               onTapDown: (TapDownDetails details) =>
//                   onViewFinderTap(details, constraints),
//             );
//           }),
//         ),
//       );
//     }
//   }

//   void _handleScaleStart(ScaleStartDetails details) {
//     _baseScale = _currentScale;
//   }

//   Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
//     // When there are not exactly two fingers on screen don't scale
//     if (controller == null || _pointers != 2) {
//       return;
//     }

//     _currentScale = (_baseScale * details.scale)
//         .clamp(_minAvailableZoom, _maxAvailableZoom);

//     await controller!.setZoomLevel(_currentScale);
//   }

//   /// Display the thumbnail of the captured image or video.
//   Widget _thumbnailWidget(ThemeData theme) {
//     final VideoPlayerController? localVideoController = videoController;

//     return Expanded(
//       child: Align(
//         alignment: Alignment.centerRight,
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: <Widget>[
//             if (localVideoController == null && imageFile == null)
//               Container()
//             else
//               SizedBox(
//                 width: 64.0,
//                 height: 64.0,
//                 child: (localVideoController == null)
//                     ? (
//                         // The captured image on the web contains a network-accessible URL
//                         // pointing to a location within the browser. It may be displayed
//                         // either with Image.network or Image.memory after loading the image
//                         // bytes to memory.
//                         kIsWeb
//                             ? Image.network(imageFile!.path)
//                             : Image.file(File(imageFile!.path)))
//                     : Container(
//                         decoration: BoxDecoration(
//                             border: Border.all(
//                                 color: theme
//                                         .buttonTheme?.colorScheme?.background ??
//                                     theme.hintColor)), //Colors.pink
//                         child: Center(
//                           child: AspectRatio(
//                               aspectRatio:
//                                   localVideoController.value.size != null
//                                       ? localVideoController.value.aspectRatio
//                                       : 1.0,
//                               child: VideoPlayer(localVideoController)),
//                         ),
//                       ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   /// Display a bar with buttons to change the flash and exposure modes
//   Widget _modeControlRowWidget(ThemeData theme) {
//     return Column(
//       children: <Widget>[
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           children: <Widget>[
//             IconButton(
//               icon: const Icon(Icons.flash_on),
//               color: theme.primaryColor,
//               onPressed: controller != null ? onFlashModeButtonPressed : null,
//             ),
//             // The exposure and focus mode are currently not supported on the web.
//             ...!kIsWeb
//                 ? <Widget>[
//                     IconButton(
//                       icon: const Icon(Icons.exposure),
//                       color: theme.primaryColor,
//                       onPressed: controller != null
//                           ? onExposureModeButtonPressed
//                           : null,
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.filter_center_focus),
//                       color: theme.primaryColor,
//                       onPressed:
//                           controller != null ? onFocusModeButtonPressed : null,
//                     )
//                   ]
//                 : <Widget>[],
//             ...enableFeatureAudio
//                 ? <Widget>[
//                     IconButton(
//                       key: const Key('iconButtonVolume'),
//                       icon: Icon(
//                           enableAudio ? Icons.volume_up : Icons.volume_mute),
//                       color: theme.primaryColor,
//                       onPressed:
//                           controller != null ? onAudioModeButtonPressed : null,
//                     ),
//                   ]
//                 : <Widget>[],
//             IconButton(
//               key: const Key('iconButtonCaptureOrientationLock'),
//               icon: Icon(controller?.value.isCaptureOrientationLocked ?? false
//                   ? Icons.screen_lock_rotation
//                   : Icons.screen_rotation),
//               color: theme.primaryColor,
//               onPressed: controller != null
//                   ? onCaptureOrientationLockButtonPressed
//                   : null,
//             ),
//             ...cameras.length > 1
//                 ? <Widget>[
//                     IconButton(
//                       icon: const Icon(Icons.cameraswitch_rounded),
//                       color: theme.primaryColor,
//                       onPressed: controller == null ? null : changeToNextCamera,
//                     )
//                   ]
//                 : <Widget>[],
//           ],
//         ),
//         _flashModeControlRowWidget(theme),
//         _exposureModeControlRowWidget(theme),
//         _focusModeControlRowWidget(theme),
//       ],
//     );
//   }

//   Widget _flashModeControlRowWidget(ThemeData theme) {
//     return SizeTransition(
//       sizeFactor: _flashModeControlRowAnimation,
//       child: ClipRect(
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           children: <Widget>[
//             IconButton(
//               icon: const Icon(Icons.flash_off),
//               color: controller?.value.flashMode == FlashMode.off
//                   ? Colors.orange
//                   : theme.primaryColor,
//               onPressed: controller != null
//                   ? () => onSetFlashModeButtonPressed(FlashMode.off)
//                   : null,
//             ),
//             IconButton(
//               icon: const Icon(Icons.flash_auto),
//               color: controller?.value.flashMode == FlashMode.auto
//                   ? Colors.orange
//                   : theme.primaryColor,
//               onPressed: controller != null
//                   ? () => onSetFlashModeButtonPressed(FlashMode.auto)
//                   : null,
//             ),
//             IconButton(
//               icon: const Icon(Icons.flash_on),
//               color: controller?.value.flashMode == FlashMode.always
//                   ? Colors.orange
//                   : theme.primaryColor,
//               onPressed: controller != null
//                   ? () => onSetFlashModeButtonPressed(FlashMode.always)
//                   : null,
//             ),
//             IconButton(
//               icon: const Icon(Icons.highlight),
//               color: controller?.value.flashMode == FlashMode.torch
//                   ? Colors.orange
//                   : theme.primaryColor,
//               onPressed: controller != null
//                   ? () => onSetFlashModeButtonPressed(FlashMode.torch)
//                   : null,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _exposureModeControlRowWidget(ThemeData theme) {
//     final ButtonStyle styleAuto = TextButton.styleFrom(
//       // TODO(darrenaustin): Migrate to new API once it lands in stable: https://github.com/flutter/flutter/issues/105724
//       // ignore: deprecated_member_use
//       primary: controller?.value.exposureMode == ExposureMode.auto
//           ? Colors.orange
//           : theme.primaryColor,
//     );
//     final ButtonStyle styleLocked = TextButton.styleFrom(
//       // TODO(darrenaustin): Migrate to new API once it lands in stable: https://github.com/flutter/flutter/issues/105724
//       // ignore: deprecated_member_use
//       primary: controller?.value.exposureMode == ExposureMode.locked
//           ? Colors.orange
//           : theme.primaryColor,
//     );

//     return SizeTransition(
//       sizeFactor: _exposureModeControlRowAnimation,
//       child: ClipRect(
//         child: Container(
//           color: theme.backgroundColor,
//           child: Column(
//             children: <Widget>[
//               const Center(
//                 child: Text('Exposure Mode'),
//               ),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: <Widget>[
//                   TextButton(
//                     style: styleAuto,
//                     onPressed: controller != null
//                         ? () =>
//                             onSetExposureModeButtonPressed(ExposureMode.auto)
//                         : null,
//                     onLongPress: () {
//                       if (controller != null) {
//                         controller!.setExposurePoint(null);
//                         showInSnackBar('Resetting exposure point');
//                       }
//                     },
//                     child: const Text('AUTO'),
//                   ),
//                   TextButton(
//                     style: styleLocked,
//                     onPressed: controller != null
//                         ? () =>
//                             onSetExposureModeButtonPressed(ExposureMode.locked)
//                         : null,
//                     child: const Text('LOCKED'),
//                   ),
//                   TextButton(
//                     style: styleLocked,
//                     onPressed: controller != null
//                         ? () => controller!.setExposureOffset(0.0)
//                         : null,
//                     child: const Text('RESET OFFSET'),
//                   ),
//                 ],
//               ),
//               const Center(
//                 child: Text('Exposure Offset'),
//               ),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: <Widget>[
//                   Text(_minAvailableExposureOffset.toString()),
//                   Slider(
//                     value: _currentExposureOffset,
//                     min: _minAvailableExposureOffset,
//                     max: _maxAvailableExposureOffset,
//                     label: _currentExposureOffset.toString(),
//                     onChanged: _minAvailableExposureOffset ==
//                             _maxAvailableExposureOffset
//                         ? null
//                         : setExposureOffset,
//                   ),
//                   Text(_maxAvailableExposureOffset.toString()),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _focusModeControlRowWidget(ThemeData theme) {
//     final ButtonStyle styleAuto = TextButton.styleFrom(
//       // TODO(darrenaustin): Migrate to new API once it lands in stable: https://github.com/flutter/flutter/issues/105724
//       // ignore: deprecated_member_use
//       primary: controller?.value.focusMode == FocusMode.auto
//           ? Colors.orange
//           : theme.primaryColor,
//     );
//     final ButtonStyle styleLocked = TextButton.styleFrom(
//       // TODO(darrenaustin): Migrate to new API once it lands in stable: https://github.com/flutter/flutter/issues/105724
//       // ignore: deprecated_member_use
//       primary: controller?.value.focusMode == FocusMode.locked
//           ? Colors.orange
//           : theme.primaryColor,
//     );

//     return SizeTransition(
//       sizeFactor: _focusModeControlRowAnimation,
//       child: ClipRect(
//         child: Container(
//           color: theme.backgroundColor,
//           child: Column(
//             children: <Widget>[
//               const Center(
//                 child: Text('Focus Mode'),
//               ),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: <Widget>[
//                   TextButton(
//                     style: styleAuto,
//                     onPressed: controller != null
//                         ? () => onSetFocusModeButtonPressed(FocusMode.auto)
//                         : null,
//                     onLongPress: () {
//                       if (controller != null) {
//                         controller!.setFocusPoint(null);
//                       }
//                       showInSnackBar('Resetting focus point');
//                     },
//                     child: const Text('AUTO'),
//                   ),
//                   TextButton(
//                     style: styleLocked,
//                     onPressed: controller != null
//                         ? () => onSetFocusModeButtonPressed(FocusMode.locked)
//                         : null,
//                     child: const Text('LOCKED'),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   /// Display the control bar with buttons to take pictures and record videos.
//   Widget _captureControlRowWidget(ThemeData theme) {
//     final CameraControllerPlus? cameraController = controller;

//     return !enableFeatureTake
//         ? Container()
//         : Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: <Widget>[
//               ...enableFeaturePhoto
//                   ? <Widget>[
//                       IconButton(
//                         icon: const Icon(Icons.camera_alt),
//                         color: theme.primaryColor,
//                         onPressed: cameraController != null &&
//                                 cameraController.value.isInitialized &&
//                                 !cameraController.value.isRecordingVideo
//                             ? onTakePictureButtonPressed
//                             : null,
//                       ),
//                     ]
//                   : <Widget>[],
//               ...enableFeatureVideo
//                   ? <Widget>[
//                       IconButton(
//                         icon: const Icon(Icons.videocam),
//                         color: theme.primaryColor,
//                         onPressed: cameraController != null &&
//                                 cameraController.value.isInitialized &&
//                                 !cameraController.value.isRecordingVideo
//                             ? onVideoRecordButtonPressed
//                             : null,
//                       ),
//                       IconButton(
//                         icon: cameraController != null &&
//                                 cameraController.value.isRecordingPaused
//                             ? const Icon(Icons.play_arrow)
//                             : const Icon(Icons.pause),
//                         color: theme.primaryColor,
//                         onPressed: cameraController != null &&
//                                 cameraController.value.isInitialized &&
//                                 cameraController.value.isRecordingVideo
//                             ? (cameraController.value.isRecordingPaused)
//                                 ? onResumeButtonPressed
//                                 : onPauseButtonPressed
//                             : null,
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.stop),
//                         color: Colors.red,
//                         onPressed: cameraController != null &&
//                                 cameraController.value.isInitialized &&
//                                 cameraController.value.isRecordingVideo
//                             ? onStopButtonPressed
//                             : null,
//                       ),
//                     ]
//                   : <Widget>[],
//               IconButton(
//                 icon: const Icon(Icons.pause_presentation),
//                 color: cameraController != null &&
//                         cameraController.value.isPreviewPaused
//                     ? Colors.red
//                     : theme.primaryColor,
//                 onPressed: cameraController == null
//                     ? null
//                     : onPausePreviewButtonPressed,
//               ),
//             ],
//           );
//   }

//   void changeToNextCamera() {
//     if (controller != null && cameras.isNotEmpty) {
//       bool stateChangeCamera = false;
//       for (int cameraIndex = 0; cameraIndex < cameras.length; cameraIndex++) {
//         if (stateChangeCamera) {
//           changeCamera(cameras[cameraIndex]);
//           break;
//         } else if (cameras[cameraIndex] == controller!.description) {
//           stateChangeCamera = true;
//           if (cameraIndex == cameras.length - 1) {
//             changeCamera(cameras[0]);
//             break;
//           }
//         }
//       }
//     }
//   }

//   void changeCamera(CameraDescription? description) {
//     if (description == null) {
//       return;
//     }

//     onNewCameraSelected(description);
//   }

//   /// Display a row of toggle to select the camera (or a message if no camera is available).
//   Widget _cameraTogglesRowWidget(ThemeData theme) {
//     final List<Widget> toggles = <Widget>[];

//     if (!enableFeatureIconsCameras) {
//       return Container(); //Text('None');
//     } else if (cameras.isEmpty) {
//       _ambiguate(SchedulerBinding.instance)?.addPostFrameCallback((_) async {
//         showInSnackBar('No camera found.');
//       });
//       return Container(); //Text('None');
//     } else {
//       for (final CameraDescription cameraDescription in cameras) {
//         toggles.add(
//           IconButton(
//             icon: Icon(getCameraLensIcon(cameraDescription.lensDirection)),
//             color: controller != null &&
//                     controller!.description == cameraDescription
//                 ? theme.primaryColor
//                 : theme.disabledColor,
//             onPressed: controller != null && controller!.value.isRecordingVideo
//                 ? null
//                 : () => changeCamera(cameraDescription),
//           ),
//         );
//       }
//     }

//     return Row(children: toggles);
//   }

//   String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

//   void showInSnackBar(String message) {
//     // ScaffoldMessenger.of(context)
//     //     .showSnackBar(SnackBar(content: Text(message)));
//   }

//   void showLogInSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//       content: Text(message),
//       duration: const Duration(days: 1),
//     ));
//   }

//   void onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
//     if (controller == null) {
//       return;
//     }

//     final CameraControllerPlus cameraController = controller!;

//     final Offset offset = Offset(
//       details.localPosition.dx / constraints.maxWidth,
//       details.localPosition.dy / constraints.maxHeight,
//     );
//     cameraController.setExposurePoint(offset);
//     cameraController.setFocusPoint(offset);
//   }

//   Future<void> onNewCameraSelected(CameraDescription cameraDescription) async {
//     final CameraControllerPlus? oldController = controller;
//     if (oldController != null) {
//       // `controller` needs to be set to null before getting disposed,
//       // to avoid a race condition when we use the controller that is being
//       // disposed. This happens when camera permission dialog shows up,
//       // which triggers `didChangeAppLifecycleState`, which disposes and
//       // re-creates the controller.
//       controller = null;
//       await oldController.dispose();
//     }

//     final CameraControllerPlus cameraController = CameraControllerPlus(
//       cameraDescription,
//       kIsWeb ? ResolutionPreset.max : ResolutionPreset.medium,
//       enableAudio: enableAudio,
//       imageFormatGroup: ImageFormatGroup.jpeg,
//     );

//     controller = cameraController;

//     // If the controller is updated then update the UI.
//     cameraController.addListener(() {
//       if (mounted) {
//         setState(() {});
//       }
//       if (cameraController.value.hasError) {
//         showInSnackBar(
//             'Camera error ${cameraController.value.errorDescription}');
//       }
//     });

//     try {
//       await cameraController.initialize();
//       Future<double>? maxZoomLevel;
//       try {
//         maxZoomLevel = cameraController.getMaxZoomLevel();
//       } catch (e) {}
//       Future<double>? minZoomLevel;
//       try {
//         minZoomLevel = cameraController.getMinZoomLevel();
//       } catch (e) {}

//       await Future.wait(<Future<Object?>>[
//         // The exposure mode is currently not supported on the web.
//         ...!kIsWeb
//             ? <Future<Object?>>[
//                 cameraController.getMinExposureOffset().then(
//                     (double value) => _minAvailableExposureOffset = value),
//                 cameraController
//                     .getMaxExposureOffset()
//                     .then((double value) => _maxAvailableExposureOffset = value)
//               ]
//             : <Future<Object?>>[],
//         ...maxZoomLevel != null
//             ? <Future<Object>>[
//                 maxZoomLevel.then((double value) => _maxAvailableZoom = value)
//               ]
//             : <Future<Object>>[],
//         ...minZoomLevel != null
//             ? <Future<Object>>[
//                 minZoomLevel.then((double value) => _minAvailableZoom = value)
//               ]
//             : <Future<Object>>[],
//       ]);
//     } on CameraException catch (e) {
//       switch (e.code) {
//         case 'CameraAccessDenied':
//           showInSnackBar('You have denied camera access.');
//           break;
//         case 'CameraAccessDeniedWithoutPrompt':
//           // iOS only
//           showInSnackBar('Please go to Settings app to enable camera access.');
//           break;
//         case 'CameraAccessRestricted':
//           // iOS only
//           showInSnackBar('Camera access is restricted.');
//           break;
//         case 'AudioAccessDenied':
//           showInSnackBar('You have denied audio access.');
//           break;
//         case 'AudioAccessDeniedWithoutPrompt':
//           // iOS only
//           showInSnackBar('Please go to Settings app to enable audio access.');
//           break;
//         case 'AudioAccessRestricted':
//           // iOS only
//           showInSnackBar('Audio access is restricted.');
//           break;
//         default:
//           _showCameraException(e);
//           break;
//       }
//     } on PlatformException catch (e) {
//       showInSnackBar(e.toString());
//     }

//     if (mounted) {
//       setState(() {});
//     }
//   }

//   void onTakePictureButtonPressed() {
//     if (enableFeaturePhoto) {
//       takePicture().then((XFile? file) {
//         if (mounted) {
//           setState(() {
//             imageFile = file;
//             videoController?.dispose();
//             videoController = null;
//           });
//           if (file != null) {
//             showInSnackBar('Picture saved to ${file.path}');
//           }
//         }
//       });
//     }
//   }

//   void onFlashModeButtonPressed() {
//     if (_flashModeControlRowAnimationController.value == 1) {
//       _flashModeControlRowAnimationController.reverse();
//     } else {
//       _flashModeControlRowAnimationController.forward();
//       _exposureModeControlRowAnimationController.reverse();
//       _focusModeControlRowAnimationController.reverse();
//     }
//   }

//   void onExposureModeButtonPressed() {
//     if (_exposureModeControlRowAnimationController.value == 1) {
//       _exposureModeControlRowAnimationController.reverse();
//     } else {
//       _exposureModeControlRowAnimationController.forward();
//       _flashModeControlRowAnimationController.reverse();
//       _focusModeControlRowAnimationController.reverse();
//     }
//   }

//   void onFocusModeButtonPressed() {
//     if (_focusModeControlRowAnimationController.value == 1) {
//       _focusModeControlRowAnimationController.reverse();
//     } else {
//       _focusModeControlRowAnimationController.forward();
//       _flashModeControlRowAnimationController.reverse();
//       _exposureModeControlRowAnimationController.reverse();
//     }
//   }

//   void onAudioModeButtonPressed() {
//     if (enableFeatureAudio) {
//       enableAudio = !enableAudio;
//       if (controller != null) {
//         onNewCameraSelected(controller!.description);
//       }
//     }
//   }

//   Future<void> onCaptureOrientationLockButtonPressed() async {
//     try {
//       if (controller != null) {
//         final CameraControllerPlus cameraController = controller!;
//         if (cameraController.value.isCaptureOrientationLocked) {
//           await cameraController.unlockCaptureOrientation();
//           showInSnackBar('Capture orientation unlocked');
//         } else {
//           await cameraController.lockCaptureOrientation();
//           showInSnackBar(
//               'Capture orientation locked to ${cameraController.value.lockedCaptureOrientation.toString().split('.').last}');
//         }
//       }
//     } on CameraException catch (e) {
//       _showCameraException(e);
//     }
//   }

//   void onSetFlashModeButtonPressed(FlashMode mode) {
//     setFlashMode(mode).then((_) {
//       if (mounted) {
//         setState(() {});
//       }
//       showInSnackBar('Flash mode set to ${mode.toString().split('.').last}');
//     });
//   }

//   void onSetExposureModeButtonPressed(ExposureMode mode) {
//     setExposureMode(mode).then((_) {
//       if (mounted) {
//         setState(() {});
//       }
//       showInSnackBar('Exposure mode set to ${mode.toString().split('.').last}');
//     });
//   }

//   void onSetFocusModeButtonPressed(FocusMode mode) {
//     setFocusMode(mode).then((_) {
//       if (mounted) {
//         setState(() {});
//       }
//       showInSnackBar('Focus mode set to ${mode.toString().split('.').last}');
//     });
//   }

//   void onVideoRecordButtonPressed() {
//     if (enableFeatureVideo) {
//       startVideoRecording().then((_) {
//         if (mounted) {
//           setState(() {});
//         }
//       });
//     }
//   }

//   void onStopButtonPressed() {
//     stopVideoRecording().then((XFile? file) {
//       if (mounted) {
//         setState(() {});
//       }
//       if (file != null) {
//         showInSnackBar('Video recorded to ${file.path}');
//         videoFile = file;
//         _startVideoPlayer();
//       }
//     });
//   }

//   Future<void> onPausePreviewButtonPressed() async {
//     final CameraControllerPlus? cameraController = controller;

//     if (cameraController == null || !cameraController.value.isInitialized) {
//       showInSnackBar('Error: select a camera first.');
//       return;
//     }

//     if (cameraController.value.isPreviewPaused) {
//       await cameraController.resumePreview();
//     } else {
//       await cameraController.pausePreview();
//     }

//     if (mounted) {
//       setState(() {});
//     }
//   }

//   void onPauseButtonPressed() {
//     pauseVideoRecording().then((_) {
//       if (mounted) {
//         setState(() {});
//       }
//       showInSnackBar('Video recording paused');
//     });
//   }

//   void onResumeButtonPressed() {
//     resumeVideoRecording().then((_) {
//       if (mounted) {
//         setState(() {});
//       }
//       showInSnackBar('Video recording resumed');
//     });
//   }

//   Future<void> startVideoRecording() async {
//     final CameraControllerPlus? cameraController = controller;

//     if (cameraController == null || !cameraController.value.isInitialized) {
//       showInSnackBar('Error: select a camera first.');
//       return;
//     }

//     if (cameraController.value.isRecordingVideo) {
//       // A recording is already started, do nothing.
//       return;
//     }

//     try {
//       await cameraController.startVideoRecording();
//     } on CameraException catch (e) {
//       _showCameraException(e);
//       return;
//     }
//   }

//   Future<XFile?> stopVideoRecording() async {
//     final CameraControllerPlus? cameraController = controller;

//     if (cameraController == null || !cameraController.value.isRecordingVideo) {
//       return null;
//     }

//     try {
//       return cameraController.stopVideoRecording();
//     } on CameraException catch (e) {
//       _showCameraException(e);
//       return null;
//     }
//   }

//   Future<void> pauseVideoRecording() async {
//     final CameraControllerPlus? cameraController = controller;

//     if (cameraController == null || !cameraController.value.isRecordingVideo) {
//       return;
//     }

//     try {
//       await cameraController.pauseVideoRecording();
//     } on CameraException catch (e) {
//       _showCameraException(e);
//       rethrow;
//     }
//   }

//   Future<void> resumeVideoRecording() async {
//     final CameraControllerPlus? cameraController = controller;

//     if (cameraController == null || !cameraController.value.isRecordingVideo) {
//       return;
//     }

//     try {
//       await cameraController.resumeVideoRecording();
//     } on CameraException catch (e) {
//       _showCameraException(e);
//       rethrow;
//     }
//   }

//   Future<void> setFlashMode(FlashMode mode) async {
//     if (controller == null) {
//       return;
//     }

//     try {
//       await controller!.setFlashMode(mode);
//     } on CameraException catch (e) {
//       _showCameraException(e);
//       rethrow;
//     }
//   }

//   Future<void> setExposureMode(ExposureMode mode) async {
//     if (controller == null) {
//       return;
//     }

//     try {
//       await controller!.setExposureMode(mode);
//     } on CameraException catch (e) {
//       _showCameraException(e);
//       rethrow;
//     }
//   }

//   Future<void> setExposureOffset(double offset) async {
//     if (controller == null) {
//       return;
//     }

//     setState(() {
//       _currentExposureOffset = offset;
//     });
//     try {
//       offset = await controller!.setExposureOffset(offset);
//     } on CameraException catch (e) {
//       _showCameraException(e);
//       rethrow;
//     }
//   }

//   Future<void> setFocusMode(FocusMode mode) async {
//     if (controller == null) {
//       return;
//     }

//     try {
//       await controller!.setFocusMode(mode);
//     } on CameraException catch (e) {
//       _showCameraException(e);
//       rethrow;
//     }
//   }

//   Future<void> _startVideoPlayer() async {
//     if (videoFile == null) {
//       return;
//     }

//     final VideoPlayerController vController = kIsWeb
//         ? VideoPlayerController.network(videoFile!.path)
//         : VideoPlayerController.file(File(videoFile!.path));

//     videoPlayerListener = () {
//       if (videoController != null && videoController!.value.size != null) {
//         // Refreshing the state to update video player with the correct ratio.
//         if (mounted) {
//           setState(() {});
//         }
//         videoController!.removeListener(videoPlayerListener!);
//       }
//     };
//     vController.addListener(videoPlayerListener!);
//     await vController.setLooping(true);
//     await vController.initialize();
//     await videoController?.dispose();
//     if (mounted) {
//       setState(() {
//         imageFile = null;
//         videoController = vController;
//       });
//     }
//     await vController.play();
//   }

//   Future<XFile?> takePicture() async {
//     final CameraControllerPlus? cameraController = controller;
//     if (cameraController == null || !cameraController.value.isInitialized) {
//       showInSnackBar('Error: select a camera first.');
//       return null;
//     }

//     if (cameraController.value.isTakingPicture) {
//       // A capture is already pending, do nothing.
//       return null;
//     }

//     try {
//       final XFile file = await cameraController.takePicture();
//       return file;
//     } on CameraException catch (e) {
//       _showCameraException(e);
//       return null;
//     }
//   }

//   void _showCameraException(CameraException e) {
//     logError(e.code, e.description);
//     showInSnackBar('Error: ${e.code}\n${e.description}');
//   }
// }

// Map<CameraLensDirection, IconData> cameraLensDirectionIcon = {
//   CameraLensDirection.front: Icons.camera_front,
//   CameraLensDirection.back: Icons.camera_rear,
//   CameraLensDirection.external: Icons.camera,
//   //throw ArgumentError('Unknown lens direction');
// };

// IconData getCameraLensIcon(CameraLensDirection cameraLensDirection) =>
//     cameraLensDirectionIcon.containsKey(cameraLensDirection)
//         ? cameraLensDirectionIcon[cameraLensDirection]!
//         : Icons.camera;

// /// This allows a value of type T or T? to be treated as a value of type T?.
// ///
// /// We use this so that APIs that have become non-nullable can still be used
// /// with `!` and `?` on the stable branch.
// // TODO(ianh): Remove this once we roll stable in late 2021.
// T? _ambiguate<T>(T? value) => value;
