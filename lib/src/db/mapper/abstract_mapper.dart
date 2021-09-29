library geiger_localstorage;

import 'package:geiger_localstorage/src/storage_exception.dart';

import '../generic_controller.dart';
import '../storage_mapper.dart';

/// <p>An abstract mapper providing general checks.</p>
abstract class AbstractMapper with StorageMapper {
  void getSanity(String? path) {
    if (path == null) {
      throw NullThrownError();
    }
  }

  void checkPath(String path) {
    if (':' == path) {
      return;
    }
    if (!RegExp('(' + GenericController.pathDelimiter + '[a-zA-Z0-9\\-]+)*')
        .hasMatch(path)) {
      throw StorageException(('illegal path detected in "' + path) + '"');
    }
  }
}
