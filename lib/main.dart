import 'package:flutter/material.dart';

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

  void stop() {}

  void play() {}

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
