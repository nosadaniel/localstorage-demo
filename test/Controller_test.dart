import 'package:localstorage/src/StorageController.dart';
import 'package:localstorage/src/StorageException.dart';
import 'package:localstorage/src/Visibility.dart';
import 'package:localstorage/src/db/GenericController.dart';
import 'package:localstorage/src/db/data/NodeImpl.dart';
import 'package:localstorage/src/db/data/NodeValueImpl.dart';
import 'package:localstorage/src/db/mapper/DummyMapper.dart';
import 'package:test/test.dart';

class Controller_test {}

void updateTests(final StorageController controller) {
  group('controller update tests', () {
    test('Owner Update On Node', () {
      print('## Testing controller in UNKNOWN');
      controller.add(NodeImpl('testNodeOwner1', ''));
      var node = controller.get(':testNodeOwner1');
      expect(node.getOwner(), 'testOwner');
    });

    test('Storage Node Create', () {
      controller.add(NodeImpl(':StorageNodeCreate1'));
      // fetch stored node
      var storedNode = controller.get(':StorageNodeCreate1');

      // check results
      expect(storedNode.getOwner(), 'testOwner');
      expect(storedNode.getName(), 'StorageNodeCreate1');
      expect(storedNode.getPath(), ':StorageNodeCreate1');
      expect(storedNode.getVisibility(), Visibility.RED);
    });

    test('Test Storage Node Add', () {
      controller.add(NodeImpl('parent1', ''));
      controller.add(NodeImpl('name2', ':parent1'));

      // get the record
      var storedNode = controller.get(':parent1:name2');

      // check results
      expect(storedNode.getOwner(), 'testOwner');
      expect(storedNode.getName(), 'name2');
      expect(storedNode.getPath(), ':parent1:name2');
      expect(storedNode.getVisibility(), Visibility.RED);
    });

    // depends on correct functionality of the StorageController.create() function
    test('test storage node update', () {
      // create original node
      controller.add(NodeImpl(':nodeUpdateTest'));

      // updated Node with different visibility children
      var node = NodeImpl('testNode1', ':nodeUpdateTest', Visibility.GREEN);
      controller.add(node);
      expect(node.getOwner(), 'testOwner');

      var sn = NodeImpl('testChild1', ':nodeUpdateTest:testNode1');
      controller.add(sn);
      node.setVisibility(Visibility.RED);
      node.addChild(sn);

      // update with node from above
      controller.update(node);

      // get the record
      var storedNode = controller.get(':nodeUpdateTest:testNode1');

      // check results
      expect(storedNode.getOwner(), 'testOwner');
      expect(storedNode.getName(), 'testNode1');
      expect(storedNode.getPath(), ':nodeUpdateTest:testNode1');
      expect(storedNode.getChildNodesCsv(), 'testChild1');
      expect(storedNode.getVisibility(), Visibility.RED);
    });

    test('add node with missing parent', () {
      expect(() => controller.add(NodeImpl('testNode1', ':nodeUpdateTest2')),
          throwsA(TypeMatcher<StorageException>()));
    });

    test('create new node', () {
      var n = [NodeImpl(':nodeCreateTest'), NodeImpl('testNode1', ':nodeCreateTest')];

      for (final tn in n) {
        print(
            '## creating new node ${tn.getPath()} (parent of ${tn.getParentPath()})');
        controller.add(tn);
      }

      // add a value
      print('## adding value');
      controller.addValue(
          ':nodeCreateTest:testNode1', NodeValueImpl('key1', 'valueFirst'));

      // update value
      print('## updating value');
      var value2 = NodeValueImpl('key1', 'valueSecond');
      controller.updateValue(':nodeCreateTest:testNode1', value2);

      // get the record
      print('## testing updated value');
      var n2 = controller.get(':nodeCreateTest:testNode1');
      expect(
          (n2.getValue(value2.getKey()) ??
              NodeValueImpl(value2.getKey(), 'INVALID'))
              .getValue(),
          value2.getValue());

      print(
          '## testing removal of node with child nodes (${n[n.length - 1].getPath()})');

      expect(() => controller.delete(n[0].getPath()),
          throwsA(TypeMatcher<StorageException>()));

      for (final tn in List.from(n.reversed)) {
        print(
            '## removing node ${tn.getPath()} (parent of ${tn.getParentPath()})');
        controller.delete(tn.getPath());
      }
    });

    test('remove node from storage', () {
      controller.add(NodeImpl('removalNode1', ''));
      var node = NodeImpl('name1', ':removalNode1');
      var nv = NodeValueImpl('key', 'value');
      node.addValue(nv);
      controller.add(node);
      var removed = controller.delete(':parent1:name1');

      // check nodes
      expect(node, removed);
      expect(() => controller.get(removed.getPath()),
          throwsA(TypeMatcher<StorageException>()));

      // check values
      expect(removed.getValue('key'), nv);
      expect(() => controller.getValue(removed.getPath(), 'key'),
          throwsA(TypeMatcher<StorageException>()));
    });

    test('Remove node with children', () {
      controller.add(NodeImpl('parent1', ''));
      var node = NodeImpl('name1', ':parent1');
      // add child
      var childNode = NodeImpl('child1', ':parent1:name1');
      node.addChild(childNode);
      controller.add(node);
      controller.add(childNode);

      expect(() => controller.delete(':parent1:name1'),
          throwsA(TypeMatcher<StorageException>()));

      // check if node still exists
      expect(controller.get(':parent1:name1'), node);
    });

    group('rename tests',() {
      test('rename node', () {
        var nodes = [
          NodeImpl('renameTests'),
          NodeImpl('name1', ':renameTests'),
          NodeImpl('name11', ':renameTests:name1'),
          NodeImpl('name2', ':renameTests'),
          NodeImpl('name21', ':renameTests:name2'),
          NodeImpl('name3', ':renameTests')
        ];
        for (var n in nodes) {
          controller.add(n);
        }

        // rename by name
        controller.rename(':renameTests:name1', 'name1a');

        // rename by path
        controller.rename(':renameTests:name2', ':renameTests:name2a');

        // check old nodes
        expect(() => controller.get(':renameTests:name1'),
            throwsA(TypeMatcher<StorageException>()));
        expect(() => controller.get(':renameTests:name2'),
            throwsA(TypeMatcher<StorageException>()));

        // check new nodes
        for (final name in [':renameTests:name1a', ':renameTests:name2a']) {
          expect(controller.get(name).getPath(), name,
              reason: 'renaming node seems unsuccessful (new node missing)');
        }
        // check name
        expect(controller.get(':renameTests:name1a').getName(), 'name1a',
            reason: 'renaming node seems unsuccessful (new node name wrong)');
        expect(controller.get(':renameTests:name2a').getName(), 'name2a',
            reason: 'renaming node seems unsuccessful (new node name wrong)');

        // check path
        expect(
            controller.get(':renameTests:name1a').getPath(), ':renameTests:name1a',
            reason: 'renaming node seems unsuccessful (new node path wrong)');

        expect(
            controller.get(':renameTests:name2a').getPath(), ':renameTests:name2a',
            reason: 'renaming node seems unsuccessful (new node path wrong)');

        // check child nodes
        for (final name in [
          ':renameTests:name1a:name11',
          ':renameTests:name2a:name21'
        ]) {
          expect(controller.get(name).getPath(), name,
              reason: 'renaming node seems unsuccessful (sub-node missing)');
        }
        // check child node name
        expect('name11', controller.get(':renameTests:name1a:name11').getName(),
            reason: 'renaming node seems unsuccessful (sub-node name wrong)');
        expect('name21', controller.get(':renameTests:name2a:name21').getName(),
            reason: 'renaming node seems unsuccessful (sub-node name wrong)');

        // check child node path
        expect(controller.get(':renameTests:name1a:name11').getPath(),
            ':renameTests:name1a:name11',
            reason: 'renaming node seems unsuccessful (sub-node path wrong)');
        expect(controller.get(':renameTests:name2a:name21').getPath(),
            ':renameTests:name2a:name21',
            reason: 'renaming node seems unsuccessful (sub-node path wrong)');

        // test rename of non existing nodes
        expect(() => controller.rename(':renameTests:name4', ':renameTests:name4a'),
            throwsA(TypeMatcher<StorageException>()));
        expect(() => controller.rename(':renameTests:name4', 'name4a'),
            throwsA(TypeMatcher<StorageException>()));

        // test rename to an existing node
        expect(() => controller.rename(':renameTests:name2a', ':renameTests:name3'),
            throwsA(TypeMatcher<StorageException>()));
        expect(() => controller.rename(':renameTests:name2a', 'name3'),
            throwsA(TypeMatcher<StorageException>()));
      });

      test(' Rename node with values', () {
        var nodes = [
          NodeImpl('renameTests'),
          NodeImpl('name1', ':renameTests'),
          NodeImpl('name2', ':renameTests'),
          NodeImpl('name21', ':renameTests:name2'),
          NodeImpl('name3', ':renameTests')
        ];

        var nv = NodeValueImpl('key', 'value');
        var nv1 = NodeValueImpl('key1', 'value1');
        var nv2 = NodeValueImpl('key2', 'value2');
        var nv21 = NodeValueImpl('key21', 'value21');

        nodes[0].addValue(nv);
        nodes[1].addValue(nv1);
        nodes[2].addValue(nv2);
        nodes[3].addValue(nv21);

        for (final n in nodes) {
          controller.add(n);
        }
        controller.rename(':renameTests:name2', ':renameTests:name2a');

        // check old node
        expect(() => controller.get(':renameTests:name2'),
            throwsA(TypeMatcher<StorageException>()));

        expect(
            controller.get(':renameTests:name2a').getPath(), ':renameTests:name2a',
            reason: 'renaming node seems unsuccessful (new node missing)');
        expect(controller.get(':renameTests:name2a').getName(), 'name2a',
            reason: 'renaming node seems unsuccessful (new node name wrong)');
        expect(
            controller.get(':renameTests:name2a').getPath(), ':renameTests:name2a',
            reason: 'renaming node seems unsuccessful (new node path wrong)');
        expect(controller.get(':renameTests:name2a:name21'), isNotNull,
            reason: 'renaming node seems unsuccessful (sub-node missing)');
        expect(controller.get(':renameTests:name2a:name21').getName(), 'name21',
            reason: 'renaming node seems unsuccessful (sub-node missing)');
        expect(controller.get(':renameTests:name2a:name21').getPath(),
            ':renameTests:name2a:name21',
            reason: 'renaming node seems unsuccessful (sub-node path wrong)');

        // check values
        expect(controller.get(':renameTests').getValue('key'), nv,
            reason: 'value lost on parent');
        expect(controller.get(':renameTests:name1').getValue('key1'), nv1,
            reason: 'value lost on sibling');
        expect(controller.get(':renameTests:name2a').getValue('key2'), nv2,
            reason: 'value lost moved node');
        expect(controller.get(':renameTests:name2a:name21').getValue('key21'), nv21,
            reason: 'value lost on sub-node');

        // check old values
        expect(() => controller.getValue(':renameTests:name2', 'key2'),
            throwsA(TypeMatcher<NullThrownError>()));
        expect(() => controller.getValue(':renameTests:name2:name21', 'key2'),
            throwsA(TypeMatcher<NullThrownError>()));
      });

    });

  });
}

void main() {
  final StorageController controller =
      GenericController('testOwner', DummyMapper());

  updateTests(controller);


  test('Storage node search', () {
    // TODO
  });

  test('Storage change listener', () {
    // TODO
  });

  test('notify change listener', () {
    // TODO
  });

}
