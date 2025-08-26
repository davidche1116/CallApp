import 'dart:io';

import 'package:call/data/phone_info.dart';
import 'package:call/page/image_edit_page.dart';
import 'package:call/utls/db_util.dart';
import 'package:call/utls/style_util.dart';
import 'package:call/utls/widget_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class AddPage extends StatefulWidget {
  const AddPage({this.info, super.key});

  /// info默认null：新增联系人；!=null：修改联系人
  final PhoneInfo? info;

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  late ValueNotifier<String> _photoFilePath;

  late TextEditingController _controllerName;
  late TextEditingController _controllerPhone;
  late TextEditingController _controllerVoice;
  late TextEditingController _controllerWechat;
  late FocusNode _focusNodeName;
  late FocusNode _focusNodePhone;
  late FocusNode _focusNodeVoice;
  late FocusNode _focusNodeWechat;
  late int _num;

  @override
  void initState() {
    super.initState();

    _controllerName = TextEditingController();
    _controllerPhone = TextEditingController();
    _controllerVoice = TextEditingController();
    _controllerWechat = TextEditingController();

    _focusNodeName = FocusNode();
    _focusNodePhone = FocusNode();
    _focusNodeVoice = FocusNode();
    _focusNodeWechat = FocusNode();

    if (widget.info != null) {
      _photoFilePath = ValueNotifier(widget.info!.photo);
      _controllerName.text = widget.info!.name;
      _controllerPhone.text = widget.info!.phone;
      _controllerVoice.text = widget.info!.voice;
      _controllerWechat.text = widget.info!.wechat;
      _num = widget.info!.num;
    } else {
      _photoFilePath = ValueNotifier("");
    }
  }

  @override
  void dispose() {
    _focusNodeName.dispose();
    _focusNodePhone.dispose();
    _focusNodeVoice.dispose();
    _focusNodeWechat.dispose();

    _controllerName.dispose();
    _controllerPhone.dispose();
    _controllerVoice.dispose();
    _controllerWechat.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: (widget.info != null)
            ? const Text('编辑联系人')
            : const Text('添加联系人'),
        actions: [
          IconButton(
            onPressed: () {
              _saveOrEdit(widget.info != null);
            },
            icon: const Icon(CupertinoIcons.tray),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        children: [
          WidgetUtil.titleText('头像'),
          _photoWidget(),
          WidgetUtil.titleText('姓名'),
          TextField(
            controller: _controllerName,
            focusNode: _focusNodeName,
            textAlign: TextAlign.center,
            style: StyleUtil.textStyle,
            maxLength: 16,
            onSubmitted: (_) {
              if (_controllerPhone.text.isEmpty) {
                FocusScope.of(context).requestFocus(_focusNodePhone);
              }
            },
          ),
          WidgetUtil.titleText('号码'),
          TextField(
            controller: _controllerPhone,
            focusNode: _focusNodePhone,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.phone,
            style: StyleUtil.textStyle,
            maxLength: 32,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
            ],
            onSubmitted: (_) => _saveOrEdit(widget.info != null),
          ),
          WidgetUtil.titleText('语音'),
          TextField(
            controller: _controllerVoice,
            focusNode: _focusNodeVoice,
            textAlign: TextAlign.center,
            style: StyleUtil.textStyle,
            maxLength: 16,
            onSubmitted: (_) => _saveOrEdit(widget.info != null),
          ),
          WidgetUtil.titleText('微信'),
          TextField(
            controller: _controllerWechat,
            focusNode: _focusNodeWechat,
            textAlign: TextAlign.center,
            style: StyleUtil.textStyle,
            maxLength: 16,
            onSubmitted: (_) => _saveOrEdit(widget.info != null),
          ),
        ],
      ),
    );
  }

  Widget _photoWidget() {
    return GestureDetector(
      onTap: () async {
        final List<AssetEntity>? list = await AssetPicker.pickAssets(
          context,
          pickerConfig: AssetPickerConfig(
            maxAssets: 1,
            requestType: RequestType.image,
            themeColor: Theme.of(context).colorScheme.onPrimary,
          ),
        );
        if (list != null && list.length == 1) {
          File? path = await list.first.file;
          if (!mounted) return;
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ImageEditPage(path!)),
          );

          if (result != null) {
            /// 获取存储目录
            var tempDir = await getApplicationDocumentsDirectory();

            /// 生成file文件格式
            var file = await File(
              '${tempDir.path}/image_${DateTime.now().toString().replaceAll(' ', '_')}.jpg',
            ).create();
            //转成file文件
            file.writeAsBytesSync(result);
            _photoFilePath.value = file.path;

            await Future.delayed(const Duration(seconds: 1));
            if (!mounted) {
              return;
            }
            if (_controllerName.text.isEmpty) {
              FocusScope.of(context).requestFocus(_focusNodeName);
            }
          }
        }
      },
      child: Container(
        constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
        child: Center(
          child: AspectRatio(
            aspectRatio: 1.0,
            child: ValueListenableBuilder(
              valueListenable: _photoFilePath,
              builder: (BuildContext context, String value, Widget? child) {
                return WidgetUtil.photoImageIcon(
                  value,
                  200,
                  Colors.transparent,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveOrEdit(bool isEdit) async {
    String name = _controllerName.text;
    String phone = _controllerPhone.text;
    if (name.isEmpty || phone.isEmpty) {
      WidgetUtil.showToast('姓名和号码不能为空');
    } else {
      await WidgetUtil.confirmPopup(
        '是否保存【$name】？',
        onTap: () async {
          if (isEdit) {
            await DbUtil().updateInfo(
              PhoneInfo(
                name,
                phone,
                _photoFilePath.value,
                id: widget.info!.id,
                num: _num,
                voice: _controllerVoice.text,
                wechat: _controllerWechat.text,
              ),
            );
          } else {
            await DbUtil().addInfo(
              PhoneInfo(
                name,
                phone,
                _photoFilePath.value,
                voice: _controllerVoice.text,
                wechat: _controllerWechat.text,
              ),
            );
          }
          await DbUtil().queryInfo();
          WidgetUtil.showToast(isEdit ? '编辑成功' : '保存成功');
          if (!mounted) return;
          Navigator.pop(context);
        },
      );
    }
  }
}
