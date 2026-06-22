// lib/core/network/network_info.dart

import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

/// Connectivity contract.
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

/// Default implementation using internet_connection_checker_plus.
class NetworkInfoImpl implements NetworkInfo {
  final InternetConnection _connection;

  NetworkInfoImpl({InternetConnection? connection})
      : _connection = connection ?? InternetConnection.createInstance();

  @override
  Future<bool> get isConnected => _connection.hasInternetAccess;
}