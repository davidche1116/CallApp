import 'dart:async';
import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_ruler_picker/flutter_ruler_picker.dart';

import '../utls/crop_editor_helper.dart';
import '../utls/widget_util.dart';

class ImageEditPage extends StatefulWidget {
  final File _file;

  const ImageEditPage(this._file, {super.key});

  @override
  State<ImageEditPage> createState() => _ImageEditPageState();
}

class _ImageEditPageState extends State<ImageEditPage> {
  final ImageEditorController _editorController = ImageEditorController();
  final MyRulerPickerController _rulerPickerController =
      MyRulerPickerController(value: 0.0);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider imageProvider = ExtendedFileImageProvider(
      widget._file,
      cacheRawData: true,
    );

    return Scaffold(
      body: Stack(
        children: [
          ExtendedImage(
            image: imageProvider,
            fit: BoxFit.contain,
            mode: ExtendedImageMode.editor,
            enableLoadState: true,
            initEditorConfigHandler: (ExtendedImageState? state) {
              return EditorConfig(
                maxScale: 16.0,
                cropRectPadding: const EdgeInsets.all(20.0),
                hitTestSize: 20.0,
                cropLayerPainter: const EditorCropLayerPainter(),
                initCropRectType: InitCropRectType.imageRect,
                cropAspectRatio: CropAspectRatios.ratio1_1,
                controller: _editorController,
                cornerColor: Theme.of(context).colorScheme.onPrimary,
              );
            },
          ),
          SafeArea(
            child: Column(
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  actions: [
                    FilledButton(
                      onPressed: () async {
                        WidgetUtil.showLoading('处理中');

                        /// 裁剪
                        var list = await _cropImage(true);

                        /// 压缩
                        var result =
                            await FlutterImageCompress.compressWithList(
                              list!,
                              minHeight: 800,
                              minWidth: 800,
                              quality: 90,
                            );

                        WidgetUtil.hideLoading();

                        if (context.mounted) {
                          Navigator.pop(context, result);
                        }
                      },
                      child: const Text('完成'),
                    ),
                    SizedBox(width: 20),
                  ],
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (BuildContext c, BoxConstraints b) {
                            return RulerPicker(
                              controller: _rulerPickerController,
                              rulerBackgroundColor: Colors.transparent,
                              onValueChanged: (num value) {
                                if (_rulerPickerController.value
                                        .toDouble()
                                        .equalTo(value.toDouble()) &&
                                    !_onUndoOrRedoing) {
                                  return;
                                }
                                HapticFeedback.vibrate();

                                _editorController.rotate(
                                  degree:
                                      value.toDouble() -
                                      _rulerPickerController.value,
                                );

                                _rulerPickerController.setValueWithOutNotify(
                                  value,
                                );
                              },
                              width: b.maxWidth,
                              height: 50,
                              onBuildRulerScaleText:
                                  (int index, num rulerScaleValue) {
                                    return '$rulerScaleValue';
                                  },
                              ranges: const <RulerRange>[
                                RulerRange(begin: -45, end: 45, scale: 1),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        onPressed: () {
                          _onUndoOrRedo(() {
                            _editorController.undo();
                          });
                        },
                        icon: Icon(Icons.undo, size: 30),
                      ),
                      IconButton(
                        onPressed: () {
                          _onUndoOrRedo(() {
                            _editorController.redo();
                          });
                        },
                        icon: Icon(Icons.redo, size: 30),
                      ),
                      IconButton(
                        onPressed: () {
                          _rulerPickerController.value = 0;
                          _editorController.reset();
                        },
                        icon: Icon(Icons.restore, size: 30),
                      ),
                      IconButton(
                        onPressed: () {
                          _editorController.flip(animation: true);
                        },
                        icon: const Icon(Icons.flip, size: 30),
                      ),
                      IconButton(
                        onPressed: () {
                          _editorController.rotate(
                            degree: 90,
                            animation: true,
                            rotateCropRect: true,
                          );
                        },
                        icon: const Icon(Icons.rotate_right, size: 30),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _onUndoOrRedoing = false;
  void _onUndoOrRedo(Function fn) {
    final double oldRotateDegrees = _editorController.rotateDegrees;
    _onUndoOrRedoing = true;
    fn();
    _onUndoOrRedoing = false;
    final double newRotateDegrees = _editorController.rotateDegrees;
    if (oldRotateDegrees != newRotateDegrees &&
        !(newRotateDegrees - oldRotateDegrees).isZero &&
        (newRotateDegrees - oldRotateDegrees) % 90 != 0) {
      _rulerPickerController.value =
          _rulerPickerController.value + (newRotateDegrees - oldRotateDegrees);
    }
  }

  Future<Uint8List?> _cropImage(bool useNative) async {
    String msg = '';
    try {
      EditImageInfo imageInfo = await cropImageDataWithNativeLibrary(
        _editorController,
      );
      return imageInfo.data;
    } catch (e, stack) {
      msg = 'save failed: $e\n $stack';
      debugPrint(msg);
    }

    return null;
  }
}

class MyRulerPickerController extends RulerPickerController {
  MyRulerPickerController({num value = 0}) : _value = value;
  @override
  num get value => _value;
  num _value;
  @override
  set value(num newValue) {
    if (_value == newValue) {
      return;
    }
    _value = newValue;
    notifyListeners();
  }

  void setValueWithOutNotify(num newValue) {
    _value = newValue;
  }
}
