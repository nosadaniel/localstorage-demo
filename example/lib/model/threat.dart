import 'dart:developer';

import 'package:geiger_localstorage/geiger_localstorage.dart';

class Threat {
  String threatId;
  String name;

  Threat({required this.threatId, required this.name});

  @override
  String toString() {
    return "Threat:{threatId: $threatId, name: $name }";
  }
}

class CreateNodeAndNodeValue {
  List<Threat> threats = <Threat>[];
  Node? threatNode;

  //pass threatMap to threats List
  void addThreatMap(Map<String, String> threatMap) {
    threatMap.forEach((key, value) {
      threats.add(Threat(threatId: key, name: value));
    });
  }

  //populate :Global:threats with values according threats
  void populateGlobalThreatsNode(StorageController? controller) {
    try {
      threatNode = controller!.get(':Global:threats');
    } on StorageException {
      threatNode = NodeImpl("threats", ":Global");
      //create :Global:threats
      controller!.add(threatNode!);
      for (Threat threat in threats) {
        Node threatChildNode = NodeImpl(":Global:threats:${threat.threatId}");
        //create :Global:threats:$threatId
        threatNode!.addChild(threatChildNode);
        //create a Nodvalue
        NodeValue threatNodeValueName = NodeValueImpl("name", threat.name);
        // add NodeValue to threatChildNode
        threatChildNode.addValue(threatNodeValueName);
        //update threatNode
        controller.update(threatNode!);
      }
    }
  }

  //return list of threats
  List<Threat> getThreats(StorageController? controller) {
    List<Threat> t = [];
    try {
      threatNode = controller!.get(":Global:threats");
      //log(threatNode!.getChildren().toString());
      threatNode!.getChildren().forEach((key, value) {
        return t.add(Threat(
            threatId: key,
            name: value.getValue("name")!.getValue("en").toString()));
      });
      return t;
    } on StorageException {
      log(":Global:threats can not be find in the database");
    }
    return <Threat>[];
    //for displaying changes
  }
}
