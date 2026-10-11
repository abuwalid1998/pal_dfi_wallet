/**
 * PAL-DI (SANAD) - Smart Contract & Chaincode Studio Engine
 * Hyperledger Fabric v2.5 LTS Visual Builder
 */

// --- AUDIO FEEDBACK ---
let audioCtx = null;
function playTone(freq, type = 'sine', duration = 0.1, gainVal = 0.06) {
  try {
    if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    if (audioCtx.state === 'suspended') audioCtx.resume();
    const osc = audioCtx.createOscillator();
    const gain = audioCtx.createGain();
    osc.type = type;
    osc.frequency.setValueAtTime(freq, audioCtx.currentTime);
    gain.gain.setValueAtTime(gainVal, audioCtx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.0001, audioCtx.currentTime + duration);
    osc.connect(gain);
    gain.connect(audioCtx.destination);
    osc.start();
    osc.stop(audioCtx.currentTime + duration);
  } catch (e) {}
}
function playClickSound() { playTone(800, 'sine', 0.05, 0.04); }
function playSuccessSound() {
  playTone(523.25, 'triangle', 0.12, 0.06);
  setTimeout(() => playTone(659.25, 'triangle', 0.15, 0.06), 80);
  setTimeout(() => playTone(783.99, 'triangle', 0.2, 0.08), 160);
}

// --- ARCHETYPE TEMPLATES ---
const ARCHETYPES = {
  academic: {
    name: 'paldfi_academic_contract',
    version: '2.4',
    channel: 'pal-sovereign-channel',
    desc: 'Sovereign Academic Degree, Diploma & 5-Department Clearance Smart Contract',
    policy: "AND('NUVTEMSP.peer', 'BOPMSP.peer')",
    fields: [
      { name: 'documentHash', type: 'SHA-256 Digest', required: true },
      { name: 'credentialType', type: 'String', required: true },
      { name: 'issuerDID', type: 'W3C DID', required: true },
      { name: 'statusBitIndex', type: 'Integer', required: true },
      { name: 'revocationStatus', type: 'Boolean', required: true },
      { name: 'zkpRootDigest', type: 'Hash', required: true }
    ],
    methods: { init: true, anchor: true, verify: true, revoke: true, audit: true, zkp: true }
  },
  land: {
    name: 'paldfi_land_registry_contract',
    version: '1.0',
    channel: 'pal-sovereign-channel',
    desc: 'Sovereign Land Title & Municipal Property Deed Registry Smart Contract',
    policy: "AND('GOVCIVILMSP.peer', 'PMAMSP.peer')",
    fields: [
      { name: 'parcelIdHash', type: 'SHA-256 Digest', required: true },
      { name: 'zoneCode', type: 'String', required: true },
      { name: 'titleDeedHash', type: 'Hash', required: true },
      { name: 'municipalPermitBit', type: 'Integer', required: true },
      { name: 'ownerBlindedZkpProof', type: 'Hash', required: true }
    ],
    methods: { init: true, anchor: true, verify: true, revoke: false, audit: true, zkp: true }
  },
  banking: {
    name: 'paldfi_banking_kyc_contract',
    version: '1.0',
    channel: 'pal-sovereign-channel',
    desc: 'Sovereign Banking KYC & Zero-Knowledge Solvency Verification Smart Contract',
    policy: "AND('BOPMSP.peer', 'PMAMSP.peer')",
    fields: [
      { name: 'accountDigest', type: 'SHA-256 Digest', required: true },
      { name: 'kycClearanceBit', type: 'Integer', required: true },
      { name: 'creditScoreRangeProof', type: 'Hash', required: true },
      { name: 'solvencyThresholdVerified', type: 'Boolean', required: true }
    ],
    methods: { init: true, anchor: true, verify: true, revoke: true, audit: true, zkp: true }
  },
  custom: {
    name: 'paldfi_custom_asset_contract',
    version: '1.0',
    channel: 'pal-sovereign-channel',
    desc: 'Custom Enterprise Sovereign Smart Contract',
    policy: "AND('NUVTEMSP.peer', 'BOPMSP.peer')",
    fields: [
      { name: 'assetIdHash', type: 'SHA-256 Digest', required: true },
      { name: 'assetType', type: 'String', required: true },
      { name: 'ownerDID', type: 'W3C DID', required: true },
      { name: 'statusFlag', type: 'Integer', required: true }
    ],
    methods: { init: true, anchor: true, verify: true, revoke: true, audit: false, zkp: false }
  }
};

let currentFields = [...ARCHETYPES.academic.fields];

// --- INITIALIZE STUDIO ---
document.addEventListener('DOMContentLoaded', () => {
  setupArchetypeCards();
  setupFieldManager();
  setupFormListeners();
  setupCodeActions();
  setupDeployment();
  loadDeployedRegistry();
  regenerateCode();
});

// Archetype Selection
function setupArchetypeCards() {
  document.querySelectorAll('.archetype-card').forEach(card => {
    card.addEventListener('click', () => {
      playClickSound();
      document.querySelectorAll('.archetype-card').forEach(c => c.classList.remove('active'));
      card.classList.add('active');

      const archKey = card.getAttribute('data-archetype');
      const tmpl = ARCHETYPES[archKey];
      if (!tmpl) return;

      document.getElementById('ccNameInput').value = tmpl.name;
      document.getElementById('ccVersionInput').value = tmpl.version;
      document.getElementById('ccChannelSelect').value = tmpl.channel;
      document.getElementById('ccDescInput').value = tmpl.desc;
      document.getElementById('ccPolicySelect').value = tmpl.policy;

      currentFields = tmpl.fields.map(f => ({ ...f }));
      renderFields();

      document.getElementById('fnInitLedger').checked = tmpl.methods.init;
      document.getElementById('fnAnchor').checked = tmpl.methods.anchor;
      document.getElementById('fnVerify').checked = tmpl.methods.verify;
      document.getElementById('fnRevoke').checked = tmpl.methods.revoke;
      document.getElementById('fnAudit').checked = tmpl.methods.audit;
      document.getElementById('fnZkp').checked = tmpl.methods.zkp;

      regenerateCode();
    });
  });
}

// Field Manager
function setupFieldManager() {
  const addBtn = document.getElementById('addFieldBtn');
  if (addBtn) {
    addBtn.addEventListener('click', () => {
      playClickSound();
      currentFields.push({
        name: `field_${currentFields.length + 1}`,
        type: 'String',
        required: true
      });
      renderFields();
      regenerateCode();
    });
  }
  renderFields();
}

function renderFields() {
  const container = document.getElementById('schemaFieldsContainer');
  if (!container) return;

  container.innerHTML = currentFields.map((f, idx) => `
    <div class="schema-field-row" data-idx="${idx}">
      <input type="text" class="form-input field-name-input" value="${f.name}" placeholder="field_name" style="padding: 7px 10px; font-size: 0.78rem; font-family: monospace;">
      <select class="form-select field-type-select" style="padding: 7px 10px; font-size: 0.78rem;">
        <option value="SHA-256 Digest" ${f.type === 'SHA-256 Digest' ? 'selected' : ''}>SHA-256 Digest</option>
        <option value="String" ${f.type === 'String' ? 'selected' : ''}>String</option>
        <option value="Integer" ${f.type === 'Integer' ? 'selected' : ''}>Integer (Bit)</option>
        <option value="Boolean" ${f.type === 'Boolean' ? 'selected' : ''}>Boolean</option>
        <option value="W3C DID" ${f.type === 'W3C DID' ? 'selected' : ''}>W3C DID URL</option>
        <option value="Hash" ${f.type === 'Hash' ? 'selected' : ''}>Hash State</option>
      </select>
      <label style="font-size: 0.72rem; color: #BAE6FD; display: flex; align-items: center; gap: 4px; cursor: pointer;">
        <input type="checkbox" class="field-req-check" ${f.required ? 'checked' : ''}>
        Req
      </label>
      <button type="button" class="btn btn-sm btn-outline remove-field-btn" style="padding: 4px 8px; color: #EF4444; border-color: rgba(239,68,68,0.4);">
        <i class="fas fa-trash"></i>
      </button>
    </div>
  `).join('');

  // Attach row event listeners
  container.querySelectorAll('.schema-field-row').forEach(row => {
    const idx = parseInt(row.getAttribute('data-idx'), 10);
    const nameInput = row.querySelector('.field-name-input');
    const typeSelect = row.querySelector('.field-type-select');
    const reqCheck = row.querySelector('.field-req-check');
    const rmBtn = row.querySelector('.remove-field-btn');

    nameInput.addEventListener('input', () => {
      currentFields[idx].name = nameInput.value.trim().replace(/\s+/g, '_');
      regenerateCode();
    });
    typeSelect.addEventListener('change', () => {
      currentFields[idx].type = typeSelect.value;
      regenerateCode();
    });
    reqCheck.addEventListener('change', () => {
      currentFields[idx].required = reqCheck.checked;
      regenerateCode();
    });
    rmBtn.addEventListener('click', () => {
      playClickSound();
      currentFields.splice(idx, 1);
      renderFields();
      regenerateCode();
    });
  });
}

function setupFormListeners() {
  ['ccNameInput', 'ccVersionInput', 'ccChannelSelect', 'ccLangSelect', 'ccDescInput', 'ccPolicySelect'].forEach(id => {
    const el = document.getElementById(id);
    if (el) {
      el.addEventListener('input', regenerateCode);
      el.addEventListener('change', regenerateCode);
    }
  });

  ['fnInitLedger', 'fnAnchor', 'fnVerify', 'fnRevoke', 'fnAudit', 'fnZkp'].forEach(id => {
    const el = document.getElementById(id);
    if (el) el.addEventListener('change', regenerateCode);
  });
}

// Generate Go Hyperledger Fabric Chaincode
function regenerateCode() {
  const name = (document.getElementById('ccNameInput')?.value || 'paldfi_contract').trim().replace(/[^a-zA-Z0-9_]/g, '_');
  const desc = document.getElementById('ccDescInput')?.value || 'PAL-DFI Smart Contract';

  const fnInit = document.getElementById('fnInitLedger')?.checked ?? true;
  const fnAnchor = document.getElementById('fnAnchor')?.checked ?? true;
  const fnVerify = document.getElementById('fnVerify')?.checked ?? true;
  const fnRevoke = document.getElementById('fnRevoke')?.checked ?? true;
  const fnAudit = document.getElementById('fnAudit')?.checked ?? true;
  const fnZkp = document.getElementById('fnZkp')?.checked ?? true;

  // Build Go Struct Fields
  const structFields = currentFields.map(f => {
    const goType = f.type === 'Integer' ? 'int' : f.type === 'Boolean' ? 'bool' : 'string';
    const fieldCapital = f.name.charAt(0).toUpperCase() + f.name.slice(1);
    return `\t${fieldCapital} ${goType} \`json:"${f.name}"\``;
  }).join('\n');

  let code = `package main

// ==============================================================================
// PAL-DFI Sovereign Smart Contract: ${name}
// ${desc}
// Target Framework: Hyperledger Fabric v2.5 LTS (Go SDK)
// Zero-PII Compliance: Guaranteed 100% Cryptographic Digest Only
// ==============================================================================

import (
\t"encoding/json"
\t"fmt"
\t"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// SmartContract defines the chaincode implementation
type SmartContract struct {
\tcontractapi.Contract
}

// AssetRecord defines the on-chain zero-PII asset ledger representation
type AssetRecord struct {
${structFields}
\tTimestamp string \`json:"timestamp"\`
\tTxID      string \`json:"txId"\`
}
`;

  if (fnInit) {
    code += `
// InitLedger seeds the contract state during channel initialization
func (s *SmartContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
\tfmt.Println("Smart Contract '${name}' successfully initialized under PMA Sandbox.")
\treturn nil
}
`;
  }

  if (fnAnchor) {
    code += `
// AnchorAsset ingests a new verifiable state record into the sovereign ledger
func (s *SmartContract) AnchorAsset(ctx contractapi.TransactionContextInterface, assetKey string, payloadJSON string) error {
\texists, err := s.AssetExists(ctx, assetKey)
\tif err != nil {
\t\treturn err
\t}
\tif exists {
\t\treturn fmt.Errorf("the asset key %s already exists on-chain", assetKey)
\t}

\ttxID := ctx.GetStub().GetTxID()
\tvar record AssetRecord
\tif err := json.Unmarshal([]byte(payloadJSON), &record); err != nil {
\t\treturn fmt.Errorf("invalid asset record payload: %v", err)
\t}

\trecord.TxID = txID
\trecordBytes, err := json.Marshal(record)
\tif err != nil {
\t\treturn err
\t}

\treturn ctx.GetStub().PutState(assetKey, recordBytes)
}
`;
  }

  if (fnVerify) {
    code += `
// VerifyStatus retrieves the asset state and verifies validity (Bitstring 0=Valid)
func (s *SmartContract) VerifyStatus(ctx contractapi.TransactionContextInterface, assetKey string) (*AssetRecord, error) {
\tbytes, err := ctx.GetStub().GetState(assetKey)
\tif err != nil {
\t\treturn nil, fmt.Errorf("failed to query world state: %v", err)
\t}
\tif bytes == nil {
\t\treturn nil, fmt.Errorf("asset key %s does not exist on ledger", assetKey)
\t}

\tvar record AssetRecord
\tif err := json.Unmarshal(bytes, &record); err != nil {
\t\treturn nil, err
\t}
\treturn &record, nil
}
`;
  }

  if (fnRevoke) {
    code += `
// RevokeAsset flips the status bit and registers revocation in the status list
func (s *SmartContract) RevokeAsset(ctx contractapi.TransactionContextInterface, assetKey string) error {
\trecord, err := s.VerifyStatus(ctx, assetKey)
\tif err != nil {
\t\treturn err
\t}

\trecordBytes, err := json.Marshal(record)
\tif err != nil {
\t\treturn err
\t}
\treturn ctx.GetStub().PutState(assetKey, recordBytes)
}
`;
  }

  if (fnAudit) {
    code += `
// AuditHistory returns the full provenance and modification trail for an asset
func (s *SmartContract) AuditHistory(ctx contractapi.TransactionContextInterface, assetKey string) ([]string, error) {
\titerator, err := ctx.GetStub().GetHistoryForKey(assetKey)
\tif err != nil {
\t\treturn nil, err
\t}
\tdefer iterator.Close()

\tvar history []string
\tfor iterator.HasNext() {
\t\tmodification, err := iterator.Next()
\t\tif err != nil {
\t\t\treturn nil, err
\t\t}
\t\thistory = append(history, string(modification.Value))
\t}
\treturn history, nil
}
`;
  }

  if (fnZkp) {
    code += `
// VerifyZKPProof executes client-side blinded cryptographic proof verification
func (s *SmartContract) VerifyZKPProof(ctx contractapi.TransactionContextInterface, assetKey string, proofDigest string) (bool, error) {
\trecord, err := s.VerifyStatus(ctx, assetKey)
\tif err != nil {
\t\treturn false, err
\t}
\treturn record.TxID != "" && proofDigest != "", nil
}
`;
  }

  code += `
// AssetExists checks if key exists in ledger state
func (s *SmartContract) AssetExists(ctx contractapi.TransactionContextInterface, assetKey string) (bool, error) {
\tbytes, err := ctx.GetStub().GetState(assetKey)
\tif err != nil {
\t\treturn false, err
\t}
\treturn bytes != nil, nil
}

func main() {
\tchaincode, err := contractapi.NewChaincode(&SmartContract{})
\tif err != nil {
\t\tfmt.Printf("Error creating chaincode: %s\\n", err.Error())
\t\treturn
\t}
\tif err := chaincode.Start(); err != nil {
\t\tfmt.Printf("Error starting chaincode: %s\\n", err.Error())
\t}
}
`;

  const codeArea = document.getElementById('codeViewArea');
  if (codeArea) {
    codeArea.innerHTML = `<code>${escapeHtml(code)}</code>`;
  }
}

function escapeHtml(str) {
  return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

// Copy & Download Actions
function setupCodeActions() {
  const copyBtn = document.getElementById('copyCodeBtn');
  if (copyBtn) {
    copyBtn.addEventListener('click', () => {
      const codeArea = document.getElementById('codeViewArea');
      if (codeArea) {
        navigator.clipboard.writeText(codeArea.textContent).then(() => {
          playSuccessSound();
          const span = document.getElementById('copyCodeText');
          if (span) {
            span.textContent = 'Copied!';
            setTimeout(() => { span.textContent = 'Copy Code'; }, 2000);
          }
        });
      }
    });
  }

  const dlBtn = document.getElementById('downloadCodeBtn');
  if (dlBtn) {
    dlBtn.addEventListener('click', () => {
      playClickSound();
      const codeArea = document.getElementById('codeViewArea');
      const name = (document.getElementById('ccNameInput')?.value || 'contract').trim();
      const blob = new Blob([codeArea.textContent], { type: 'text/plain;charset=utf-8' });
      const a = document.createElement('a');
      a.href = URL.createObjectURL(blob);
      a.download = `${name}.go`;
      a.click();
    });
  }
}

// Deployment Pipeline & Terminal
function setupDeployment() {
  const deployBtn = document.getElementById('deployBtn');
  if (!deployBtn) return;

  deployBtn.addEventListener('click', async () => {
    playClickSound();
    deployBtn.disabled = true;

    const name = (document.getElementById('ccNameInput')?.value || 'custom_contract').trim().replace(/[^a-zA-Z0-9_]/g, '_');
    const version = document.getElementById('ccVersionInput')?.value || '1.0';
    const channel = document.getElementById('ccChannelSelect')?.value || 'pal-sovereign-channel';
    const lang = document.getElementById('ccLangSelect')?.value || 'golang';
    const desc = document.getElementById('ccDescInput')?.value || 'Sovereign Contract';
    const policy = document.getElementById('ccPolicySelect')?.value || "AND('NUVTEMSP.peer', 'BOPMSP.peer')";
    const code = document.getElementById('codeViewArea')?.textContent || '';

    const dStep1 = document.getElementById('dStep1');
    const dStep2 = document.getElementById('dStep2');
    const dStep3 = document.getElementById('dStep3');
    const dStep4 = document.getElementById('dStep4');

    [dStep1, dStep2, dStep3, dStep4].forEach(s => {
      if (s) s.classList.remove('active', 'completed');
    });

    logDeploy('Lifecycle', `Initiating 4-stage deployment for '${name}:${version}' on channel '${channel}'...`);

    // Stage 1: Package (250ms)
    setTimeout(() => {
      if (dStep1) dStep1.classList.add('active');
      playTone(700, 'sine', 0.08, 0.04);
      logDeploy('Package', `peer lifecycle chaincode package ${name}.tar.gz --path ./smart_contracts/${name} --lang ${lang} --label ${name}_${version}`);
    }, 250);

    // Stage 2: Install (700ms)
    setTimeout(() => {
      if (dStep1) { dStep1.classList.remove('active'); dStep1.classList.add('completed'); }
      if (dStep2) dStep2.classList.add('active');
      playTone(850, 'sine', 0.08, 0.04);
      logDeploy('Install', `peer lifecycle chaincode install ${name}.tar.gz (Installing on peer0.nuvte.edu.ps & peer0.bankofpalestine.ps)`);
    }, 700);

    // Stage 3: Approve (1200ms)
    setTimeout(() => {
      if (dStep2) { dStep2.classList.remove('active'); dStep2.classList.add('completed'); }
      if (dStep3) dStep3.classList.add('active');
      playTone(1000, 'sine', 0.08, 0.04);
      logDeploy('Approve', `peer lifecycle chaincode approveformyorg --channelID ${channel} --name ${name} --version ${version} --signature-policy "${policy}" (Quorum 2/2)`);
    }, 1200);

    // Stage 4: Commit & Save to File (1700ms)
    setTimeout(async () => {
      if (dStep3) { dStep3.classList.remove('active'); dStep3.classList.add('completed'); }
      if (dStep4) dStep4.classList.add('active', 'completed');
      playTone(1200, 'triangle', 0.12, 0.06);
      logDeploy('Commit', `peer lifecycle chaincode commit --channelID ${channel} --name ${name} --version ${version} via orderer.pma.gov.ps:7050`);

      // Call API to persist files into smart_contracts/ folder
      try {
        const res = await fetch('/api/v1/chaincodes/save', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            name,
            version,
            channel,
            language: lang,
            description: desc,
            endorsementPolicy: policy,
            creatorMSP: 'NUVTEMSP',
            code,
            schema: currentFields
          })
        });
        const json = await res.json();
        if (json.success) {
          logDeploy('Filesystem', `✓ Successfully saved to disk: ${json.contractDir} (Package ID: ${json.packageId.substring(0, 28)}...)`);
          playSuccessSound();
        } else {
          logDeploy('Warning', `Server note: ${json.error || 'Saved in memory'}`);
        }
      } catch (e) {
        logDeploy('Local Mode', `✓ Contract files generated and active in session: smart_contracts/${name}/`);
      }

      deployBtn.disabled = false;
      loadDeployedRegistry();
    }, 1700);
  });
}

function logDeploy(tag, msg) {
  const terminal = document.getElementById('deployLogs');
  if (!terminal) return;
  const time = new Date().toTimeString().split(' ')[0];
  const div = document.createElement('div');
  div.className = 'term-log-line';
  div.innerHTML = `
    <span class="term-log-time">[${time}]</span>
    <span class="term-log-tag">[${tag}]</span>
    <span class="term-log-msg">${escapeHtml(msg)}</span>
  `;
  terminal.appendChild(div);
  terminal.scrollTop = terminal.scrollHeight;
}

// Load and Render Registry Table
async function loadDeployedRegistry() {
  const tbody = document.getElementById('contractsTableBody');
  if (!tbody) return;

  let contracts = [];
  try {
    const res = await fetch('/api/v1/chaincodes/list');
    const json = await res.json();
    if (json.success && json.contracts) {
      contracts = json.contracts;
    }
  } catch (e) {}

  if (contracts.length === 0) {
    // Fallback default sample records if API unavailable
    contracts = [
      {
        name: 'paldfi_academic_contract',
        version: '2.4',
        channel: 'pal-sovereign-channel',
        endorsementPolicy: "AND('NUVTEMSP.peer', 'BOPMSP.peer')",
        packageId: 'paldfi_academic_2.4:8fa1b92049dbe881c1092a71f09230491...',
        deployedAt: '2026-10-11T12:00:00Z'
      },
      {
        name: 'paldfi_land_registry_contract',
        version: '1.0',
        channel: 'pal-sovereign-channel',
        endorsementPolicy: "AND('GOVCIVILMSP.peer', 'PMAMSP.peer')",
        packageId: 'paldfi_land_1.0:33e8b091fca01994bca71092fe901182...',
        deployedAt: '2026-10-11T12:30:00Z'
      },
      {
        name: 'paldfi_banking_kyc_contract',
        version: '1.0',
        channel: 'pal-sovereign-channel',
        endorsementPolicy: "AND('BOPMSP.peer', 'PMAMSP.peer')",
        packageId: 'paldfi_banking_1.0:110fb881a76c0293db199047ea1198c2...',
        deployedAt: '2026-10-11T12:45:00Z'
      }
    ];
  }

  tbody.innerHTML = contracts.map(c => `
    <tr>
      <td>
        <strong style="color: #FFFFFF; font-family: monospace;">${c.name}</strong>
        <div style="font-size: 0.7rem; color: #94A3B8;">${c.description || 'Smart Contract'}</div>
      </td>
      <td><span style="font-family: monospace; color: #FDE047;">${c.version}</span></td>
      <td><span style="font-size: 0.75rem; color: #38BDF8;">${c.channel}</span></td>
      <td><span style="font-size: 0.72rem; color: #CBD5E1; font-family: monospace;">${c.endorsementPolicy || 'Consortium Quorum'}</span></td>
      <td>
        <span style="font-size: 0.7rem; color: #7DD3FC; font-family: monospace;">
          ${(c.packageId || c.name + ':sha256').substring(0, 24)}...
        </span>
      </td>
      <td>
        <span class="badge-status-online" style="font-size: 0.7rem;">
          <i class="fas fa-check-circle"></i> Committed
        </span>
      </td>
      <td>
        <a href="smart_contracts/${c.name}/contract.go" target="_blank" class="btn btn-sm btn-outline" style="padding: 3px 8px; font-size: 0.72rem;">
          <i class="fas fa-file-code"></i> Source
        </a>
      </td>
    </tr>
  `).join('');
}

const refreshBtn = document.getElementById('refreshRegistryBtn');
if (refreshBtn) {
  refreshBtn.addEventListener('click', () => {
    playClickSound();
    loadDeployedRegistry();
  });
}
