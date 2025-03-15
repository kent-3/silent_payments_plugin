import 'dart:async';
import 'package:flutter/material.dart';

import 'package:silent_payments_plugin/silent_payments_plugin.dart'
    as silent_payments_plugin;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // late Future<int> sumAsyncResult;
  late Map<String, dynamic> result;

  @override
  void initState() {
    super.initState();

    result = silent_payments_plugin.interpretBytesVec(
      silent_payments_plugin.callApiScanOutputs(
        [
          ["545ff3ecec27fbf43790d639a7a71ea0ff72a3dcce11aea17aeb63eca4188379"],
        ],
        "03a952f2ec5ea0a8bd7d5022c499ab7947058e3dd471434775b08f10d5d4fd1ab9",
        silent_payments_plugin.Receiver(
          "f402c47811fa7ff8d7f879de7be8d2f1b7cc411c0542535731fb43095b90a3b6",
          "022fdc3f6726e23bfce017ab731c09e13d97cde4613bba309e5f2c507798764bca",
          false,
          [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], // TODO: figure out what these do
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 25);
    const spacerSmall = SizedBox(height: 10);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Native Packages')),
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                const Text(
                  'This calls a native function through FFI that is shipped as source in the package. '
                  'The native code is built as part of the Flutter Runner build.',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
                spacerSmall,
                Text('$result', style: textStyle, textAlign: TextAlign.center),
                spacerSmall,
                // FutureBuilder<int>(
                //   future: sumAsyncResult,
                //   builder: (BuildContext context, AsyncSnapshot<int> value) {
                //     final displayValue =
                //         (value.hasData) ? value.data : 'loading';
                //     return Text(
                //       'await sumAsync(3, 4) = $displayValue',
                //       style: textStyle,
                //       textAlign: TextAlign.center,
                //     );
                //   },
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
