// ignore_for_file: unnecessary_this, avoid_print, unused_field, prefer_final_fields

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:peliculas/helpers/debauncer.dart';
import 'package:peliculas/models/models.dart';
import 'package:peliculas/models/search_response.dart';

class MoviesProvider extends ChangeNotifier {
  String _apiKey = '5780a4f4a3b4ef3b204db0161ed7f127';
  String _baseUrl = 'api.themoviedb.org';
  String _language = 'es-ES';

  int _popuparPage = 0;

  List<Movie> onDisplayMovies = [];
  List<Movie> popularMovies = [];

  Map<int, List<Cast>> movieCast = {};

  final debouncer = Debouncer(
    duration: Duration(milliseconds: 500),
  );

  final StreamController<List<Movie>> _suggestionsStreamController =
      new StreamController.broadcast();

  Stream<List<Movie>> get suggestionStream =>
      this._suggestionsStreamController.stream;

  MoviesProvider() {
    print('Movies provider inicializado');
    this.getOnDisplayMovies();
    this.getPopularMovies();
  }

  Future<String> _getJsonData(String endpaoint, [int page = 1]) async {
    final url = Uri.https(_baseUrl, endpaoint,
        {'api_key': _apiKey, 'language': _language, 'page': '$page'});

    final response = await http.get(url);
    return response.body;
  }

  getOnDisplayMovies() async {
    /* var url = Uri.https(_baseUrl, '3/movie/now_playing',
        {'api_key': _apiKey, 'language': _language, 'page': '1'});

    final response = await http.get(url); */

    final jsonData = await this._getJsonData('3/movie/now_playing');
    //final decodeData = json.decode(response.body);
    final nowPlayingREsponse = NowPlayingResponse.fromJson(jsonData);
    /*  final Map<String, dynamic> decodedDAta = json.decode(response.body); */

    //print(nowPlayingREsponse.results[0].title);

    onDisplayMovies = nowPlayingREsponse.results;
    notifyListeners();
  }

  getPopularMovies() async {
    _popuparPage++;

    final jsonDAta = await this._getJsonData('3/movie/popular', _popuparPage);
    /* var url = Uri.https(_baseUrl, '3/movie/popular',
        {'api_key': _apiKey, 'language': _language, 'page': '1'});

    final response = await http.get(url); */
    //final decodeData = json.decode(response.body);
    final popularREsponse = PopularResponse.fromJson(jsonDAta);
    /*  final Map<String, dynamic> decodedDAta = json.decode(response.body); */

    //print(nowPlayingREsponse.results[0].title);

    popularMovies = [...popularMovies, ...popularREsponse.results];
    notifyListeners();
  }

  Future<List<Cast>> getMoivieCast(int movieId) async {
    //TODO: revisar el mapa

    if (movieCast.containsKey(movieId)) return movieCast[movieId]!;

    print('pidiendo info al srvidor');

    final jsonData = await this._getJsonData('3/movie/$movieId/credits');
    final creditsResponse = CreditsResponse.fromJson(jsonData);

    movieCast[movieId] = creditsResponse.cast;

    return creditsResponse.cast;
  }

  Future<List<Movie>> searchMovies(String query) async {
    final url = Uri.https(_baseUrl, '3/search/movie',
        {'api_key': _apiKey, 'language': _language, 'query': query});

    final response = await http.get(url);
    final searchResponse = SearchResponse.fromJson(response.body);

    return searchResponse.results;
  }

  void getSuggestionByQuery(String query) {
    debouncer.value = '';
    debouncer.onValue = (value) async {
      //print('tenemos valor a buscar${value}');
      final result = await this.searchMovies(value);
      this._suggestionsStreamController.add(result);
    };

    final timer = Timer.periodic(Duration(milliseconds: 300), (_) {
      debouncer.value = query;
    });

    Future.delayed(Duration(milliseconds: 301)).then((_) => timer.cancel());
  }
}
