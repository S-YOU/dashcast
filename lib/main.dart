import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dashcast/player.dart';
import 'package:dashcast/notifiers.dart';

final url = 'https://itsallwidgets.com/podcast/feed';

final pathSuffix = 'dashcast/downloads';

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

class _MyNavBarState extends State<MyNavBar>
    with SingleTickerProviderStateMixin {
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
            _NavBarIcon(
              isActive: i == widget.activeIndex,
              onPressed: () => widget.onPressed(i),
              iconData: widget.icons[i],
              iconScale: iconScale,
              beaconRadius: beaconRadius,
              maxBeaconRadius: maxBeaconRadius,
            )
        ],
      ),
    );
  }
}

class _NavBarIcon extends StatelessWidget {
  final bool isActive;
  final double beaconRadius;
  final double maxBeaconRadius;
  final double iconScale;
  final IconData iconData;
  final VoidCallback onPressed;

  const _NavBarIcon({
    Key key,
    @required this.isActive,
    @required this.beaconRadius,
    @required this.maxBeaconRadius,
    @required this.iconScale,
    @required this.iconData,
    @required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: BeaconPainter(
        beaconRadius: isActive ? beaconRadius : 0,
        maxBeaconRadius: maxBeaconRadius,
        beaconColor: Colors.purple,
      ),
      child: GestureDetector(
        child: Transform.scale(
          scale: isActive ? iconScale : 1,
          child: Icon(iconData,
              color: isActive ? Colors.yellow[700] : Colors.black54),
        ),
        onTap: onPressed,
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
  }) : endColor = Color.lerp(beaconColor, Colors.white, 0.9);

  @override
  void paint(Canvas canvas, Size size) {
    if (beaconRadius == maxBeaconRadius) {
      return;
    }
    var animationProgress = beaconRadius / maxBeaconRadius;
    double strokeWidth = beaconRadius < maxBeaconRadius * 0.5
        ? beaconRadius
        : maxBeaconRadius - beaconRadius;
    final paint = Paint()
      ..color = Color.lerp(beaconColor, endColor, animationProgress)
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

  final EpisodeFeed rssFeed;

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
                    i.download();
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
