<img src="android/app/src/main/res/mipmap-mdpi/ic_launcher.png" width="160px" />

# Call打电话

一个工具类APP，用于老人快捷方便拨打家人电话、微信视频通话。使用Flutter编写

## 开发环境

- flutter 3.26.0-0.1.pre
- dart 3.6.0-216.1.beta
- gradle 8.3
- gradle-plugin 8.1.4
- kotlin 1.8.22

## 功能特点

- 点击头像拨打普通电话、微信视频通话
- 添加、编辑、删除联系人姓名、图片、微信昵称/备注、语音播报内容
- 查询通话记录（电话、微信）
- 设置语音播报TTS音量、语速，点击联系人震动时长、强度
- 联系人拖动排序
- 权限管理（无障碍、打电话、相册、设置）
- 导出联系人照片
- 联系人数据库管理
- 手机系统信息查看

## 界面截图
![UI](assets/screenshot/ui.jpg)

## 源码说明

> ```
> Call
> ├─android              # Android工程配置
> ├─assets               # 资源文件目录
> ├─ios                  # iOS工程配置
> ├─lib                  # flutter源代码目录
> │  ├─data              # 数据类
> │  ├─page              # 各个页面
> │  ├─utls              # 工具类
> │  └─main.dart         # APP入口
> └─test                 # 测试目录
> ```
