import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String clientId = '6752c32f79404a7bba5e5ef1eac59a96';
const String clientSecret = 'fe14dabba842419cb671da8e12fc7e3b';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ArtistSearchScreen(),
    );
  }
}

class ArtistSearchScreen extends StatefulWidget {
  @override
  _ArtistSearchScreenState createState() => _ArtistSearchScreenState();
}

class _ArtistSearchScreenState extends State<ArtistSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _artistInfo;
  List<String> _topTracks = [];
  String? _artistImage;
  bool _isLoading = false;

  Future<String?> _getSpotifyAccessToken() async {
    final String credentials = base64Encode(utf8.encode('$clientId:$clientSecret'));

    final response = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'client_credentials',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data['access_token'];
    } else {
      print('Failed to get access token: ${response.statusCode}');
      return null;
    }
  }

  Future<void> _getArtistAndTopTracks(String artistName) async {
    setState(() {
      _isLoading = true;
      _topTracks = [];
    });

    final accessToken = await _getSpotifyAccessToken();
    if (accessToken == null) return;

    final artistResponse = await http.get(
      Uri.parse('https://api.spotify.com/v1/search?q=$artistName&type=artist&limit=1'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (artistResponse.statusCode == 200) {
      final Map<String, dynamic> artistData = json.decode(artistResponse.body);
      if (artistData['artists']['items'].isNotEmpty) {
        final artist = artistData['artists']['items'][0];
        final artistId = artist['id'];
        _artistImage = artist['images'].isNotEmpty ? artist['images'][0]['url'] : null;

        setState(() {
          _artistInfo = 'Artist: ${artist['name']}\n'
              'Followers: ${artist['followers']['total']}\n'
              'Genres: ${artist['genres'].join(', ')}\n'
              'Popularity: ${artist['popularity']}';
        });

        await _getTopTracks(artistId, accessToken);
      } else {
        setState(() {
          _artistInfo = 'No artist found.';
        });
      }
    } else {
      print('Error fetching artist info: ${artistResponse.statusCode}');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _getTopTracks(String artistId, String token) async {
    final topTracksResponse = await http.get(
      Uri.parse('https://api.spotify.com/v1/artists/$artistId/top-tracks?market=US'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (topTracksResponse.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(topTracksResponse.body);
      final List<dynamic> tracks = data['tracks'];
      setState(() {
        _topTracks = tracks.map((track) => track['name'].toString()).toList();
      });
    } else {
      print('Error fetching top tracks: ${topTracksResponse.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Spotify Artist Search'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter artist name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_controller.text.isNotEmpty) {
                  _getArtistAndTopTracks(_controller.text);
                }
              },
              child: Text('Search'),
            ),
            SizedBox(height: 20),
            if (_isLoading) CircularProgressIndicator(),
            if (_artistInfo != null)
              Text(
                _artistInfo!,
                textAlign: TextAlign.left,
              ),
            SizedBox(height: 20),
            if (_artistImage != null)
              Image.network(
                _artistImage!,
                width: 100,  // Set desired width
                height: 100, // Set desired height
                fit: BoxFit.cover, // Optional, to adjust how the image fits within the bounds
              ),

            if (_topTracks.isNotEmpty) ...[
              Text('Top Tracks:', style: TextStyle(fontWeight: FontWeight.bold)),
              for (var track in _topTracks) Text(track),
            ],
          ],
        ),
      ),
    );
  }
}
