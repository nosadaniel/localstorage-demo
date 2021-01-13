package ch.fhnw.geiger.localstorage.db.data;

import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.MissingResourceException;
import java.util.Vector;
import java.util.stream.Collector;
import java.util.stream.Collectors;

/**
 * <p>This abstract class defines the common attributes for all NodeValueObjects.</p>
 *
 * @author Sacha
 * @version 0.1
 */
public class NodeValueImpl implements NodeValue {

  private static final Locale DEFAULT_LOCALE = Locale.ENGLISH;

  /**
   * They key is used to identify the NodeValueObject inside a StorageNode,
   * therefore, the key is unique within one StorageNode.
   */
  private String key;

  private Map<Locale, String> value = new HashMap<>();

  /**
   * <p>The type of the value.</p>>
   */
  private String type;

  /**
   * Description of this value, can be used for translation.
   */
  private Map<Locale, String> description = new HashMap<>();

  /**
   * Defines the epoch when this value was last modified.
   */
  private long lastModified;

  /**
   * <p>Default constructor to create a new key/value pair.</p>
   *
   * <p>Type and description of the key/value pair are set to null. This
   * Constructor should only be used for private values (visibility RED).</p>
   *
   * @param key   the name of the key
   * @param value the value of the key
   */
  public NodeValueImpl(String key, String value) {
    this(key, value, null, null, 0);
  }

  /**
   * <p>A fully fledged constructor for creating key/value pairs suitable for sharing.</p>
   *
   * @param key          the name of the key/value pair
   * @param value        the value to be set
   * @param type         a searchable type field
   * @param description  the description to be shown when asking for consent of sharing
   * @param lastModified the last modified date to be set
   */
  public NodeValueImpl(String key, String value, String type, String description,
                       long lastModified) {
    if (key == null || value == null) {
      throw new NullPointerException();
    }
    this.key = key;
    setLocalizedString(this.value, value, DEFAULT_LOCALE);
    this.type = type;
    if (description != null) {
      setLocalizedString(this.description, description, DEFAULT_LOCALE);
    }
    this.lastModified = lastModified;
  }

  @Override
  public String getKey() {
    return key;
  }

  private void setKey(String key) {
    this.key = key;
    updateLastmodified();
  }

  @Override
  public String getValue() {
    return getValue(DEFAULT_LOCALE.toLanguageTag());
  }

  @Override
  public String getValue(String languageRange) {
    return getLocalizedString(this.value, languageRange);
  }

  @Override
  public Map<Locale, String> getAllValueTranslations() {
    return new HashMap<>(value);
  }

  @Override
  public void setValue(String value, Locale locale) throws MissingResourceException {
    setLocalizedString(this.value, value, locale);
    updateLastmodified();
  }

  @Override
  public void setValue(String value) {
    setValue(value, DEFAULT_LOCALE);
  }

  @Override
  public String getType() {
    return type;
  }

  @Override
  public String setType(String type) {
    String ret = this.type;
    this.type = type;
    updateLastmodified();
    return ret;
  }

  @Override
  public String getDescription() {
    return getDescription(DEFAULT_LOCALE.toLanguageTag());
  }

  @Override
  public String getDescription(String languageRange) {
    return getLocalizedString(description, languageRange);
  }

  @Override
  public Map<Locale, String> getAllDescriptionTranslations() {
    return new HashMap<>(description);
  }

  private static Locale lookupLocale(Map<Locale, String> map, String languageRange) {
    // Get Language Range
    List<Locale.LanguageRange> lr = Locale.LanguageRange.parse(languageRange);

    // extending range list with locale only
    List<Locale.LanguageRange> al = new Vector<>();
    for (Locale.LanguageRange r : lr) {
      String language = (Locale.forLanguageTag(r.getRange())).getLanguage();
      Locale.LanguageRange lrOnlyLanguage = new Locale.LanguageRange(language, r.getWeight());
      if (!lr.contains(lrOnlyLanguage)) {
        al.add(lrOnlyLanguage);
      }
    }
    lr.addAll(al);

    // create a mapping map
    Map<Locale, Locale> localeMapping = new HashMap<>();
    for (Locale l : map.keySet()) {
      localeMapping.put(l, l);
      Locale ll = new Locale(l.getLanguage());
      if (!localeMapping.containsKey(ll)) {
        localeMapping.put(ll, l);
      }
    }

    List<Locale> matchingLocales = Locale.filter(lr, localeMapping.keySet());
    if (matchingLocales.size() > 0) {
      return localeMapping.get(matchingLocales.get(0));
    } else {
      return DEFAULT_LOCALE;
    }
  }

  private static String getLocalizedString(Map<Locale, String> map, String languageRange) {
    return map.get(lookupLocale(map, languageRange));
  }

  private static void setLocalizedString(Map<Locale, String> map, String value, Locale locale)
      throws MissingResourceException {
    if (getLocalizedString(map, DEFAULT_LOCALE.toLanguageTag()) == null
        && locale != DEFAULT_LOCALE) {
      throw new MissingResourceException("undefined string for locale " + DEFAULT_LOCALE, "Locale",
          locale.toLanguageTag());
    }
    map.put(locale, value);
  }

  @Override
  public String setDescription(String value, Locale locale) {
    if (description == null) {
      throw new NullPointerException("description may not be null");
    }
    String ret = getLocalizedString(this.description, locale.toLanguageTag());
    setLocalizedString(this.description, value, locale);
    updateLastmodified();
    return ret;
  }

  @Override
  public String setDescription(String description) {
    return setDescription(description, DEFAULT_LOCALE);
  }

  @Override
  public long getLastModified() {
    return lastModified;
  }

  @Override
  public void update(NodeValue node) {
    NodeValueImpl n2 = (NodeValueImpl) (node);
    this.key = n2.getKey();
    this.value.clear();
    for (Map.Entry<Locale, String> e : n2.value.entrySet()) {
      this.value.put(e.getKey(), e.getValue());
    }
    this.type = n2.getType();
    this.description.clear();
    for (Map.Entry<Locale, String> e : n2.description.entrySet()) {
      this.description.put(e.getKey(), e.getValue());
    }
    updateLastmodified();
  }

  private void updateLastmodified() {
    this.lastModified = new Date().getTime();
  }

  @Override
  public NodeValue deepClone() {
    NodeValue ret = new NodeValueImpl(getKey(), getValue());
    ret.update(this);
    return ret;
  }

  @Override
  public String toString() {
    return "(" + type + ")" + key + "=" + value;
  }

  @Override
  public boolean equals(Object o) {
    if (!(o instanceof NodeValueImpl)) {
      return false;
    }
    NodeValueImpl nv = (NodeValueImpl) o;

    if (!getKey().equals(nv.getKey())) {
      return false;
    }
    if (getValue() != null && !getValue().equals(nv.getValue())) {
      return false;
    }
    synchronized (value) {
      if (value.size() != nv.value.size()) {
        return false;
      }
      for (Map.Entry<Locale, String> e : value.entrySet()) {
        if (!e.getValue().equals(nv.value.get(e.getKey()))) {
          return false;
        }
      }
    }
    if (getType() != null && !getType().equals(nv.getType())) {
      return false;
    }
    if (getDescription() != null && !getDescription().equals(nv.getDescription())) {
      return false;
    }
    synchronized (description) {
      if (description.size() != nv.description.size()) {
        return false;
      }
      for (Map.Entry<Locale, String> e : description.entrySet()) {
        if (!e.getValue().equals(nv.description.get(e.getKey()))) {
          return false;
        }
      }
    }
    return true;
  }
}
