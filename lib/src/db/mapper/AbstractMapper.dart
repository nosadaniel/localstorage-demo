import 'package:localstorage/src/StorageException.dart';
import 'package:localstorage/src/db/data/Node.dart';

import '../GenericController.dart';
import '../StorageMapper.dart';

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
    if (!RegExp('(' + GenericController.PATH_DELIMITER + '[a-zA-Z0-9\\-]+)*')
        .hasMatch(path)) {
      throw StorageException(('illegal path detected in \"' + path) + '\"');
    }
  }
}
