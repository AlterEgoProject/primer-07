import java.io.File;
import java.io.FilenameFilter;

public class FileFilter implements FilenameFilter {
  @Override
  public boolean accept(File directory, String fileName) {
    if(fileName.endsWith(".wav")) {
      return true;
    }
    return false;
  }
}
