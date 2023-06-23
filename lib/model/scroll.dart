import 'package:shared_preferences/shared_preferences.dart';

class Scroll {
  final SharedPreferences prefs;

  Scroll(this.prefs);

  int get interval => prefs.getInt('scrollInterval') ?? 3000;

  int get span => prefs.getInt('scrollSpan') ?? 800;

  set interval(int value) {
    prefs.setInt('scrollInterval', value);
  }

  set span(int value) {
    prefs.setInt('scrollSpan', value);
  }
}
