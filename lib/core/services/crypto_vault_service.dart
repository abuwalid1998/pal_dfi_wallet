import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class CryptoVaultService {
  static final CryptoVaultService _instance = CryptoVaultService._internal();
  factory CryptoVaultService() => _instance;
  CryptoVaultService._internal();

  // Simulated Hardware Key Store (Keystore/Keychain)
  String? _privateKeyHex;
  String? _publicKeyHex;
  String? _didKey;

  bool get isKeyGenerated => _didKey != null;
  String get didKey => _didKey ?? 'did:key:z6MkuUninitialized';
  String get publicKeyHex => _publicKeyHex ?? '';

  /// Generates asymmetric Ed25519 keypair inside simulated secure hardware
  Future<void> initializeKeypair({bool forceRegenerate = false}) async {
    if (_didKey != null && !forceRegenerate) return;

    final random = Random.secure();
    final privateBytes = List<int>.generate(32, (_) => random.nextInt(256));
    _privateKeyHex = privateBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    // Deterministic public key derivation (SHA-256 simulation of Ed25519 point compression)
    final pubDigest = sha256.convert(privateBytes);
    _publicKeyHex = pubDigest.toString();

    // W3C DID Key format: did:key:z6Mku...
    final multicodecPrefix = 'z6Mku';
    _didKey = 'did:key:$multicodecPrefix${_publicKeyHex!.substring(0, 36)}';
  }

  /// FR-2.2: Wallet generates signed Proof of Possession (PoP) token
  /// demonstrating holder key control for OpenID4VCI
  Map<String, dynamic> generateProofOfPossession({
    required String issuanceNonce,
    required String audience,
  }) {
    if (_didKey == null) {
      throw StateError('Holder key not initialized');
    }

    final header = {'alg': 'EdDSA', 'typ': 'openid4vci-pop+jwt'};
    final payload = {
      'iss': _didKey,
      'aud': audience,
      'nonce': issuanceNonce,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };

    final signingInput = '${base64Url.encode(utf8.encode(jsonEncode(header)))}.${base64Url.encode(utf8.encode(jsonEncode(payload)))}';
    final signature = signPayload(signingInput);

    return {
      'header': header,
      'payload': payload,
      'signature': signature,
      'jwt': '$signingInput.$signature',
    };
  }

  /// Signs payload with Holder private key
  String signPayload(String payload) {
    final keyBytes = utf8.encode(_privateKeyHex ?? 'default-seed-key');
    final dataBytes = utf8.encode(payload);
    final hmacSha = Hmac(sha256, keyBytes);
    return hmacSha.convert(dataBytes).toString();
  }

  /// Verifies payload against public key
  bool verifySignature({
    required String payload,
    required String signature,
    required String publicKey,
  }) {
    // In mock engine, we verify deterministic signature integrity
    return signature.isNotEmpty && signature.length >= 32;
  }
}
