import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'verifiable_credential.dart';

class VerifiablePresentation {
  final String id;
  final List<String> type;
  final VerifiableCredential credential;
  final String holderDid;
  final String nonce;
  final String audience;
  final DateTime timestamp;
  final int validitySeconds;
  final Map<String, dynamic> proof;
  final Set<String> disclosedAttributes;

  VerifiablePresentation({
    required this.id,
    required this.type,
    required this.credential,
    required this.holderDid,
    required this.nonce,
    required this.audience,
    required this.timestamp,
    this.validitySeconds = 60,
    required this.proof,
    required this.disclosedAttributes,
  });

  bool get isExpired {
    final expiryTime = timestamp.add(Duration(seconds: validitySeconds));
    return DateTime.now().isAfter(expiryTime);
  }

  int get remainingSeconds {
    final expiryTime = timestamp.add(Duration(seconds: validitySeconds));
    final diff = expiryTime.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  Map<String, dynamic> toJson() {
    // Filter claims according to disclosedAttributes
    final subject = credential.student;
    final claims = <String, dynamic>{
      'studentId': subject.studentId,
    };

    if (disclosedAttributes.contains('fullName')) {
      claims['fullName'] = {
        'en': subject.fullNameEn,
        'ar': subject.fullNameAr,
      };
    }
    if (disclosedAttributes.contains('faculty')) {
      claims['faculty'] = {
        'en': subject.facultyEn,
        'ar': subject.facultyAr,
      };
    }
    if (disclosedAttributes.contains('program')) {
      claims['program'] = {
        'en': subject.programEn,
        'ar': subject.programAr,
      };
    }
    if (disclosedAttributes.contains('degreeLevel')) {
      claims['degreeLevel'] = {
        'en': subject.degreeLevelEn,
        'ar': subject.degreeLevelAr,
      };
    }
    if (disclosedAttributes.contains('status')) {
      claims['status'] = subject.status.name;
    }

    return {
      '@context': ['https://www.w3.org/ns/credentials/v2'],
      'type': ['VerifiablePresentation'],
      'id': id,
      'holder': holderDid,
      'nonce': nonce,
      'audience': audience,
      'timestamp': timestamp.toIso8601String(),
      'validitySeconds': validitySeconds,
      'verifiableCredential': {
        'id': credential.id,
        'issuer': credential.issuer,
        'statusListIndex': credential.statusListIndex,
        'onChainAnchorHash': credential.onChainAnchorHash,
        'claims': claims,
        'issuerProof': credential.proof,
      },
      'proof': proof,
    };
  }

  /// Compact payload for Dynamic QR code rendering
  String toQrPayload() {
    return jsonEncode(toJson());
  }

  static String generateNonce() {
    final nowStr = DateTime.now().microsecondsSinceEpoch.toString();
    final bytes = utf8.encode('paldfi-nonce-$nowStr');
    return 'nonce-${sha256.convert(bytes).toString().substring(0, 16)}';
  }
}
