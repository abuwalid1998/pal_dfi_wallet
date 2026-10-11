enum ContractDeploymentStatus {
  draft,
  deploying,
  deployed,
  deprecated,
}

class SmartContractDefinition {
  final String contractId;
  final String institutionId;
  final String institutionNameEn;
  final String institutionNameAr;
  final String nameEn;
  final String nameAr;
  final String descriptionEn;
  final String descriptionAr;
  final String version;
  final String channel;
  final String endorsementPolicy;
  final List<String> schemaAttributes;
  final int startingBitIndex;
  ContractDeploymentStatus status;
  DateTime? deployedAt;
  String? deployedBy;
  String? deployTxId;
  int? deployBlockNumber;

  SmartContractDefinition({
    required this.contractId,
    required this.institutionId,
    required this.institutionNameEn,
    required this.institutionNameAr,
    required this.nameEn,
    required this.nameAr,
    required this.descriptionEn,
    required this.descriptionAr,
    this.version = '1.0.0',
    this.channel = 'nuvte-academic-channel',
    this.endorsementPolicy = "OR('Org1MSP.peer', 'Org2MSP.peer')",
    required this.schemaAttributes,
    this.startingBitIndex = 200,
    this.status = ContractDeploymentStatus.draft,
    this.deployedAt,
    this.deployedBy,
    this.deployTxId,
    this.deployBlockNumber,
  });

  bool get isDeployed => status == ContractDeploymentStatus.deployed;

  Map<String, dynamic> toJson() => {
    'contractId': contractId,
    'institutionId': institutionId,
    'institutionNameEn': institutionNameEn,
    'institutionNameAr': institutionNameAr,
    'nameEn': nameEn,
    'nameAr': nameAr,
    'descriptionEn': descriptionEn,
    'descriptionAr': descriptionAr,
    'version': version,
    'channel': channel,
    'endorsementPolicy': endorsementPolicy,
    'schemaAttributes': schemaAttributes,
    'startingBitIndex': startingBitIndex,
    'status': status.name,
    'deployedAt': deployedAt?.toIso8601String(),
    'deployedBy': deployedBy,
    'deployTxId': deployTxId,
    'deployBlockNumber': deployBlockNumber,
  };
}
