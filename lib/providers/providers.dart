import 'package:pata/data/repository/transaction_repository.dart';
import 'package:pata/utils/connectivity_checker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:pata/auth/auth_service.dart';
export 'package:pata/data/remote/firestore_service.dart';
export 'package:pata/data/repository/transaction_repository.dart';

final connectivityCheckerProvider = Provider<ConnectivityChecker>((ref) {
  return ConnectivityChecker();
});