import 'package:material_ui/material_ui.dart';

import '../models/mood.dart';

/// Muestra el dibujo del ánimo (`assets/moods/<id>.png`).
/// Si el PNG aún no existe, muestra un emoji provisional.
class MoodImage extends StatelessWidget {
  const MoodImage(this.mood, {super.key, this.size = 56});

  final MoodType mood;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      mood.asset,
      width: size,
      height: size,
      errorBuilder: (_, _, _) => SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(mood.fallback, style: TextStyle(fontSize: size * 0.7)),
        ),
      ),
    );
  }
}
