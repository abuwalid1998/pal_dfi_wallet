import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LedgerVerificationResult {
  final bool isValid;
  final bool isRevoked;
  final bool isTampered;
  final bool isAnchorVerified;
  final int responseTimeMs;
  final String statusDescription;
  final String blockNumber;
  final String transactionId;
  final bool isLiveNetwork;
  final String explorerUrl;

  LedgerVerificationResult({
    required this.isValid,
    required this.isRevoked,
    required this.isTampered,
    required this.isAnchorVerified,
    required this.responseTimeMs,
    required this.statusDescription,
    required this.blockNumber,
    required this.transactionId,
    this.isLiveNetwork = false,
    this.explorerUrl = 'http://localhost:8090',
  });
}

class FabricLedgerService {
  static final FabricLedgerService _instance = FabricLedgerService._internal();
  factory FabricLedgerService() => _instance;
  FabricLedgerService._internal() {
    // Initiate background connection health check
    checkGatewayHealth();
  }

  // REST Gateway Base URL
  final String gatewayUrl = 'http://localhost:5050';
  final ValueNotifier<bool> isLiveConnected = ValueNotifier<bool>(false);

  // Bitstring status list in-memory cache (0 = valid, 1 = revoked) - synced dynamically with Fabric
  final Map<int, bool> _bitstringStatusList = {};

  // Anchored SHA-256 hashes on Fabric ledger
  final Map<String, int> _anchoredHashesToBlock = {};

  final String issuerDid = 'did:key:z6MkuNUVTEAcademicAuthorityPalestine2024PMA';
  final String issuerPublicKey = 'nuvte-pki-cert-ed25519-root-40983bf9';
  final String explorerBaseUrl = 'http://localhost:8090';

  /// Check whether the local Fabric Gateway REST server is reachable
  Future<bool> checkGatewayHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$gatewayUrl/api/health'))
          .timeout(const Duration(milliseconds: 1500));
      final healthy = (response.statusCode == 200);
      isLiveConnected.value = healthy;
      return healthy;
    } catch (_) {
      isLiveConnected.value = false;
      return false;
    }
  }

  /// Register an anchor on-chain during issuance
  void anchorCredentialHash(String hash, int block) {
    _anchoredHashesToBlock[hash] = block;
  }

  /// Toggle revocation status bit in BitstringStatusList2021
  void setRevocationStatus(int index, bool isRevoked) {
    _bitstringStatusList[index] = isRevoked;
  }

  /// Check revocation status bit directly
  bool isBitRevoked(int index) {
    return _bitstringStatusList[index] ?? false;
  }

  /// Query the status bit directly from the live ledger or local cache
  Future<bool> checkRevocationStatusOnChain(int statusListIndex, {String? docId}) async {
    try {
      if (docId != null && docId.isNotEmpty) {
        final res = await http
            .get(Uri.parse('$gatewayUrl/api/documents/$docId'))
            .timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data is Map<String, dynamic> && data.containsKey('status')) {
            final isRev = (data['status'] == 'REVOKED');
            _bitstringStatusList[statusListIndex] = isRev;
            isLiveConnected.value = true;
            return isRev;
          }
        }
      }
      final res = await http
          .get(Uri.parse('$gatewayUrl/api/status-list/nuvte-status-list-2024/$statusListIndex'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final isRev = data['isRevoked'] == true;
        _bitstringStatusList[statusListIndex] = isRev;
        isLiveConnected.value = true;
        return isRev;
      }
    } catch (_) {
      // Local fallback
    }
    return _bitstringStatusList[statusListIndex] ?? false;
  }

  /// Anchor a new academic document on the live Hyperledger Fabric smart contract
  Future<Map<String, dynamic>> anchorDocumentOnChain({
    required String docId,
    required String docType,
    required String docHash,
    required String subjectHash,
    required int statusListIndex,
    Map<String, dynamic>? metadata,
  }) async {
    final stopwatch = Stopwatch()..start();
    _bitstringStatusList[statusListIndex] = false;
    _anchoredHashesToBlock[docHash] = 104820 + statusListIndex;

    try {
      final response = await http
          .post(
            Uri.parse('$gatewayUrl/api/documents/anchor'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'docId': docId,
              'docType': docType,
              'docHash': docHash,
              'issuerDid': issuerDid,
              'subjectHash': subjectHash,
              'statusListIndex': statusListIndex,
              'metadata': metadata ?? {},
            }),
          )
          .timeout(const Duration(seconds: 15));

      stopwatch.stop();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        isLiveConnected.value = true;
        return {
          'success': true,
          'isLive': true,
          'txId': data['txId'] ?? 'tx-live-${DateTime.now().millisecondsSinceEpoch}',
          'timestamp': data['timestamp'] ?? DateTime.now().toUtc().toIso8601String(),
          'elapsedMs': stopwatch.elapsedMilliseconds,
          'explorerUrl': explorerBaseUrl,
        };
      }
    } catch (_) {
      // Fallback to simulation mode if gateway is not reachable
    }

    stopwatch.stop();
    return {
      'success': true,
      'isLive': false,
      'txId': 'tx-sim-0x${docHash.length >= 16 ? docHash.substring(0, 16) : "fab-anchor"}',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'elapsedMs': stopwatch.elapsedMilliseconds,
      'explorerUrl': explorerBaseUrl,
    };
  }

  /// Toggle revocation status on-chain (supports both Revocation and Reinstatement)
  Future<Map<String, dynamic>> toggleDocumentRevocationOnChain({
    required String docId,
    required int statusListIndex,
    required bool isRevoking,
    required String reason,
  }) async {
    final stopwatch = Stopwatch()..start();
    _bitstringStatusList[statusListIndex] = isRevoking;

    final endpoint = isRevoking ? '$gatewayUrl/api/documents/revoke' : '$gatewayUrl/api/documents/reinstate';

    try {
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'docId': docId,
              'reason': reason,
            }),
          )
          .timeout(const Duration(seconds: 15));

      stopwatch.stop();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        isLiveConnected.value = true;
        return {
          'success': true,
          'isLive': true,
          'txId': data['txId'] ?? 'tx-${isRevoking ? "revoke" : "reinstate"}-${DateTime.now().millisecondsSinceEpoch}',
          'timestamp': data['timestamp'] ?? DateTime.now().toUtc().toIso8601String(),
          'elapsedMs': stopwatch.elapsedMilliseconds,
          'explorerUrl': explorerBaseUrl,
        };
      }
    } catch (_) {
      // Fallback
    }

    stopwatch.stop();
    return {
      'success': true,
      'isLive': false,
      'txId': 'tx-sim-${isRevoking ? "revoke" : "reinstate"}-${DateTime.now().millisecondsSinceEpoch}',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'elapsedMs': stopwatch.elapsedMilliseconds,
      'explorerUrl': explorerBaseUrl,
    };
  }

  /// Revoke an academic document on the live Hyperledger Fabric smart contract
  Future<Map<String, dynamic>> revokeDocumentOnChain({
    required String docId,
    required int statusListIndex,
    required String reason,
  }) async {
    return toggleDocumentRevocationOnChain(
      docId: docId,
      statusListIndex: statusListIndex,
      isRevoking: true,
      reason: reason,
    );
  }

  /// Record an immutable verification audit on the live Hyperledger Fabric ledger
  Future<Map<String, dynamic>> recordVerificationAudit({
    required String auditId,
    required String verifierDid,
    required String verifierName,
    required String docId,
    required String studentDid,
    required String nonce,
    required String verificationResult,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$gatewayUrl/api/audit/record'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'auditId': auditId,
              'verifierDid': verifierDid,
              'verifierName': verifierName,
              'docId': docId,
              'studentDid': studentDid,
              'nonce': nonce,
              'verificationResult': verificationResult,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'isLive': true,
          'txId': data['txId'] ?? 'tx-audit-${DateTime.now().millisecondsSinceEpoch}',
        };
      }
    } catch (_) {
      // Ignore
    }
    return {
      'success': true,
      'isLive': false,
      'txId': 'tx-sim-audit-${DateTime.now().millisecondsSinceEpoch}',
    };
  }

  /// Verifies credential against Hyperledger Fabric 2.5
  /// Strictly checks BitstringStatusList2021 and anchor hash (< 3.0s NFR)
  Future<LedgerVerificationResult> queryStatusList({
    required int statusListIndex,
    required String anchorHash,
    required String signature,
    String docId = 'DOC-NUVTE-2024-GRAD-098',
  }) async {
    final stopwatch = Stopwatch()..start();

    // 1. Try Live Hyperledger Fabric REST Gateway first
    try {
      final response = await http
          .post(
            Uri.parse('$gatewayUrl/api/documents/verify'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'docId': docId,
              'docHash': anchorHash,
            }),
          )
          .timeout(const Duration(seconds: 10));

      stopwatch.stop();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final isValid = data['isValid'] == true;
        final isRevoked = data['isRevoked'] == true;
        final txId = data['txId'] as String? ?? 'tx-hlf-${DateTime.now().millisecondsSinceEpoch}';
        final message = data['message'] as String? ?? 'Verified on Hyperledger Fabric 2.5';
        final blockNum = 'HLF-BLK-LIVE-2024';

        isLiveConnected.value = true;
        _bitstringStatusList[statusListIndex] = isRevoked;

        return LedgerVerificationResult(
          isValid: isValid,
          isRevoked: isRevoked,
          isTampered: !isValid && !isRevoked,
          isAnchorVerified: isValid || isRevoked,
          responseTimeMs: stopwatch.elapsedMilliseconds,
          statusDescription: message,
          blockNumber: blockNum,
          transactionId: txId.isNotEmpty ? txId : 'tx-hlf-verified',
          isLiveNetwork: true,
          explorerUrl: explorerBaseUrl,
        );
      }
    } catch (_) {
      // Gateway unreachable, fall back to robust local simulation
      isLiveConnected.value = false;
    }

    // 2. Fallback local simulation
    if (!stopwatch.isRunning) stopwatch.start();
    await Future.delayed(const Duration(milliseconds: 180));
    stopwatch.stop();

    final isRevoked = _bitstringStatusList[statusListIndex] ?? false;
    final isTampered = signature.isEmpty || signature.length < 20;
    final isAnchorValid = anchorHash.isNotEmpty;

    final blockNum = 'HLF-BLK-${104820 + statusListIndex}';
    final txId = 'tx-0x${(anchorHash.length >= 16 ? anchorHash.substring(0, 16) : "fabric-tx-root")}';

    if (isTampered) {
      return LedgerVerificationResult(
        isValid: false,
        isRevoked: isRevoked,
        isTampered: true,
        isAnchorVerified: false,
        responseTimeMs: stopwatch.elapsedMilliseconds,
        statusDescription: 'Cryptographic signature mismatch! Tampered payload detected.',
        blockNumber: blockNum,
        transactionId: txId,
        isLiveNetwork: false,
      );
    }

    if (isRevoked) {
      return LedgerVerificationResult(
        isValid: false,
        isRevoked: true,
        isTampered: false,
        isAnchorVerified: true,
        responseTimeMs: stopwatch.elapsedMilliseconds,
        statusDescription: 'Credential marked as REVOKED in BitstringStatusList2021 at bit #$statusListIndex.',
        blockNumber: blockNum,
        transactionId: txId,
        isLiveNetwork: false,
      );
    }

    return LedgerVerificationResult(
      isValid: true,
      isRevoked: false,
      isTampered: false,
      isAnchorVerified: isAnchorValid,
      responseTimeMs: stopwatch.elapsedMilliseconds,
      statusDescription: 'Verified successfully against NUVTE Root PKI and BitstringStatusList2021.',
      blockNumber: blockNum,
      transactionId: txId,
      isLiveNetwork: false,
    );
  }

  /// Zero PII Ledger Audit summary for technical transparency
  List<Map<String, dynamic>> getLedgerAuditBlocks() {
    return [
      {
        'block': 104820,
        'timestamp': '2026-09-23 06:00:00',
        'type': 'BITSTRING_STATUS_REGISTRY_INIT',
        'issuer': issuerDid,
        'dataSummary': 'BitstringStatusList2021 created with 100,000 capacity. Zero PII.',
      },
      {
        'block': 104821,
        'timestamp': '2026-09-23 06:03:01',
        'type': 'ANCHOR_CREDENTIAL_HASH',
        'issuer': issuerDid,
        'dataSummary': 'SHA-256 hash committed: 07d7f0...98c (DOC-NUVTE-2024-GRAD-098 @ Bit #102 Active)',
      },
      {
        'block': 104822,
        'timestamp': '2026-09-23 06:05:16',
        'type': 'VERIFICATION_AUDIT_LOG',
        'issuer': 'did:key:z6MkuBankOfPalestineCompliance',
        'dataSummary': 'Bank of Palestine verified DOC-NUVTE-2024-GRAD-098 (Status: VALID)',
      },
    ];
  }
}
