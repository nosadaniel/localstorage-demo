library geiger_localstorage;

import 'dart:async';

import 'package:geiger_localstorage/src/serialization/serializer_helper.dart';
import 'package:test/test.dart';

class SerializerHelperTest {}

void main() {
  test('testing serialization/deserialization of string', () {
    for(String s in ['string','testMessage öäü^'] ) {
      StreamController<List<int>> sc= StreamController();
      Sink<List<int>> sink = sc.sink;
      SerializerHelper.writeString(sink,s);
      var s2=SerializerHelper.readString(sc.stream);
      expect(s2,s,reason: 'deserialization failed for string "$s"');
    }
  });
  test('testing serialization/deserialization of int', () {
    for(int s in [0,1,-1,1<<63] ) {
      StreamController<List<int>> sc= StreamController<List<int>>();
      Sink<List<int>> sink = sc.sink;
      SerializerHelper.writeInt(sink,s);
      var s2=SerializerHelper.readInt(sc.stream);
      expect(s2,s,reason: 'deserialization of int failed for $s');
    }
  });
}