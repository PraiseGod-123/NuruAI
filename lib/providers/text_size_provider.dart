import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ══════════════════════════════════════════════════════════════
// TEXT SIZE PROVIDER
//
// Stores user's preferred text scale factor (0.85 – 1.4).
// Persisted via SharedPreferences so it survives app restarts.
//
// Usage in main app:
//   MaterialApp(
//     builder: (context, child) {
//       final scale = context.watch<TextSizeProvider>().scale;
//       return MediaQuery(
//         data: MediaQuery.of(context).copyWith(textScaleFactor: scale),
//         child: child!,
//       );
//     },
//   )
// ══════════════════════════════════════════════════════════════

class TextSizeProvider extends ChangeNotifier {
  static const _key = 'nuru_text_scale';
  static const _min = 0.85;
  static const _max = 1.40;
  static const _default = 1.0;

  double _scale = _default;
  double get scale => _scale;

  // Human-readable label
  String get label {
    if (_scale <= 0.88) return 'Small';
    if (_scale <= 1.05) return 'Normal';
    if (_scale <= 1.20) return 'Large';
    return 'Extra Large';
  }

  double get min => _min;
  double get max => _max;

  TextSizeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _scale = prefs.getDouble(_key) ?? _default;
    notifyListeners();
  }

  Future<void> setScale(double value) async {
    _scale = value.clamp(_min, _max);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, _scale);
  }

  Future<void> reset() => setScale(_default);
}
