import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../flowder.dart';
import 'core/downloader_core.dart';

export 'core/downloader_core.dart';
export 'progress/progress.dart';
export 'utils/utils.dart';

/// Global [typedef] that returns a `int` with the current byte on download
/// and another `int` with the total of bytes of the file.
typedef FlowderProgressCallback = void Function(int count, int total);

const fileNameKeyHeader = 'x-my-file-name';

/// Class used as a Static Handler
/// you can call the following functions.
/// - Flowder.download: Returns an instance of [DownloaderCore]
/// - Flowder.initDownload -> this used at your own risk.
class Flowder {
  /// Start a new Download progress.
  /// Returns a [DownloaderCore]
  static Future<DownloaderCore> download(
    String url,
    DownloaderUtils options,
  ) async {
    try {
      final initData = await initDownload(url, options);

      return DownloaderCore(
        initData.streamSubscription,
        options,
        url,
        initData.fullPath,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Init a new Download, however this returns a [StreamSubscription]
  /// use at your own risk.
  static Future<InitData> initDownload(
    String url,
    DownloaderUtils options,
  ) async {
    var lastProgress = await options.progress.getProgress(url);
    final client = options.client ?? Dio(BaseOptions(sendTimeout: 60));
    StreamSubscription? subscription;
    try {
      isDownloading = true;

      final response = await client.get<ResponseBody>(
        url,
        options: Options(
          responseType: ResponseType.stream,
          headers: <String, dynamic>{
            HttpHeaders.rangeHeader: 'bytes=$lastProgress-',
          },
        ),
      );
      final fileName = _getFileName(response);
      var fullPath = '${options.path}/$fileName';
      var baseFile = File(fullPath);
      final file = await baseFile.create(recursive: true);
      final total = int.tryParse(
            response.headers.value(HttpHeaders.contentLengthHeader)!,
          ) ??
          0;
      final sink = await file.open(mode: FileMode.writeOnlyAppend);
      subscription = response.data!.stream.listen(
        (Uint8List data) async {
          subscription!.pause();
          await sink.writeFrom(data);
          final currentProgress = lastProgress + data.length;
          await options.progress.setProgress(url, currentProgress.toInt());
          options.progressCallback.call(currentProgress, total);
          lastProgress = currentProgress;
          subscription.resume();
        },
        onDone: () async {
          options.onDone.call();
          await sink.close();
          if (options.client != null) client.close();
        },
        onError: (dynamic error) async => subscription!.pause(),
      );

      return InitData(subscription, fullPath);
    } catch (e) {
      rethrow;
    }
  }

  static String _getFileName(Response response) {
    String fileName = 'new_file';
    try {
      if (response.headers.map.containsKey(fileNameKeyHeader)) {
        var list = response.headers.map[fileNameKeyHeader];
        if (list is List<String> && list.isNotEmpty) {
          fileName =
              (response.headers.map[fileNameKeyHeader] as List<String>)[0];
        }
      }
    } catch (_) {}

    return fileName;
  }
}

class InitData {
  final StreamSubscription streamSubscription;
  final String fullPath;

  InitData(this.streamSubscription, this.fullPath);
}
