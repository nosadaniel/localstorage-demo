/// Contains all classes for accessing a local, hierarchically structured database.
///
/// The database provided in this class is suitable for partial replication.
library geiger_localstorage;

export 'src/db/data/field.dart';
export 'src/db/data/node.dart';
export 'src/db/data/node_implementation.dart';
export 'src/db/data/node_value.dart';
export 'src/db/data/node_value_implementation.dart';
//export 'src/db/data/switchable_boolean.dart';

export 'src/db/mapper/abstract_mapper.dart';
export 'src/db/mapper/abstract_sql_mapper.dart';
export 'src/db/mapper/dummy_mapper.dart';
export 'src/db/mapper/sqlite_mapper.dart';

export 'src/db/generic_controller.dart';
export 'src/db/storage_mapper.dart';

export 'src/change_registrar.dart';
export 'src/event_type.dart';
export 'src/search_criteria.dart';
export 'src/storage_controller.dart';
export 'src/storage_exception.dart';
export 'src/storage_listener.dart';
export 'src/visibility.dart';
