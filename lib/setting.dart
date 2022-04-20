import 'config/config.dart' as gc;
import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import 'package:localstorage/localstorage.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Material(
      child: MySettingPage(title: gc.title_setting),
    );
  }
}

class MySettingPage extends StatefulWidget {
  const MySettingPage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  State<MySettingPage> createState() => _MySettingState();
}

class _MySettingState extends State<MySettingPage> {
  LocalStorage localStorage = LocalStorage(gc.ls_name);
  double? _compressionRatio;

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
    var compressionRatio =
        await localStorage.getItem(gc.set_key_compression) ??
            gc.default_compression_ration;
    setState(() {
      _compressionRatio = compressionRatio;
    });
  }

  _onChange(String key, var value) {
    localStorage.setItem(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Container(
          margin: const EdgeInsets.only(
              left: 10.0, right: 10.0, top: 20.0, bottom: 20.0),
          width: 350,
          height: 80,
          child: Column(children: [
            Text(gc.set_title_compression + ": " + _compressionRatio.toString()),
            Slider(
              value: _compressionRatio ?? gc.default_compression_ration,
              max: gc.set_max_compression.toDouble(),
              min: gc.set_min_compression.toDouble(),
              label: (_compressionRatio?.toInt().toString() ?? "") + "%",
              divisions: (gc.set_max_compression - gc.set_min_compression),
              onChangeEnd: (double value) {
                _onChange(gc.set_key_compression, value);
              },
              onChanged: (double value) {
                setState(() {
                  _compressionRatio = value;
                }
              );
            })
          ]),
        )
    );
  }
}
