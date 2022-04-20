import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:localstorage/localstorage.dart';
import 'config/config.dart' as gc;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'setting.dart' as setting;

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: gc.title_main,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: gc.title_main),
      builder: EasyLoading.init(),
      initialRoute: '/',
      routes: {
        gc.ru_setting: (BuildContext context) => const setting.SettingPage(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  LocalStorage localStorage = LocalStorage(gc.ls_name);
  String? _imgPath;
  double? _compressionRatio;
  Uint8List? _imgInShow;

  @override
  initState() {
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _getStorage();
    });
    super.initState();
  }

  Future _getStorage() async {
    // refer to this link https://stackoverflow.com/questions/51901002/is-there-a-way-to-load-async-data-on-initstate-method, get async data in initState
    await localStorage.ready;
    var compressionRatio = await localStorage.getItem(gc.set_key_compression) ??
        gc.default_compression_ration;
    var imgPath = await localStorage.getItem(gc.ls_item_img_path);
    var imgInShow = File(
            imgPath ?? (gc.default_camera1_path + gc.default_replace_img))
        .readAsBytesSync(); // read bytes rather than use FileImage to avoid image lazy update (choose a new image, but show the old one)
    setState(() {
      _compressionRatio = compressionRatio;
      _imgPath = imgPath;
      _imgInShow = imgInShow;
    });
    print(_compressionRatio);
  }

  Future<void> _deleteCache() async {
    var tempDir = await getTemporaryDirectory();

    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  }

  _checkPermission() async {
    var statusStorage = await Permission.storage.status;
    if (!statusStorage.isGranted) {
      await Permission.storage.request();
    }
    var statusAccessMediaLocation = await Permission.accessMediaLocation.status;
    if (!statusAccessMediaLocation.isGranted) {
      await Permission.accessMediaLocation.request();
    }
    var statusManageExternalStorage =
        await Permission.accessMediaLocation.status;
    if (!statusManageExternalStorage.isGranted) {
      await Permission.manageExternalStorage.request();
    }
  }

  _showToast(msg) {
    Fluttertoast.showToast(
        msg: msg ?? "",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: const Color.fromARGB(255, 100, 100, 100),
        textColor: const Color.fromARGB(255, 230, 230, 230),
        fontSize: 16.0);
  }

  _changeImg(imgPath) async {
    if (null != imgPath && "" != imgPath) {
      imageCache?.clear();
      var newImgPath = _copyImg(imgPath);
      setState(() {
        _imgInShow = File(newImgPath).readAsBytesSync();
        _imgPath = newImgPath;
      });
      await File(imgPath).delete();
      localStorage.setItem(gc.ls_item_img_path, newImgPath);
      _deleteCache();
      // return;
    } else {
      await _deleteImg();
      setState(() {
        _imgInShow = null;
        _imgPath = null;
      });
      localStorage.deleteItem(gc.ls_item_img_path);
      _deleteCache();
    }
  }

  _copyImg(imgPath) {
    try {
      File newImgFile = File(imgPath)
          .copySync(gc.default_camera1_path + gc.default_replace_img);
      return newImgFile.path;
    } on Exception {
      _showToast(gc.msg_save_img_err);
      return "";
    }
  }

  _deleteImg() {
    try {
      File(gc.default_camera1_path + gc.default_replace_img).deleteSync();
    } on Exception {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 350,
                height: 550,
                margin: const EdgeInsets.only(
                    left: 10.0, right: 10.0, top: 20.0, bottom: 20.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blueAccent),
                  borderRadius: const BorderRadius.all(Radius.circular(5.0)),
                ),
                child: InkWell(
                    onTap: () async {
                      await _checkPermission();
                      final ImagePicker _picker = ImagePicker();
                      // Pick an image
                      final XFile? image = await _picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: _compressionRatio?.toInt());
                      if (image != null) {
                        EasyLoading.show(status: gc.msg_copying_img);
                        _changeImg(image.path);
                        EasyLoading.dismiss();
                        _showToast(gc.msg_img_changed);
                      } else {
                        _showToast(gc.msg_no_img_changed);
                      }
                    },
                    child: Container(
                        width: 350,
                        height: 550,
                        decoration: (null != _imgPath && "" != _imgPath)
                            ? BoxDecoration(
                                image: DecorationImage(
                                    image: MemoryImage(_imgInShow!)))
                            : null,
                        child: (null == _imgPath || "" == _imgPath)
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.add_a_photo,
                                      size: 26.0,
                                    ),
                                    Text(gc.btn_add_img),
                                  ],
                                ),
                              )
                            : null)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    // remove image
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.all(16.0),
                        backgroundColor: const Color.fromARGB(255, 13, 172, 66),
                        maximumSize: const Size(400, 80)),
                    onPressed: () async {
                      await _checkPermission();
                      _changeImg(null);
                      _showToast(gc.msg_img_removed);
                    },
                    child: const Text(
                      gc.btn_remove_img,
                      style: TextStyle(
                          color: Color.fromARGB(255, 255, 255, 255),
                          fontSize: 18.0),
                    ),
                  ),
                  TextButton(
                    // setting
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.all(16.0),
                      textStyle: const TextStyle(
                          color: Color.fromARGB(255, 12, 12, 12)),
                      backgroundColor: const Color.fromARGB(255, 116, 185, 231),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        gc.ru_setting,
                      ).then((value) => {_getStorage()});// re-read data from localstorage
                    },
                    child: const Text(
                      gc.btn_set_app,
                      style: TextStyle(
                          color: Color.fromARGB(255, 255, 255, 255),
                          fontSize: 18.0),
                    ),
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}
