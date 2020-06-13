import 'dart:async';
import 'dart:convert' show base64, jsonDecode, jsonEncode;
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:translator/src/langs/languages.dart';
import './tokens/token_provider_interface.dart';
import './tokens/google_token_gen.dart';

///
/// This library is a Dart implementation of Free Google Translate API
/// based on JavaScript and PHP Free Google Translate APIs
///
/// [author] Gabriel N. Pacheco.
///
class GoogleTranslator {
  GoogleTranslator();

  var _baseUrl = 'https://translate.googleapis.com/translate_a/single';

  var _baseUrlSpeech = 'https://texttospeech.googleapis.com/v1/text:synthesize';
  var _baseUrlSpeechFree = 'https://translate.google.com.vn/translate_tts';

  TokenProviderInterface tokenProvider;

  /// Translates texts from specified language to another
  Future<String> translate(String sourceText,
      {String from = 'auto', String to = 'en'}) async {
    /// Assertion for supported language
    [from, to].forEach((language) {
      assert(Languages.isSupported(language),
          "\n\/E:\t\tError -> Not a supported language: '$language'");
    });

    /// New tokenProvider -> uses GoogleTokenGenerator for free API
    tokenProvider = GoogleTokenGenerator();
    try {
      var parameters = {
        'client': 't',
        'sl': from,
        'tl': to,
        'dt': 't',
        'ie': 'UTF-8',
        'oe': 'UTF-8',
        'tk': tokenProvider.generateToken(sourceText),
        'q': sourceText
      };

      /// Append parameters in url
      var str = '';
      parameters.forEach((key, value) {
        if (key == 'q') {
          str += (key + '=' + Uri.encodeComponent(value));
          return;
        }
        str += (key + '=' + Uri.encodeComponent(value) + '&');
      });

      var url = _baseUrl + '?' + str;

      /// Fetch and parse data from Google Transl. API
      final data = await http.get(url);
      if (data.statusCode != 200) {
        print(data.statusCode);
        return null;
      }

      final jsonData = jsonDecode(data.body);

      final sb = StringBuffer();
      for (var c = 0; c < jsonData[0].length; c++) {
        sb.write(jsonData[0][c][0]);
      }

      return sb.toString();
    } on Error catch (err) {
      print('Error: $err\n${err.stackTrace}');
      return null;
    }
  }

  Future speech(String sourceText,
      {String lang = 'vi-VN', String name = "vi-VN-Wavenet-A"}) async {
    /// Assertion for supported language
    // [lang].forEach((language) {
    //   assert(Languages.isSupported(language),
    //       "\n\/E:\t\tError -> Not a supported language: '$language'");
    // });

    /// New tokenProvider -> uses GoogleTokenGenerator for free API
    tokenProvider = GoogleTokenGenerator();
    try {
      var parameters = {
        'alt': 'json',
        'key': 'AIzaSyAa8yy0GdcGPHdtD083HiGGx_S0vMPScDM',
      };

      var headers = {
        'x-origin': 'https://explorer.apis.google.com',
        'x-referer': 'https://explorer.apis.google.com',
        'content-type': 'application/json',
      };

      var body = {
        "input": {"text": sourceText},
        "voice": {"languageCode": lang, "name": name},
        "audioConfig": {
          "audioEncoding": "LINEAR16",
          "pitch": 0,
          "speakingRate": 1
        }
      };

      /// Append parameters in url
      var str = '';
      parameters.forEach((key, value) {
        if (key == 'q') {
          str += (key + '=' + Uri.encodeComponent(value));
          return;
        }
        str += (key + '=' + Uri.encodeComponent(value) + '&');
      });

      var _urlSpeech = _baseUrlSpeech + '?' + str;

      final data =
          await http.post(_urlSpeech, headers: headers, body: jsonEncode(body));
      if (data.statusCode != 200) {
        print(data.statusCode);
        return null;
      }

      var audioPath = Uri.dataFromBytes(
        base64.decode(jsonDecode(data.body)['audioContent']),
        mimeType: "audio/wav",
      ).toString();
      await AudioPlayer().play(audioPath, isLocal: true);

      return 1;
    } on Error catch (err) {
      print('Error: $err\n${err.stackTrace}');
      return null;
    }
  }

  Future speechFree(String sourceText) async {
    var parameters = {
      'ie': 'UTF-8',
      'client': 'tw-ob',
      'tl': 'en',
      'q': sourceText,
    };

    /// Append parameters in url
    var str = '';
    parameters.forEach((key, value) {
      if (key == 'q') {
        str += (key + '=' + Uri.encodeComponent(value));
        return;
      }
      str += (key + '=' + Uri.encodeComponent(value) + '&');
    });

    var _urlSpeech = _baseUrlSpeechFree + '?' + str;
    try {
      await AudioPlayer().play(
        _urlSpeech,
        isLocal: false,
      );
      return 1;
    } on Error catch (err) {
      print('Error: $err\n${err.stackTrace}');
      return null;
    }
  }

  /// Translates and prints directly
  void translateAndPrint(String text,
      {String from = 'auto', String to = 'en'}) {
    translate(text, from: from, to: to).then((s) {
      print(s);
    });
  }

  /// Sets base URL for countries that default url doesn't work
  void set baseUrl(var base) => _baseUrl = base;
}
