import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nfc_manager/platform_tags.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:convert/convert.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  ValueNotifier<dynamic> result = ValueNotifier(null);

  @override
  void initState() {
    super.initState();

    _tagRead();
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('NfcManager Plugin Example')),
        body: SafeArea(
          child: FutureBuilder<bool>(
            future: NfcManager.instance.isAvailable(),
            builder: (context, ss) => ss.data != true
                ? Center(child: Text('NfcManager.isAvailable(): ${ss.data}'))
                : Flex(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    direction: Axis.vertical,
                    children: [
                      Flexible(
                        flex: 2,
                        child: Container(
                          margin: EdgeInsets.all(4),
                          constraints: BoxConstraints.expand(),
                          decoration: BoxDecoration(border: Border.all()),
                          child: SingleChildScrollView(
                            child: ValueListenableBuilder<dynamic>(
                              valueListenable: result,
                              builder: (context, value, _) =>
                                  Text('${value ?? ''}'),
                            ),
                          ),
                        ),
                      ),
                      Flexible(
                        flex: 3,
                        child: GridView.count(
                          padding: EdgeInsets.all(4),
                          crossAxisCount: 2,
                          childAspectRatio: 4,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                          children: [
                            // RaisedButton(
                            //     child: Text('Tag Read'), onPressed: _tagRead),
                            RaisedButton(
                                child: Text('Ndef Write'),
                                onPressed: _ndefWrite),
                            RaisedButton(
                                child: Text('Ndef Write Lock'),
                                onPressed: _ndefWriteLock),
                          ],
                        ),
                      ),
                      CircularProgressIndicator(
                        value: null,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  void _tagRead() {
    NfcManager.instance.startTagSession(onDiscovered: (NfcTag tag) async {
      result.value = tag.data;
      print(tag.data);
      IsoDep testDep = IsoDep.fromTag(tag);
      var command1 = Uint8List.fromList([
        0x00,
        0xa4,
        0x04,
        0x00,
        hex.decode('d4100000030001').length,
        ...hex.decode('d4100000030001'),
        0x00,
      ]);
      var command2 = Uint8List.fromList([
        0x90,
        0x4c,
        0x00,
        0x00,
        0x04,
      ]);
      var command1Res = await testDep.transceive(command1);
      var command2Res = await testDep.transceive(command2);
      print("DONE!");
      // NfcManager.instance.stopSession();
    });
  }

  void _ndefWrite() {
    NfcManager.instance.startTagSession(onDiscovered: (NfcTag tag) async {
      Ndef ndef = Ndef.fromTag(tag);
      if (ndef == null) {
        result.value = 'Tag is not ndef';
        NfcManager.instance.stopSession(errorMessageIOS: result.value);
        return;
      }

      NdefMessage message = NdefMessage([
        NdefRecord.createText('Hello World!'),
        NdefRecord.createUri(Uri.parse('https://flutter.dev')),
        NdefRecord.createMime(
            'text/plain', Uint8List.fromList('Hello'.codeUnits)),
        NdefRecord.createExternal(
            'com.example', 'mytype', Uint8List.fromList('mydata'.codeUnits)),
      ]);

      try {
        await ndef.write(message);
        result.value = 'Success to "Ndef Write"';
        NfcManager.instance.stopSession();
      } catch (e) {
        result.value = e;
        NfcManager.instance
            .stopSession(errorMessageIOS: result.value.toString());
        return;
      }
    });
  }

  void _ndefWriteLock() {
    NfcManager.instance.startTagSession(onDiscovered: (NfcTag tag) async {
      Ndef ndef = Ndef.fromTag(tag);
      if (ndef == null) {
        result.value = 'Tag is not ndef';
        NfcManager.instance
            .stopSession(errorMessageIOS: result.value.toString());
        return;
      }

      try {
        await ndef.writeLock();
        result.value = 'Success to "Ndef Write Lock"';
        NfcManager.instance.stopSession();
      } catch (e) {
        result.value = e;
        NfcManager.instance
            .stopSession(errorMessageIOS: result.value.toString());
        return;
      }
    });
  }
}
