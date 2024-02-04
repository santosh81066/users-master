import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/retry.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:users/models/carouselimages.dart';
import 'package:users/models/categorystate.dart';
import 'package:users/providers/authnotifier.dart';
import 'package:users/utils/purohitapi.dart';
import 'package:http/http.dart' as http;

class CarouselStateNotifier extends StateNotifier<CategoryState> {
  final AuthNotifier authNotifier;
  CarouselStateNotifier(this.authNotifier) : super(CategoryState());

  Future<void> getCarousel() async {
    final url = PurohitApi().baseUrl + PurohitApi().adds;
    final token = authNotifier.state.accessToken;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedpurohithCarouselResponseJson =
        prefs.getString('purohithCarouselResponse');
    if (savedpurohithCarouselResponseJson != null) {
      print('there is carousel data');
      // Decode the JSON string back into a Map
      Map<String, dynamic> savedpurohithCarouselResponse =
          json.decode(savedpurohithCarouselResponseJson);
      state = state.copyWith(
          carousel: SliderImages.fromJson(savedpurohithCarouselResponse));
      return;
    }
    print('there is no carousel data');
    final client = RetryClient(
      http.Client(),
      retries: 4,
      when: (response) {
        return response.statusCode == 401 ? true : false;
      },
      onRetry: (req, res, retryCount) async {
        if (retryCount == 0 && res?.statusCode == 401) {
          var accessToken = await authNotifier.restoreAccessToken();
          // Only this block can run (once) until done
          req.headers['Authorization'] = accessToken;
        }
      },
    );
    var response = await client.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': token!
      },
    );

    Map<String, dynamic> purohithCarouselResponse = json.decode(response.body);
    print('get carosole $purohithCarouselResponse');
    await prefs.setString(
        'purohithCarouselResponse', json.encode(purohithCarouselResponse));
    state = state.copyWith(
        carousel: SliderImages.fromJson(purohithCarouselResponse));
  }

  Future<XFile?> getCarouselPic(String imageid) async {
    final url = "${PurohitApi().baseUrl}${PurohitApi().adds}/$imageid";
    final token = authNotifier.state.accessToken;
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Check for cached image
    String? cachedBase64String = prefs.getString('carouselPic_$imageid');
    if (cachedBase64String != null) {
      final Uint8List bytes = base64Decode(cachedBase64String);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/slider$imageid');
      await file.writeAsBytes(bytes);
      return XFile(file.path);
    }
    final client = RetryClient(
      http.Client(),
      retries: 4,
      when: (response) => response.statusCode == 401,
      onRetry: (req, res, retryCount) async {
        if (retryCount == 0 && res?.statusCode == 401) {
          var accessToken = await authNotifier.restoreAccessToken();
          req.headers['Authorization'] = accessToken;
        }
      },
    );

    var response = await client.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': token!
      },
    );

    if (response.statusCode == 200) {
      final Uint8List resbytes = response.bodyBytes;
      String base64String = base64Encode(resbytes);
      await prefs.setString('carouselPic_$imageid', base64String);

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/slider$imageid');
      await file.writeAsBytes(resbytes);
      return XFile(file.path);
    }
    return null;
  }

  Future<void> loadCarouselImages() async {
    if (state.carousel == null) return;
    var updatedData =
        await Future.wait(state.carousel!.data!.map((carouseldata) async {
      final imageid = carouseldata.id;
      if (imageid != null) {
        final xfile = await getCarouselPic(imageid.toString());
        if (xfile != null) {
          carouseldata.xfile = xfile;
          print('carouseldata:${carouseldata.xfile!.path}');
        }
      }
      return carouseldata;
    }));
    state = state.copyWith(carousel: SliderImages(data: updatedData));
  }
}

// Riverpod provider for CarouselStateNotifier
final carouselStateProvider =
    StateNotifierProvider<CarouselStateNotifier, CategoryState>((ref) {
  final authNotifier = ref.read(authProvider.notifier);
  return CarouselStateNotifier(authNotifier);
});
