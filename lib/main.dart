import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Boring Show!',
      home: BoringPage(),
    );
  }
}

class BoringPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: DashCastApp()),
    );
  }
}

class DashCastApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Flexible(
          flex: 9,
          child: Placeholder(),
        ),
        Flexible(
          flex: 1,
          child: AudioControls(),
        ),
      ],
    );
  }
}

class AudioControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PlaybackButtons(),
      ],
    );
  }
}


class PlaybackButtons extends StatefulWidget {
  @override
  _PlaybackButtonsState createState() => _PlaybackButtonsState();
}

class _PlaybackButtonsState extends State<PlaybackButtons> {
  bool _isPlaying = false;
  FlutterSound _sound;
  final _url =
      'https://incompetech.com/music/royalty-free/mp3-royaltyfree/Surf%20Shimmy.mp3';
  double playPosition;

  @override
  void initState() {
    super.initState();
    _sound = new FlutterSound();
    playPosition =  0;
  }

  void stop() async {
    await _sound.stopPlayer();
    setState(() => _isPlaying = false);
  }

  void play() async {
    String path = await _sound.startPlayer(_url);
    print('startPlayer: $path');
  }

  void fastForward(args) {

  }

  void fastRewind(args) {

  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Slider(
          value: 0.2,
        ),
        Row(
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.fast_rewind),
              onPressed: () => {},
            ),
            IconButton(
              icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
              onPressed: () => _playSound(),
            ),
            IconButton(
              icon: Icon(Icons.fast_forward),
              onPressed: () => {},
            ),
          ],
        ),
      ],
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
