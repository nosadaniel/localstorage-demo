import 'EventType.dart';
import 'db/data/Node.dart';

/// <p>Listener interface for storage events.</p>
abstract class StorageListener {
  /// <p>Event listener for all storage node changes.</p>
  ///
  /// @param event the type of event causing the call
  /// @param oldNode the old node content
  /// @param newNode the new node content
  /// @throws StorageException if the storage backend encounters a problem
  void gotStorageChange(EventType event, Node? oldNode, Node? newNode);
}
