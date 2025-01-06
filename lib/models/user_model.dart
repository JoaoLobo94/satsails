// this screen needs some heavy refactoring. On version "Unyielding conviction" we shall totally redo this spaghetti code.
import 'dart:convert';
import 'package:Satsails/handlers/response_handlers.dart';
import 'package:Satsails/models/purchase_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:pusher_beams/pusher_beams.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

const FlutterSecureStorage _storage = FlutterSecureStorage();

class UserModel extends StateNotifier<User> {
  UserModel(super.state);
  Future<void> setHasInsertedAffiliate(bool hasInsertedAffiliate) async {
    final box = await Hive.openBox('user');
    box.put('hasInsertedAffiliate', hasInsertedAffiliate);
    state = state.copyWith(hasInsertedAffiliate: hasInsertedAffiliate);
  }

  Future<void> setHasCreatedAffiliate(bool hasCreatedAffiliate) async {
    final box = await Hive.openBox('user');
    box.put('hasCreatedAffiliate', hasCreatedAffiliate);
    state = state.copyWith(hasCreatedAffiliate: hasCreatedAffiliate);
  }

  Future<void> setPaymentId(String paymentCode) async {
    final box = await Hive.openBox('user');
    box.put('paymentId', paymentCode);
    state = state.copyWith(paymentId: paymentCode);
  }

  Future<void> setRecoveryCode(String recoveryCode) async {
    await _storage.write(key: 'recoveryCode', value: recoveryCode);
    state = state.copyWith(recoveryCode: recoveryCode);
  }

}

class User {
  final bool hasInsertedAffiliate;
  final bool hasCreatedAffiliate;
  final String recoveryCode;
  final String paymentId;
  final String? createdAffiliateLiquidAddress;
  final String? insertedAffiliateCode;
  final String? createdAffiliateCode;

  User({
    this.hasInsertedAffiliate = false,
    this.hasCreatedAffiliate = false,
    required this.recoveryCode,
    required this.paymentId,
    this.createdAffiliateLiquidAddress = '',
    this.insertedAffiliateCode = '',
    this.createdAffiliateCode = '',
  });

  User copyWith({
    bool? hasInsertedAffiliate,
    bool? hasCreatedAffiliate,
    String? recoveryCode,
    String? paymentId,
    String? depixLiquidAddress,
  }) {
    return User(
      hasInsertedAffiliate: hasInsertedAffiliate ?? this.hasInsertedAffiliate,
      hasCreatedAffiliate: hasCreatedAffiliate ?? this.hasCreatedAffiliate,
      recoveryCode: recoveryCode ?? this.recoveryCode,
      paymentId: paymentId ?? this.paymentId,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      recoveryCode: json['user']['authentication_token'],
      paymentId: json['user']['payment_id'],
    );
  }

  factory User.fromShowUserJson(Map<String, dynamic> json) {
    return User(
      recoveryCode: json['user']['authentication_token'],
      paymentId: json['user']['payment_id'],
      createdAffiliateCode: json['created_affiliate']['code'] ?? '',
      insertedAffiliateCode: json['inserted_affiliate']['code'] ?? '',
      hasCreatedAffiliate: json['has_created_affiliate'] ?? false,
      createdAffiliateLiquidAddress: json['created_affiliate']['liquid_address'] ?? '',
      hasInsertedAffiliate: json['has_inserted_affiliate'] ?? false,
    );
  }
}

class UserService {
  static Future<Result<User>> createUserRequest(String auth) async {
    try {
      final response = await http.post(
        Uri.parse(dotenv.env['BACKEND']! + '/users'),
        body: jsonEncode({
          'user': {
            'authentication_token': auth,
          }
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 201) {
        return Result(data: User.fromJson(jsonDecode(response.body)));
      } else {
        return Result(error: 'Failed to create user: ${response.body}');
      }
    } catch (e) {
      return Result(
          error: 'An error has occurred. Please check your internet connection or contact support');
    }
  }

  static Future<Result<User>> showUser(String auth) async {
    try {
      final response = await http.get(
        Uri.parse(dotenv.env['BACKEND']! + '/users/show_user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': auth,
        },
      );

      if (response.statusCode == 200) {
        return Result(data: User.fromShowUserJson(jsonDecode(response.body)));
      } else {
        return Result(error: 'Failed to show user');
      }
    } catch (e) {
      return Result(
          error: 'An error has occurred. Please check your internet connection or contact support');
    }
  }

  static BeamsAuthProvider getPusherAuth(String auth, String userId) {
    try {
      final BeamsAuthProvider response = BeamsAuthProvider()
        ..authUrl = dotenv.env['BACKEND']! + '/users/get_pusher_auth'
        ..headers = {
          'Content-Type': 'application/json',
          'Authorization': auth,
        }
        ..queryParams = {
          'user_id': userId
        }
        ..credentials = 'omit';

      return response;
    } catch (e) {
      throw Exception(
          'An error has occurred. Please check your internet connection or contact support');
    }
  }

  static Future<Result<void>> deleteUser(String auth) async {
    try {
      final response = await http.delete(
        Uri.parse(dotenv.env['BACKEND']! + '/users/delete_user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': auth,
        },
      );

      if (response.statusCode == 200) {
        return Result(data: null);
      } else {
        return Result(error: 'Failed to delete user');
      }
    } catch (e) {
      return Result(error: 'An error has occurred. Please check your internet connection or contact support');
    }
  }
}