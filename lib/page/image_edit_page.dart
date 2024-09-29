import 'dart:io';
import 'dart:typed_data';

import 'package:call/utls/widget_util.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_editor/image_editor.dart' hide ImageSource;

class ImageEditPage extends StatefulWidget {
  final File _file;

  const ImageEditPage(this._file, {super.key});

  @override
  State<ImageEditPage> createState() => _ImageEditPageState();
}

class _ImageEditPageState extends State<ImageEditPage> {
  final GlobalKey<ExtendedImageEditorState> _editorKey = GlobalKey();

  late ImageProvider _provider;

  @override
  void initState() {
    super.initState();

    _provider = ExtendedFileImageProvider(
      widget._file,
      cacheRawData: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            _buildImage(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildBack(),
                  const Spacer(),
                  _buildButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBack() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back,
            size: 30,
          ),
        ),
      ],
    );
  }

  Widget _buildButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        IconButton(
          onPressed: () => _flip(),
          icon: const Icon(Icons.flip, size: 30),
        ),
        IconButton(
          onPressed: () => _rotate(false),
          icon: const Icon(Icons.rotate_left, size: 30),
        ),
        IconButton(
          onPressed: () => _rotate(true),
          icon: const Icon(Icons.rotate_right, size: 30),
        ),
        FilledButton(
          onPressed: () async {
            WidgetUtil.showLoading('处理中');

            /// 裁剪
            var list = await _crop();

            /// 压缩
            var result = await FlutterImageCompress.compressWithList(
              list!,
              minHeight: 800,
              minWidth: 800,
              quality: 90,
            );

            WidgetUtil.hideLoading();
            if (!mounted) return;
            Navigator.pop(context, result);
          },
          child: const Text(
            '完成',
          ),
        ),
      ],
    );
  }

  Widget _buildImage() {
    return ExtendedImage(
      image: _provider,
      extendedImageEditorKey: _editorKey,
      mode: ExtendedImageMode.editor,
      fit: BoxFit.contain,
      initEditorConfigHandler: (_) => EditorConfig(
          maxScale: 16.0,
          cropRectPadding: const EdgeInsets.all(20.0),
          hitTestSize: 20.0,
          cropAspectRatio: CropAspectRatios.ratio1_1,
          cornerColor:
              Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7)),
    );
  }

  Future<Uint8List?> _crop() async {
    final ExtendedImageEditorState? state = _editorKey.currentState;
    if (state == null) {
      return null;
    }
    final Rect? rect = state.getCropRect();
    if (rect == null) {
      return null;
    }
    final EditActionDetails action = state.editAction!;
    final double radian = action.rotateAngle;

    final bool flipHorizontal = action.flipY;
    final bool flipVertical = action.flipX;
    final Uint8List img = state.rawImageData;

    if (img.isEmpty) {
      return null;
    }

    final ImageEditorOption option = ImageEditorOption();

    option.addOption(ClipOption.fromRect(rect));
    option.addOption(
        FlipOption(horizontal: flipHorizontal, vertical: flipVertical));
    if (action.hasRotateAngle) {
      option.addOption(RotateOption(radian.toInt()));
    }

    option.outputFormat = const OutputFormat.jpeg(80);

    final Uint8List? result = await ImageEditor.editImage(
      image: img,
      imageEditorOption: option,
    );

    return result;
  }

  void _flip() {
    _editorKey.currentState?.flip();
  }

  void _rotate(bool right) {
    _editorKey.currentState?.rotate(right: right);
  }
}
