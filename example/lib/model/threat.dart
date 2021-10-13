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
  final List<Threat> _threats = <Threat>[];
  Node? threatNode;

  //pass threatMap to threats List
  void _addThreatMap(Map<String, String> threatMap) {
    threatMap.forEach((key, value) {
      _threats.add(Threat(threatId: key, name: value));
    });
  }

  //populate :Global:threats with values according threats
  void _populateGlobalThreatsNode(
      StorageController? controller, Map<String, String> threatMap) {
    try {
      threatNode = controller!.get(':Global:threats');
    } on StorageException {
      threatNode = NodeImpl("threats", ":Global");
      //create :Global:threats
      controller!.add(threatNode!);
      //pass threatMap to threats List
      _addThreatMap(threatMap);
      // loop through _threats
      for (Threat threat in _threats) {
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
  List<Threat> getThreats(
      StorageController? controller, Map<String, String> threatMap) {
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
      //create and populate database if :Global:threats is not create
      _populateGlobalThreatsNode(controller, threatMap);
    }
    return <Threat>[];
    //for displaying changes
  }
}
