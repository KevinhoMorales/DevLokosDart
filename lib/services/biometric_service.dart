import 'package:local_auth/local_auth.dart';

/// Autenticación biométrica local (Face ID / Touch ID / huella).
class BiometricService {
  BiometricService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  Future<bool> get canCheckBiometrics async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// true si el dispositivo puede ofrecer biometría o credencial de dispositivo.
  Future<bool> isAvailable() async {
    final supported = await isDeviceSupported();
    if (!supported) return false;
    final canCheck = await canCheckBiometrics;
    if (!canCheck) return false;
    final enrolled = await _auth.getAvailableBiometrics();
    return enrolled.isNotEmpty;
  }

  /// Solicita biometría. Devuelve true si el usuario se autentica.
  /// Si no hay biometría / cancela / error → false (el caller hace fallback).
  Future<bool> authenticate({
    String reason = 'Confirma para eliminar tu cuenta',
  }) async {
    try {
      final available = await isAvailable();
      if (!available) return false;

      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        sensitiveTransaction: true,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
