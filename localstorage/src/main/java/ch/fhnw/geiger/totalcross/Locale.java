package ch.fhnw.geiger.totalcross;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Set;
import java.util.TreeSet;

public class Locale implements Comparable<Locale> {

  public static final Locale ENGLISH = new Locale("en");
  public static final Locale GERMAN = new Locale("de");
  public static final Locale GERMANY = new Locale("de", "DE");

  public static class LanguageRange implements Comparable {

    private double weight;
    private Locale range;

    public LanguageRange(String language, double weight) {
      range = new Locale(language);
      this.weight = Math.min(1, Math.max(0, weight));
    }

    public double getWeight() {
      return weight;
    }

    public String getRange() {
      return range.toLanguageTag();
    }

    public static List<LanguageRange> parse(String expression) {
      Set<LanguageRange> ret = new TreeSet<>();
      for (String chunk : expression.split(";")) {
        chunk = chunk.trim();
        String[] chunkElements = chunk.split(" +");
        if (chunkElements.length == 2) {
          ret.add(new LanguageRange(chunkElements[0], Double.valueOf(chunkElements[1])));
        } else {
          ret.add(new LanguageRange(chunkElements[0], 1.0));
        }
      }
      List<LanguageRange> ret2 = new ArrayList<>();
      ret2.addAll(ret);
      return ret2;
    }

    @Override
    public int compareTo(Object o) {
      if (!(o instanceof LanguageRange)) {
        return 0;
      }
      double w1 = getWeight();
      double w2 = ((LanguageRange) (o)).getWeight();
      if (w1 == w2) {
        return 0;
      } else if (w1 >= w2) {
        return -1;
      } else {
        return 1;
      }
    }
  }

  String language;
  String country = null;

  public Locale(String language) {
    String[] chunks = language.split("\\-");
    if (chunks.length == 1) {
      this.language = chunks[0].toLowerCase();
    } else if (chunks.length == 2) {
      this.language = chunks[0].toLowerCase();
      this.country = chunks[1].toUpperCase();
    } else {
      throw new IllegalArgumentException("unable to parse language string \"" + language + "\"");
    }
  }

  public Locale(String language, String country) {
    this.language = language.toLowerCase();
    this.country = country.toUpperCase();
  }

  public String toLanguageTag() {
    return language + (country != null ? "-" + country : "");
  }

  public String getLanguage() {
    return language;
  }

  public static Locale forLanguageTag(String language) {
    return new Locale(language);
  }

  public String toString() {
    return toLanguageTag();
  }

  public static List<Locale> filter(List<Locale.LanguageRange> priorityList, Collection<Locale> locales) {
    ArrayList<Locale> ret = new ArrayList<>();
    for (LanguageRange r : priorityList) {
      // look for exact match
      for (Locale l : locales) {
        if (l.toLanguageTag().equals(new Locale(r.getRange()).toLanguageTag()) && !ret.contains(l)) {
          ret.add(l);
        }
      }
    }
    for (LanguageRange r : priorityList) {
      // look for language match only (if applicable)
      for (Locale l : locales) {
        if (l.toLanguageTag().equals(new Locale(r.getRange()).getLanguage()) && !ret.contains(l)) {
          ret.add(l);
        }
      }
    }
    for (LanguageRange r : priorityList) {
      // look for any applicable language match
      for (Locale l : locales) {
        if (l.getLanguage().equals(new Locale(r.getRange()).getLanguage()) && !ret.contains(l)) {
          ret.add(l);
        }
      }
    }
    return ret;
  }

  public boolean equals(Object obj) {
    if (!(obj instanceof Locale)) {
      return false;
    }
    return toLanguageTag().equals(((Locale) (obj)).toLanguageTag());
  }

  @Override
  public int compareTo(Locale o) {
    return toLanguageTag().compareTo(o.toLanguageTag());
  }

  @Override
  public int hashCode() {
    return toLanguageTag().hashCode();
  }

}
