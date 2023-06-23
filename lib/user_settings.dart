import 'package:flutter/material.dart';
import 'package:reader_app/model/scroll.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserSettings extends StatelessWidget {
  const UserSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder:
          (BuildContext context, AsyncSnapshot<SharedPreferences> snapshot) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
          ),
          body: Builder(
            builder: (BuildContext context) {
              if (snapshot.hasData) {
                return UserSettingsBody(snapshot.data!);
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
        );
      },
    );
  }
}

class UserSettingsBody extends StatefulWidget {
  final SharedPreferences prefs;
  const UserSettingsBody(this.prefs, {super.key});

  @override
  State<UserSettingsBody> createState() => _UserSettingsBodyState();
}

class _UserSettingsBodyState extends State<UserSettingsBody> {
  late final Scroll scroll;

  @override
  void initState() {
    super.initState();
    scroll = Scroll(widget.prefs);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: const Text('Scroll Interval'),
          subtitle: const Text('Time between scrolls in milliseconds'),
          trailing: SizedBox(
            width: 100,
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: scroll.interval.toString(),
              ),
              onChanged: (String value) {
                setState(() {
                  scroll.interval = int.parse(value);
                });
              },
            ),
          ),
        ),
        ListTile(
          title: const Text('Scroll Sensitivity'),
          subtitle: const Text('How far you need to scroll to change page'),
          trailing: SizedBox(
            width: 100,
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: scroll.span.toString(),
              ),
              onChanged: (String value) {
                setState(() {
                  scroll.span = int.parse(value);
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}
