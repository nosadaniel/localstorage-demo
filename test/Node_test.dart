import 'package:geiger_localstorage/src/Visibility.dart';
import 'package:geiger_localstorage/src/db/data/NodeImpl.dart';
import 'package:test/test.dart';

class Node_test {}

void main() {
  test('node defaults', () {
    var node = NodeImpl('name', 'path');
    expect(node.getOwner(), null, reason: 'test predefined owner');
    expect(node.getVisibility(), Visibility.RED,
        reason: 'test predefined owner');
  });

  test('node equality equals()', () {
    var node = NodeImpl('name', 'path');
    var node2 = node.deepClone();
    expect(node.equals(node2), true, reason: 'equality not given');
  });

  test('ordinals mismatch', () {
    var node = NodeImpl('name', 'path');
    var node2 = node.deepClone();
    node2.setOwner('newOwner');
    expect(node.equals(node2), false);
  });

  test('equality for child nodes', () {
    var node = NodeImpl('name', 'path');
    var node2 = node.deepClone();
    node2.addChild(NodeImpl('name2', 'path:name'));
    expect(node.equals(node2), false);
  });
}
