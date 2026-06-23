import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class UpdateService {
  static bool _isChecking = false;
  static String? _apkUrl;
  static String? _updateMessage;
  static bool _forceUpdate = false;

  // URL par défaut (GitHub Release)
  static const String defaultApkUrl = "https://github.com/Nathan6874/pata/releases/download/v1.0.1/pata-1.0.1.apk";

  static Future<bool> checkForUpdate() async {
    if (_isChecking) return false;
    _isChecking = true;

    try {
      // 1. Récupérer la version actuelle
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      print('📱 Version actuelle: $currentVersion');

      // 2. Récupérer la version distante depuis Firebase Remote Config
      final remoteConfig = FirebaseRemoteConfig.instance;

      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          minimumFetchInterval: const Duration(minutes: 10),
          fetchTimeout: const Duration(seconds: 10),
        ),
      );

      // Valeurs par défaut (utiliser GitHub Releases)
      await remoteConfig.setDefaults({
        'app_version': '1.0.1',  // ← Mettre la dernière version
        'apk_url': defaultApkUrl,
        'update_message': 'Nouvelle version disponible sur GitHub',
        'force_update': false,
      });

      await remoteConfig.fetchAndActivate();

      final remoteVersion = remoteConfig.getString('app_version');
      _apkUrl = remoteConfig.getString('apk_url');
      _updateMessage = remoteConfig.getString('update_message');
      _forceUpdate = remoteConfig.getBool('force_update');

      print('🌐 Version distante: $remoteVersion');
      print('📦 APK URL: $_apkUrl');

      final isUpdateAvailable = _compareVersions(currentVersion, remoteVersion);

      _isChecking = false;
      return isUpdateAvailable;
    } catch (e) {
      print('❌ Erreur vérification mise à jour: $e');
      _isChecking = false;
      return false;
    }
  }

  // Comparer les versions
  static bool _compareVersions(String current, String remote) {
    if (current == remote) return false;
    if (remote.isEmpty) return false;

    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final remoteParts = remote.split('.').map(int.parse).toList();

      for (int i = 0; i < remoteParts.length; i++) {
        if (i >= currentParts.length) return true;
        if (remoteParts[i] > currentParts[i]) return true;
        if (remoteParts[i] < currentParts[i]) return false;
      }

      return currentParts.length < remoteParts.length;
    } catch (e) {
      print('❌ Erreur comparaison versions: $e');
      return false;
    }
  }

  static Future<void> startUpdate() async {
    final url = _apkUrl ?? defaultApkUrl;
    print('📥 Téléchargement APK depuis: $url');
    
    // Ouvre le navigateur avec le lien de téléchargement
    // L'utilisateur pourra télécharger et installer l'APK
    try {
      // Utiliser le package url_launcher pour ouvrir le lien
      // await launchUrl(Uri.parse(url));
      print('🔗 Ouvrir: $url');
    } catch (e) {
      print('❌ Erreur: $e');
    }
  }

  static String? getApkUrl() => _apkUrl ?? defaultApkUrl;
  static String? getUpdateMessage() => _updateMessage;
  static bool isForceUpdate() => _forceUpdate;
}