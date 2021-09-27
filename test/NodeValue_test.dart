
import 'package:intl/locale.dart';
import 'package:geiger_localstorage/src/db/data/NodeValueImpl.dart';
import 'package:test/test.dart';

class NodeValue_test {}

void main() {

  test( 'get and set node values',() {
    // testing general storage and getters with default values
    var nodeValue = NodeValueImpl('key', 'value');
    expect(nodeValue.getKey(), 'key', reason: 'key getter failed');
    expect(nodeValue.getValue(), 'value', reason: 'value getter failed');
    expect(
        nodeValue.getDescription(), null, reason: 'description getter failed');
    expect(nodeValue.getType(), null, reason: 'type getter failed');

    // testing setters
    nodeValue.setValue('newValue');
    expect(nodeValue.getValue(), 'newValue',
        reason: 'value getter failed after update');
    nodeValue.setType('newType');
    expect(nodeValue.getType(), 'newType', reason: 'type getter failed');
    nodeValue.setDescription('newDescription');
    expect(nodeValue.getDescription(), 'newDescription', reason: 'type getter failed');
  });

  test('multi language storage support', () {
    var nodeValue = NodeValueImpl('key', 'value');
    expect(nodeValue.getValue(),'value',reason:'unexpected value encountered');
    expect(nodeValue.getValue('en'),'value', reason:'unexpected value when getting en locale');
    expect(nodeValue.getValue('de'),'value', reason:'unexpected value when getting de locale');
    expect(nodeValue.getValue('en-us'),'value', reason:'unexpected value when getting en-us locale');

    // with multiple languages
    nodeValue.setValue('de-value', Locale.parse('de'));
    nodeValue.setValue('de-de-value', Locale.parse('de-de'));
    expect(nodeValue.getValue(),'value', reason:'Failed testing default getter');
    expect(nodeValue.getValue('en'),'value');
    expect(nodeValue.getValue('en-US'),'value');
    expect(nodeValue.getValue('de'),'de-value');
    expect(nodeValue.getValue('de-DE'), 'de-de-value');
    expect(nodeValue.getValue('de-ch'),'de-value');
  });

  test('node value equality',() {
    var nodeValue = NodeValueImpl('key', 'value');
    nodeValue.setValue('de-value', Locale.parse('de'));
    nodeValue.setValue('de-de-value', Locale.parse('de-de'));
    var nodeValue2 = nodeValue.deepClone();

    expect(nodeValue.getValue(),nodeValue2.getValue());
    expect(nodeValue.equals(nodeValue2),true);
    nodeValue.setValue('de-ch-value', Locale.parse('de-ch'));
    expect( nodeValue.equals(nodeValue2),false);
  });

}