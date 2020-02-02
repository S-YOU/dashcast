import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: BoringPage(),
    );
  }
}

class BoringPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: PlaybackButtton()),
    );
  }
}

class PlaybackButtton extends StatefulWidget {
  @override
  _PlaybackButttonState createState() => _PlaybackButttonState();
}

class _PlaybackButttonState extends State<PlaybackButtton> {
  bool _isPlaying = false;
  FlutterSound _sound;
  final _url =
      'https://incompetech.com/music/royalty-free/mp3-royaltyfree/Surf%20Shimmy.mp3';

  void stop() async {
    await _sound.stopPlayer();
    setState(() => _isPlaying = false);
  }

  void play() async {
    _sound = new FlutterSound();

    String path = await _sound.startPlayer(_url);
    print('startPlayer: $path');
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
      onPressed: () => _playSound(),
    );
  }

  void _playSound() {
    if (_isPlaying) {
      stop();
    } else {
      play();
    }
    setState(() => _isPlaying = !_isPlaying);
  }
}
