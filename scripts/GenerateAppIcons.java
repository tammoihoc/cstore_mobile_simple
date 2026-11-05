import java.awt.AlphaComposite;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import javax.imageio.ImageIO;

/** Tạo các kích thước launcher icon Android từ ảnh gốc, không cần thư viện ngoài. */
public class GenerateAppIcons {
  public static void main(String[] args) throws IOException {
    // Chạy từ gốc dự án: java scripts/GenerateAppIcons.java
    Path source = Path.of("mobile/branding/app.png");
    BufferedImage original = ImageIO.read(source.toFile());
    if (original == null) {
      throw new IOException("Không đọc được ảnh PNG: " + source);
    }

    String[] densities = {"mdpi", "hdpi", "xhdpi", "xxhdpi", "xxxhdpi"};
    int[] sizes = {48, 72, 96, 144, 192};

    for (int index = 0; index < densities.length; index++) {
      Path destination = Path.of(
          "mobile/android/app/src/main/res",
          "mipmap-" + densities[index],
          "ic_launcher.png");
      Files.createDirectories(destination.getParent());
      BufferedImage icon = resize(original, sizes[index]);
      if (!ImageIO.write(icon, "png", destination.toFile())) {
        throw new IOException("Không ghi được PNG: " + destination);
      }
      System.out.println(destination + " | " + sizes[index] + "x" + sizes[index]);
    }
  }

  private static BufferedImage resize(BufferedImage original, int size) {
    // Giữ tỉ lệ và độ trong suốt; ảnh không vuông được đặt giữa khung vuông.
    BufferedImage icon = new BufferedImage(size, size, BufferedImage.TYPE_INT_ARGB);
    double scale = Math.min(
        (double) size / original.getWidth(),
        (double) size / original.getHeight());
    int width = Math.max(1, (int) Math.round(original.getWidth() * scale));
    int height = Math.max(1, (int) Math.round(original.getHeight() * scale));
    Graphics2D graphics = icon.createGraphics();
    try {
      graphics.setComposite(AlphaComposite.Src);
      graphics.setRenderingHint(
          RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BICUBIC);
      graphics.setRenderingHint(
          RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
      graphics.drawImage(original, (size - width) / 2, (size - height) / 2, width, height, null);
    } finally {
      graphics.dispose();
    }
    return icon;
  }
}
