import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webfeed/domain/rss_item.dart';
import 'package:webfeed/webfeed.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class Podcast with ChangeNotifier {
  EpisodeFeed _feed;
  Episode _selectedItem;

  EpisodeFeed get feed => _feed;
  void parse(String url) async {
    final res = await http.get(url);
    final xmlStr = res.body;
    _feed = EpisodeFeed.parse(xmlStr);
    notifyListeners();
  }

  Episode get selectedItem => _selectedItem;
  set selectedItem(Episode value) {
    _selectedItem = value;
    notifyListeners();
  }
}

class EpisodeFeed extends RssFeed {
  final RssFeed _feed;
  List<Episode> items;

  EpisodeFeed(this._feed) {
    items = _feed.items.map((item) => Episode(item)).toList();
  }

  static EpisodeFeed parse(xmlStr) {
    return EpisodeFeed(RssFeed.parse(xmlStr));
  }
}

class Episode extends RssItem with ChangeNotifier {
  String downloadLocation;
  final RssItem item;

  Episode(this.item);

  String get title => item.title;
  String get description => item.description;

  void download(Episode item, [Function(double) callback]) async {
    final req = http.Request('GET', Uri.parse(item.guid));
    final res = await req.send();
    if (res.statusCode != 200)
      throw Exception('Unexpected HTTP code: ${res.statusCode}');

    final contentLength = res.contentLength;
    var downloadedLength = 0;

    var filePath = await _getDownloadPath(path.split(item.guid).last);
    final file = File(filePath);
    res.stream
        .map((chunk) {
          downloadedLength += chunk.length;
          if (callback != null) callback(downloadedLength / contentLength);
          return chunk;
        })
        .pipe(file.openWrite())
        .whenComplete(() {
          //TODO: Save to SharedPreferences or similar;
          item.downloadLocation = filePath;
          notifyListeners();
        })
        .catchError((e) => print('An Error has occurred!!!: $e'));
  }

  Future<String> _getDownloadPath(String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final prefix = dir.path;
    final absolutePath = path.join(prefix, filename);
    print(absolutePath);
    return absolutePath;
  }
}
