import 'package:dio/dio.dart';

import '../flowder.dart';

/// Required for the initialization of [Flowder]
class DownloaderUtils {
  /// Notification Progress Channel Inteface
  /// Please use [ProgressImplementation] when called
  final ProgressInterface progress;

  /// Dio Client for HTTP Request
  Dio? client;

  // /// Setup a location to store the downloaded file
  // File file;

  /// Path to file without file name
  String path;

  /// should delete when cancel?
  bool deleteOnCancel;

  /// Function to be called when the download has finished.
  final Function onDone;

  /// Function with the current values of the download
  /// ```dart
  /// Function(int bytes, int total) => print('current byte: $bytes and total of bytes: $total');
  /// ```
  final FlowderProgressCallback progressCallback;

  DownloaderUtils({
    required this.progress,
    this.client,
    required this.path,
    this.deleteOnCancel = false,
    required this.onDone,
    required this.progressCallback,
  });
}
