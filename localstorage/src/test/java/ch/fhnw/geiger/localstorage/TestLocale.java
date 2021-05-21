package ch.fhnw.geiger.localstorage;

import ch.fhnw.geiger.totalcross.Locale;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
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
  public void localeComparisonTest() {
    Locale l1 = Locale.ENGLISH;
    Locale l2 = new Locale("en");
    Locale l3 = new Locale("en", "gb");
    Locale l4 = new Locale("de");

    // compare locales
    Assert.assertEquals(l1, l2);
    Assert.assertNotEquals(l1, l3);
    Assert.assertNotEquals(l2, l3);
    Assert.assertNotEquals(l1, l4);
    Assert.assertNotEquals(l2, l4);
    Assert.assertNotEquals(l3, l4);

    // compare sequence of locales
    Assert.assertTrue("equal objects are not equal", l1.compareTo(l1) == 0);
    Assert.assertTrue("equal objects are not equal", l2.compareTo(l2) == 0);
    Assert.assertTrue("equal objects are not equal", l1.compareTo(l2) == 0);
    Assert.assertTrue("equal objects are not equal", l1.compareTo(l3) < 0);
    Assert.assertTrue("equal objects are not equal", l1.compareTo(l4) > 0);
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
    Assert.assertEquals("Expected locale", new Locale("fr", "ch"), res.get(0));
  }

  @Test
  public void localeMapTest() {
    Map<Locale, String> m = new HashMap<>();
    m.put(Locale.ENGLISH, "en1");
    m.put(new Locale("en"), "en2");
    m.put(new Locale("en", "gb"), "en3");
    Assert.assertEquals("en2", m.get(Locale.ENGLISH));
    Assert.assertEquals("en3", m.get(new Locale("en","gb")));
  }

}
