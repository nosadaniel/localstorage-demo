/// Contains all classes for accessing a local, hierarchically structured database.
///
/// The database provided in this class is suitable for partial replication.
library geiger_localstorage;

export 'src/db/data/Field.dart';
export 'src/db/data/Node.dart';
export 'src/db/data/NodeImpl.dart';
export 'src/db/data/NodeValue.dart';
export 'src/db/data/NodeValueImpl.dart';
//export 'src/db/data/SwitchableBoolean.dart';

export 'src/db/mapper/AbstractMapper.dart';
export 'src/db/mapper/AbstractSqlMapper.dart';
export 'src/db/mapper/DummyMapper.dart';
export 'src/db/mapper/SqliteMapper.dart';

export 'src/db/GenericController.dart';
export 'src/db/StorageMapper.dart';

export 'src/ChangeRegistrar.dart';
export 'src/EventType.dart';
export 'src/SearchCriteria.dart';
export 'src/StorageController.dart';
export 'src/StorageException.dart';
export 'src/StorageListener.dart';
export 'src/Visibility.dart';
