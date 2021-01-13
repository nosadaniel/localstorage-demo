package ch.fhnw.geiger.localstorage;

import java.io.IOException;
import java.net.URL;
import java.util.Enumeration;
import java.util.jar.Attributes;
import java.util.jar.Manifest;
import picocli.CommandLine.IVersionProvider;

/**
 * <p>Implements the commandline interface.</p>
 */
@picocli.CommandLine.Command(
    name = "localapi",
    versionProvider = ch.fhnw.geiger.localstorage.CommandLine.VersionProvider.class
)
public class CommandLine implements Runnable {

  @picocli.CommandLine.Option(names = {"-V", "--version"}, versionHelp = true,
      description = "print version information and exit")
  boolean versionRequested;

  @picocli.CommandLine.Option(
      names = {"-h", "--help"},
      usageHelp = true,
      description = "display this help message"
  )
  boolean usageHelpRequested;

  static class VersionProvider implements IVersionProvider {
    public String[] getVersion() throws Exception {
      Enumeration<URL> resources = CommandLine.class.getClassLoader()
          .getResources("META-INF/MANIFEST.MF");
      while (resources.hasMoreElements()) {
        URL url = resources.nextElement();
        try {
          Manifest manifest = new Manifest(url.openStream());
          if (isApplicableManifest(manifest)) {
            Attributes attr = manifest.getMainAttributes();
            return new String[]{get(attr, "Implementation-Title") + " version \""
                + get(attr, "Implementation-Version") + "\""};
          }
        } catch (IOException ex) {
          return new String[]{"Unable to read from " + url + ": " + ex};
        }
      }
      System.err.println("unable to provide version information");
      return new String[0];
    }

    boolean isApplicableManifest(Manifest manifest) {
      Attributes attributes = manifest.getMainAttributes();
      return "picocli".equals(get(attributes, "Implementation-Title"));
    }

    private static Object get(Attributes attributes, String key) {
      return attributes.get(new Attributes.Name(key));
    }

  }

  public void run() {
    picocli.CommandLine.usage(this, System.out);
  }

  public static void main(String[] args) {
    picocli.CommandLine.usage(new CommandLine(), System.out);
  }

}
