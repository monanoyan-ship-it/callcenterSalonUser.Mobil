import 'package:flutter/material.dart';

/// Geniş ekranlarda (tablet/desktop) child'ı [maxWidth] içinde merkeze hizalar.
/// Telefon genişliklerinde tam ekran. Form/profil/tablo sayfalarında
/// okunabilirliği arttırır.
///
/// **Implementation notu:** `Center` + `ConstrainedBox` + `ListView` antipattern'i
/// (Center child'a loose constraint geçirir, ListView intrinsic height alamaz, 0
/// yükseklikte çizilir) müşteri mobilinde yaşanmıştı. Çözüm: `Row + Spacer +
/// SizedBox` pattern'i; Spacer'lar yatay flex ile boşluğu paylaşır, ortadaki
/// SizedBox tight width'i ListView'a aktarır, `expandHeight=true` iken Row dikey
/// tight constraint verir. Bottom bar gibi shrink-wrap yüzeylerde
/// `expandHeight=false` kullanılır.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 720,
    this.expandHeight = true,
  });

  final Widget child;
  final double maxWidth;
  final bool expandHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth || constraints.maxWidth <= maxWidth) {
          return child;
        }
        return Row(
          crossAxisAlignment:
              expandHeight ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
          children: [
            const Spacer(),
            SizedBox(width: maxWidth, child: child),
            const Spacer(),
          ],
        );
      },
    );
  }
}
