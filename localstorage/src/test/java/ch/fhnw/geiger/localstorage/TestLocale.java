package ch.fhnw.geiger.localstorage;

import ch.fhnw.geiger.totalcross.Locale;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import org.junit.Assert;
import org.junit.Test;

public class TestLocale {

  @Test
  public void localeTest() {
    Locale l = Locale.ENGLISH;
    Assert.assertEquals("Checking default language tag", "en", l.getLanguage());
    Assert.assertEquals("Checking default language tag simplification (without country)", "en", new Locale("en", "UK").getLanguage());
    Assert.assertEquals("Checking casing", "en-UK", new Locale("En", "uK").toLanguageTag());
    Assert.assertNotEquals("Checking default language tag simplification (without country)", Locale.ENGLISH, new Locale("en", "uk"));
  }

  @Test
  public void localeFilterTest() {
    List<Locale> l = new ArrayList<>();
    l.add(Locale.ENGLISH);
    l.add(new Locale("fr", "ch"));

    Locale.LanguageRange[] lr = new Locale.LanguageRange[]{
        new Locale.LanguageRange("de", 1),
        new Locale.LanguageRange("en", 0.5)
    };

    List<Locale> res = Locale.filter(Arrays.asList(lr), l);
    Assert.assertEquals("Number of locale", 1, res.size());
    Assert.assertEquals("Expected locale", Locale.ENGLISH, res.get(0));

    lr = new Locale.LanguageRange[]{
        new Locale.LanguageRange("de", 1),
        new Locale.LanguageRange("fr", 0.5)
    };
    res = Locale.filter(Arrays.asList(lr), l);
    Assert.assertEquals("Number of locale", 1, res.size());
    Assert.assertEquals("Expected locale", new Locale("fr","ch"), res.get(0));
  }

}
