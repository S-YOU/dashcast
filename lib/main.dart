import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;
import 'package:webfeed/webfeed.dart';

final url = 'https://itsallwidgets.com/podcast/feed';
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Boring Show!',
      home: EpisodesPage(),
    );
  }
}

class EpisodesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: http.get(url),
        builder: (context, AsyncSnapshot<http.Response> snapshot) {
          if (snapshot.hasData) {
            final response = snapshot.data;
            if (response.statusCode == 200) {
              final rssString = response.body;
              var rssFeed = RssFeed.parse(rssString);
              return EpisodeListView(rssFeed: rssFeed);
            }
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class EpisodeListView extends StatelessWidget {
  final RssFeed rssFeed;

  const EpisodeListView({
    Key key,
    this.rssFeed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: rssFeed.items
          .map(
            (e) => ListTile(
              title: Text(e.title),
              subtitle: Text(
                e.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PlayerPage(item: i),
                  ),
                );
              },
            ),
          )
          .toList(),
    );
  }
}

class PlayerPage extends StatelessWidget {
  final RssItem item;

  const PlayerPage({Key key, this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(item.title)),
      body: SafeArea(child: Player()),
    );
  }
}

class Player extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Flexible(
          flex: 9,
          child: Placeholder(),
        ),
        Flexible(
          flex: 2,
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
  _PlaybackButtonState createState() => _PlaybackButtonState();
}

class _PlaybackButtonState extends State<PlaybackButtons> {
  bool _isPlaying = false;
  FlutterSound _sound;
  final url =
      'https://incompetech.com/music/royalty-free/mp3-royaltyfree/Surf%20Shimmy.mp3';
  double _playPosition;
  Stream<PlayStatus> _playerSubscription;

  @override
  void initState() {
    super.initState();
    _sound = FlutterSound();
    _playPosition = 0;
  }

  void _stop() async {
    await _sound.stopPlayer();
    setState(() => _isPlaying = false);
  }

  void _play() async {
    await _sound.startPlayer(url);
    _playerSubscription = _sound.onPlayerStateChanged
      ..listen((e) {
        if (e != null) {
          print(e.currentPosition);
          setState(() => _playPosition = (e.currentPosition / e.duration));
        }
      });
    setState(() => _isPlaying = true);
  }

  void _fastForward() {}

  void _rewind() {}

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Slider(value: _playPosition),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.fast_rewind),
              onPressed: () => _rewind(),
            ),
            IconButton(
              icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
              onPressed: () {
                if (_isPlaying) {
                  _stop();
                } else {
                  _play();
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.fast_forward),
              onPressed: () => _fastForward(),
            ),
          ],
        ),
      ],
    );
  }
}
