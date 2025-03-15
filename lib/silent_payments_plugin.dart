// import 'dart:async';
// import 'dart:isolate';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:convert/convert.dart';

import 'silent_payments_plugin_bindings_generated.dart';

class Receiver {
  final String bScan;
  final String BSpend;
  final bool isTestnet;
  final List<int> labels;
  final int labelsLen;

  Receiver(this.bScan, this.BSpend, this.isTestnet, this.labels)
    : labelsLen = labels.length;

  Map<String, dynamic> toJson() {
    return {
      'bScan': bScan,
      'BSpend': BSpend,
      'isTestnet': isTestnet,
      'labels': labels,
      'labelsLen': labelsLen,
    };
  }

  static Receiver fromJson(Map<String, dynamic> json) {
    return Receiver(
      json['bScan'],
      json['BSpend'],
      json['isTestnet'],
      List<int>.from(json['labels']),
    );
  }
}

Pointer<OutputData> createOutputDataStruct(String outputToCheck) {
  final outputBytes = bytesFromHexString(outputToCheck);
  final Pointer<Uint8> outputToCheckPtr = calloc<Uint8>(outputBytes.length);
  final outputToCheckList = outputToCheckPtr.asTypedList(outputBytes.length);
  outputToCheckList.setAll(0, outputBytes);

  final result = calloc<OutputData>();
  result.ref.pubkey_bytes = outputToCheckPtr;
  return result;
}

void freeOutputDataStruct(Pointer<OutputData> voutDataPtr) {
  calloc.free(voutDataPtr.ref.pubkey_bytes);
  calloc.free(voutDataPtr);
}

Pointer<ReceiverData> createReceiverDataStruct(
  String bScan,
  String BSpend,
  bool isTestnet,
  List<int> labels,
  int labelsLen,
) {
  final Pointer<Uint8> bScanPtr = calloc<Uint8>(bScan.length);
  final bScanList = bScanPtr.asTypedList(bScan.length);
  bScanList.setAll(0, bytesFromHexString(bScan));

  final Pointer<Uint8> bSpendPtr = calloc<Uint8>(BSpend.length);
  final BSpendList = bSpendPtr.asTypedList(BSpend.length);
  BSpendList.setAll(0, bytesFromHexString(BSpend));

  final Pointer<Uint32> labelsPtr = calloc<Uint32>(labels.length);
  final labelsList = labelsPtr.asTypedList(labels.length);
  labelsList.setAll(0, labels);

  final result = calloc<ReceiverData>();
  result.ref
    ..b_scan_bytes = bScanPtr
    ..B_spend_bytes = bSpendPtr
    ..is_testnet = isTestnet
    ..labels = labelsPtr
    ..labels_len = labelsLen;
  return result;
}

void freeReceiverDataStruct(Pointer<ReceiverData> receiverDataPtr) {
  calloc.free(receiverDataPtr.ref.b_scan_bytes);
  calloc.free(receiverDataPtr.ref.B_spend_bytes);
  calloc.free(receiverDataPtr.ref.labels);
  calloc.free(receiverDataPtr);
}

Pointer<Int8> callApiScanOutputs(
  List<dynamic> outputsToCheck,
  String tweakDataForRecipient,
  Receiver receiver,
) {
  final pointers = calloc<Pointer<OutputData>>(outputsToCheck.length);
  for (int i = 0; i < outputsToCheck.length; i++) {
    pointers[i] = createOutputDataStruct(outputsToCheck[i][0].toString());
  }

  final pointersReceiver = createReceiverDataStruct(
    receiver.bScan,
    receiver.BSpend,
    receiver.isTestnet,
    receiver.labels,
    receiver.labelsLen,
  );

  final tweakBytes = bytesFromHexString(tweakDataForRecipient);
  final tweakPtr = calloc<Uint8>(tweakBytes.length);
  final tweakList = tweakPtr.asTypedList(tweakBytes.length);
  tweakList.setAll(0, tweakBytes);

  final paramData = calloc<ParamData>();
  paramData.ref
    ..outputs_data = pointers
    ..outputs_data_len = outputsToCheck.length
    ..tweak_bytes = tweakPtr
    ..receiver_data = pointersReceiver;

  // Call the Rust function with ParamData
  final result = _bindings.api_scan_outputs(paramData);

  // Cleanup
  for (int i = 0; i < outputsToCheck.length; i++) {
    freeOutputDataStruct(pointers[i]);
  }
  freeReceiverDataStruct(pointersReceiver);
  calloc.free(pointers);
  calloc.free(tweakPtr);
  calloc.free(paramData);

  return result;
}

typedef FreePointerFunc = Int8 Function(Pointer<Int8>);
typedef FreePointer = int Function(Pointer<Int8>);

final freePointer = _dylib.lookupFunction<FreePointerFunc, FreePointer>(
  'free_pointer',
);

Map<String, dynamic> interpretBytesVec(Pointer<Int8> pointer) {
  final jsonString = pointer.cast<Utf8>().toDartString();

  final result = jsonDecode(jsonString) as Map<String, dynamic>;

  freePointer(pointer);

  return result;
}

Map<String, dynamic> scanOutputs(
  List<dynamic> outputsToCheck,
  String tweakDataForRecipient,
  Receiver receiver,
) {
  return interpretBytesVec(
    callApiScanOutputs(outputsToCheck, tweakDataForRecipient, receiver),
  );
}

/// Converts a hexadecimal string [data] into a List of integers representing bytes.
///
/// The function removes the '0x' prefix, strips leading zeros, and decodes the
/// resulting hexadecimal string into bytes. Optionally, it pads zero if the
/// string length is odd and the [paddingZero] parameter is set to true.
///
/// Parameters:
/// - [data]: The hexadecimal string to be converted.
/// - [paddingZero]: Whether to pad a zero to the string if its length is odd
///   (default is false).
///
/// Returns:
/// - A List of integers representing bytes converted from the hexadecimal string.
///
/// Throws:
/// - [ArgumentError] if the input is not a valid hexadecimal string.
List<int> bytesFromHexString(String data, {bool paddingZero = false}) {
  try {
    // Remove '0x' prefix if present
    String hexString =
        data.toLowerCase().startsWith("0x") ? data.substring(2) : data;

    if (hexString.isEmpty) return [];

    // Pad with zero if the length is odd and paddingZero is enabled
    if (paddingZero && hexString.length.isOdd) {
      hexString = "0$hexString";
    }

    return hex.decode(hexString); // Convert hex string to byte list
  } catch (e) {
    throw ArgumentError("invalid hex bytes");
  }
}

const String _libName = 'silent_payments_plugin';

/// The dynamic library in which the symbols for [SilentPaymentsPluginBindings] can be found.
final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

/// The bindings to the native functions in [_dylib].
final SilentPaymentsPluginBindings _bindings = SilentPaymentsPluginBindings(
  _dylib,
);
