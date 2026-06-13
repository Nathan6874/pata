import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectivityChecker extends StateNotifier<bool> {
  ConnectivityChecker() : super(false) {
    _init();
  }

  Future<void> _init() async {
    final result = await Connectivity().checkConnectivity();
    state = result != ConnectivityResult.none;
    
    Connectivity().onConnectivityChanged.listen((result) {
      state = result != ConnectivityResult.none;
    });
  }

  bool get isConnected => state;
}