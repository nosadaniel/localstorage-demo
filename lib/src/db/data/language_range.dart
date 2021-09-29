library geiger_localstorage;

import 'package:intl/locale.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';
import 'package:geiger_localstorage/src/db/data/node_value_implementation.dart';

class LanguageRange {

  List<Locale> rangeList=[];

  LanguageRange(String range) {
    for(final language in range.split(RegExp(r' +'))) {
      rangeList.add(Locale.parse(language));
    }
  }

  List<Locale> _extendedRange() {
    List<Locale> l = [];
    l.addAll(rangeList);
    for(final lang in rangeList) {
      l.add(Locale.parse(lang.languageCode));
    }
    return l;
  }

  String? getLocalizedString(Map<String,String>? map) {
    if(map==null || map[NodeValueImpl.defaultLocale]==null) {
      return null;
    }

    var l = getBestLanguage(map);

    return map[l];
  }

  String getBestLanguage(Map<String,String> map) {
    var el = _extendedRange();
    for(final t in el) {
      if(map.containsKey(t.toLanguageTag())) {
        return t.toLanguageTag();
      }
    }
    return NodeValueImpl.defaultLocale.toLanguageTag();
  }

  /// Factory for creating languageRange objects.
  ///
  /// Returns an object matching the passed language priority [range].
  static LanguageRange parse(String range) {
    return LanguageRange(range);
  }
}