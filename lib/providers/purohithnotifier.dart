import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/retry.dart';
import 'package:users/models/purohithusers.dart';
import 'package:users/providers/authnotifier.dart';
import 'package:users/providers/loader.dart';
import 'package:users/utils/purohitapi.dart';
import 'package:http/http.dart' as http;

class PurohithNotifier extends StateNotifier<PurohitUsers> {
  final AuthNotifier authNotifier;
  PurohithNotifier(this.authNotifier) : super(PurohitUsers());

  Future<void> getPurohit(BuildContext cont, WidgetRef ref) async {
    final url = PurohitApi().baseUrl + PurohitApi().getPurohit;

    final token = authNotifier.state.accessToken;
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
    Map<String, dynamic> purohithUserResponse = json.decode(response.body);
    print('purohith data:$purohithUserResponse ');
    state = PurohitUsers.fromJson(purohithUserResponse);
  }
}

final purohithNotifierProvider =
    StateNotifierProvider<PurohithNotifier, PurohitUsers>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);
  return PurohithNotifier(authNotifier);
});
