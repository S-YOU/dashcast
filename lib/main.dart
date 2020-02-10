import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:webfeed/webfeed.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

final url = 'https://itsallwidgets.com/podcast/feed';

final pathSuffix = 'dashcast/downloads';

Future<String> _getDownloadPath(String filename) async {
  final dir = await getApplicationDocumentsDirectory();
  final prefix = dir.path;
  final absolutePath = path.join(prefix, filename);
  print(absolutePath);
  return absolutePath;
}

class Podcast with ChangeNotifier {
  RssFeed _feed;
  RssItem _selectedItem;
  Map<String, bool> downloadStatus;

  RssFeed get feed => _feed;
  void parse(String url) async {
    final res = await http.get(url);
    final xmlStr = res.body;
    _feed = RssFeed.parse(xmlStr);
    notifyListeners();
  }

  RssItem get selectedItem => _selectedItem;
  set selectedItem(RssItem value) {
    _selectedItem = value;
    notifyListeners();
  }

  void download(RssItem item, [Function(double) callback]) async {
    final req = http.Request('GET', Uri.parse(item.guid));
    final res = await req.send();
    if (res.statusCode != 200)
      throw Exception('Unexpected HTTP code: ${res.statusCode}');

    final contentLength = res.contentLength;
    var downloadedLength = 0;

    final file = File(await _getDownloadPath(path.split(item.guid).last));
    res.stream
        .map((chunk) {
          downloadedLength += chunk.length;
          if (callback != null) callback(downloadedLength / contentLength);
          return chunk;
        })
        .pipe(file.openWrite())
        .whenComplete(() {
          print('Downloading complete');
        })
        .catchError((e) => print('An Error has occurred!!!: $e'));
  }
}

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => Podcast()..parse(url),
      child: MaterialApp(
        title: 'The Boring Show!',
        home: MyPage(),
      ),
    );
  }
}

class MyPage extends StatefulWidget {
  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  var navIndex = 0;

  final pages = List<Widget>.unmodifiable([
    EpisodesPage(),
    DummyPage(),
  ]);

  final iconList = List<IconData>.unmodifiable([
    Icons.hot_tub,
    Icons.timelapse,
  ]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[navIndex],
      bottomNavigationBar: MyNavBar(
        icons: iconList,
        onPressed: (i) => setState(() => navIndex = i),
        activeIndex: navIndex,
      ),
    );
  }
}

class MyNavBar extends StatefulWidget {
  const MyNavBar({
    @required this.icons,
    @required this.onPressed,
    @required this.activeIndex,
  }) : assert(icons != null);
  final List<IconData> icons;
  final Function(int) onPressed;
  final int activeIndex;

  @override
  _MyNavBarState createState() => _MyNavBarState();
}

class _MyNavBarState extends State<MyNavBar> with TickerProviderStateMixin {
  double beaconRadius = 0;
  double iconScale = 1;
  final double maxBeaconRadius = 20;
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(MyNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('${oldWidget.activeIndex}, ${widget.activeIndex}');
    if (oldWidget.activeIndex != widget.activeIndex) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    _controller.reset();
    final _curve = CurvedAnimation(parent: _controller, curve: Curves.linear);
    Tween<double>(begin: 0, end: 1).animate(_curve)
      ..addListener(() {
        setState(() {
          beaconRadius = maxBeaconRadius * _curve.value;
          if (beaconRadius == maxBeaconRadius) {
            beaconRadius = 0;
          }
          if (_curve.value < 0.5) {
            iconScale = 1 + _curve.value;
          } else {
            iconScale = 2 - _curve.value;
          }
        });
      });
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var i = 0; i < widget.icons.length; i++)
            CustomPaint(
                painter: BeaconPainter(
                    beaconRadius: i == widget.activeIndex ? beaconRadius : 0,
                    maxBeaconRadius: maxBeaconRadius,
                    beaconColor: Colors.purple),
                child: GestureDetector(
                  child: Transform.scale(
                    scale: i == widget.activeIndex ? iconScale : 1,
                    child: Icon(widget.icons[i],
                        color: i == widget.activeIndex
                            ? Colors.yellow[700]
                            : Colors.black54),
                  ),
                  onTap: () => widget.onPressed(i),
                ))
        ],
      ),
    );
  }
}

class BeaconPainter extends CustomPainter {
  final double beaconRadius;
  final double maxBeaconRadius;
  final Color beaconColor;
  final Color endColor;
  BeaconPainter({
    @required this.beaconRadius,
    @required this.maxBeaconRadius,
    @required this.beaconColor,
  }) : endColor = Color.lerp(beaconColor, Colors.white, 0.5);

  @override
  void paint(Canvas canvas, Size size) {
    if (beaconRadius == maxBeaconRadius) {
      return;
    }
    var animationProgress = beaconRadius / maxBeaconRadius;
    double strokeWidth = beaconRadius < maxBeaconRadius * 0.5
        ? beaconRadius
        : maxBeaconRadius - beaconRadius;
    print('strokeWidth: $strokeWidth');
    final paint = Paint()
      ..color =
          Color.lerp(beaconColor, endColor, animationProgress)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(const Offset(12, 12), beaconRadius, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class DummyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: const Text('Dummy Page'),
    );
  }
}

class EpisodesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<Podcast>(
      builder: (context, podcast, _) {
        return podcast.feed != null
            ? EpisodeListView(rssFeed: podcast.feed)
            : Center(
                child: CircularProgressIndicator(),
              );
      },
    );
  }
}

class EpisodeListView extends StatelessWidget {
  const EpisodeListView({
    Key key,
    @required this.rssFeed,
  }) : super(key: key);

  final RssFeed rssFeed;

  void downloadStatus(double num) => print('$num');

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: rssFeed.items
          .map(
            (i) => ListTile(
              title: Text(i.title),
              subtitle: Text(
                i.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                  icon: Icon(Icons.arrow_downward),
                  onPressed: () {
                    Provider.of<Podcast>(context).download(i);
                    Scaffold.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Downloading ${i.title}'),
                      ),
                    );
                  }),
              onTap: () {
                Provider.of<Podcast>(context).selectedItem = i;
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => PlayerPage()),
                );
              },
            ),
          )
          .toList(),
    );
  }
}

class PlayerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          Provider.of<Podcast>(context).selectedItem.title,
        ),
      ),
      body: SafeArea(child: Player()),
    );
  }
}

class Player extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final podcast = Provider.of<Podcast>(context);
    return Column(
      children: [
        Flexible(
            flex: 8,
            child: SingleChildScrollView(
              child: Column(children: [
                Image.network(podcast.feed.image.url),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    podcast.selectedItem.description.trim(),
                  ),
                ),
              ]),
            )),
        Flexible(
          flex: 2,
          child: Material(
            elevation: 12,
            child: AudioControls(),
          ),
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
  double _playPosition;
  StreamSubscription<PlayStatus> _playerSubscription;

  @override
  void initState() {
    super.initState();
    _sound = FlutterSound();
    _playPosition = 0;
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  void _cleanup() async {
    if (_sound.audioState == t_AUDIO_STATE.IS_PLAYING)
      await _sound.stopPlayer();
    _playerSubscription.cancel();
  }

  void _stop() async {
    await _sound.stopPlayer();
    setState(() => _isPlaying = false);
  }

  void _play(String url) async {
    await _sound.startPlayer(url);
    _playerSubscription = _sound.onPlayerStateChanged.listen((e) {
      if (e != null) {
        print(e.currentPosition);
        setState(() => _playPosition = (e.currentPosition / e.duration));
      }
    });
    setState(() => _isPlaying = true);
  }

  @override
  Widget build(BuildContext context) {
    final item = Provider.of<Podcast>(context).selectedItem;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Slider(
          value: _playPosition,
          onChanged: null,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.fast_rewind),
              onPressed: null,
            ),
            IconButton(
              icon: _isPlaying ? Icon(Icons.stop) : Icon(Icons.play_arrow),
              onPressed: () {
                if (_isPlaying) {
                  _stop();
                } else {
                  _play(item.guid);
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.fast_forward),
              onPressed: null,
            ),
          ],
        ),
      ],
    );
  }
}
