const http = require('http');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const PORT = 9000;
const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.go': 'text/plain; charset=utf-8',
  '.md': 'text/markdown; charset=utf-8'
};

const server = http.createServer((req, res) => {
  // CORS Headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  // --- API: Save & Deploy Smart Contract to smart_contracts/ folder ---
  if (req.method === 'POST' && req.url === '/api/v1/chaincodes/save') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      try {
        const data = JSON.parse(body);
        const name = (data.name || 'custom_contract').trim().replace(/[^a-zA-Z0-9_-]/g, '_');
        const contractDir = path.join(__dirname, 'smart_contracts', name);

        if (!fs.existsSync(contractDir)) {
          fs.mkdirSync(contractDir, { recursive: true });
        }

        const packageId = `${name}_${data.version || '1.0'}:` + crypto.createHash('sha256').update(data.code || name).digest('hex');

        const metadata = {
          name: name,
          version: data.version || '1.0',
          sequence: data.sequence || 1,
          channel: data.channel || 'pal-sovereign-channel',
          language: data.language || 'golang',
          description: data.description || 'Auto-generated no-code smart contract',
          endorsementPolicy: data.endorsementPolicy || "AND('NUVTEMSP.peer', 'BOPMSP.peer')",
          creatorMSP: data.creatorMSP || 'NUVTEMSP',
          packageId: packageId,
          zeroPiiCompliance: true,
          deployedAt: new Date().toISOString(),
          schema: data.schema || []
        };

        fs.writeFileSync(path.join(contractDir, 'metadata.json'), JSON.stringify(metadata, null, 2), 'utf8');
        fs.writeFileSync(path.join(contractDir, 'contract.go'), data.code || '// Empty contract', 'utf8');

        // Sync to PalDIMicroService smart_contracts folder if exists
        const siblingPath = path.join(__dirname, '..', 'PalDIMicroService', 'smart_contracts', name);
        try {
          if (!fs.existsSync(siblingPath)) fs.mkdirSync(siblingPath, { recursive: true });
          fs.writeFileSync(path.join(siblingPath, 'metadata.json'), JSON.stringify(metadata, null, 2), 'utf8');
          fs.writeFileSync(path.join(siblingPath, 'contract.go'), data.code || '// Empty contract', 'utf8');
        } catch (e) {}

        res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({
          success: true,
          message: `Smart Contract '${name}' successfully generated & saved to smart_contracts/${name}/`,
          packageId: packageId,
          contractDir: `smart_contracts/${name}/`,
          metadata: metadata
        }));
      } catch (err) {
        res.writeHead(400, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({ success: false, error: err.message }));
      }
    });
    return;
  }

  // --- API: List Saved Smart Contracts ---
  if (req.method === 'GET' && req.url === '/api/v1/chaincodes/list') {
    try {
      const baseDir = path.join(__dirname, 'smart_contracts');
      const list = [];
      if (fs.existsSync(baseDir)) {
        const dirs = fs.readdirSync(baseDir, { withFileTypes: true });
        for (const d of dirs) {
          if (d.isDirectory()) {
            const metaFile = path.join(baseDir, d.name, 'metadata.json');
            if (fs.existsSync(metaFile)) {
              try {
                list.push(JSON.parse(fs.readFileSync(metaFile, 'utf8')));
              } catch (e) {}
            }
          }
        }
      }
      res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ success: true, contracts: list }));
    } catch (e) {
      res.writeHead(500, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ success: false, error: e.message }));
    }
    return;
  }

  // --- API: MoI National ID CSV Database Endpoints ---
  const csvFilePath = path.join(__dirname, 'data', 'moi_national_ids.csv');

  function parseMoiCsv() {
    if (!fs.existsSync(csvFilePath)) return [];
    const content = fs.readFileSync(csvFilePath, 'utf8');
    const lines = content.trim().split('\n').map(l => l.trim()).filter(Boolean);
    if (lines.length < 2) return [];
    const headers = lines[0].split(',').map(h => h.trim());
    return lines.slice(1).map(line => {
      const vals = line.split(',').map(v => v.trim());
      const obj = {};
      headers.forEach((h, idx) => {
        obj[h] = vals[idx] !== undefined ? vals[idx] : '';
      });
      return obj;
    });
  }

  function serializeMoiCsv(records) {
    const headers = [
      'application_id', 'national_id_number', 'did', 'applicant_name_ar', 'applicant_name_en',
      'dob', 'age', 'birth_place', 'gender', 'blood_type', 'parent_id', 'parent_name',
      'status', 'base_fee_jod', 'penalty_fee_jod', 'total_fee_jod', 'payment_status',
      'payment_tx_id', 'biometric_hash', 'liveness_score', 'issued_at', 'fabric_tx_id', 'qr_signature'
    ];
    const rows = [headers.join(',')];
    records.forEach(r => {
      const row = headers.map(h => (r[h] !== undefined ? String(r[h]).replace(/,/g, ' ') : ''));
      rows.push(row.join(','));
    });
    return rows.join('\n') + '\n';
  }

  // GET: Read all MoI records from CSV
  if (req.method === 'GET' && req.url === '/api/v1/moi/records') {
    try {
      const records = parseMoiCsv();
      res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ success: true, count: records.length, records }));
    } catch (e) {
      res.writeHead(500, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ success: false, error: e.message }));
    }
    return;
  }

  // GET: Raw CSV file download
  if (req.method === 'GET' && req.url === '/api/v1/moi/export-csv') {
    try {
      if (!fs.existsSync(csvFilePath)) {
        res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
        res.end('CSV database file not found');
        return;
      }
      const csvData = fs.readFileSync(csvFilePath, 'utf8');
      res.writeHead(200, {
        'Content-Type': 'text/csv; charset=utf-8',
        'Content-Disposition': 'attachment; filename="moi_national_ids.csv"'
      });
      res.end(csvData);
    } catch (e) {
      res.writeHead(500, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('Error reading CSV: ' + e.message);
    }
    return;
  }

  // POST: Create / Append new MoI Application Record to CSV
  if (req.method === 'POST' && req.url === '/api/v1/moi/apply') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      try {
        const payload = JSON.parse(body);
        const dataDir = path.join(__dirname, 'data');
        if (!fs.existsSync(dataDir)) fs.mkdirSync(dataDir, { recursive: true });

        const records = parseMoiCsv();
        const existingIdx = records.findIndex(r => r.application_id === payload.application_id);
        if (existingIdx >= 0) {
          records[existingIdx] = { ...records[existingIdx], ...payload };
        } else {
          records.push(payload);
        }

        fs.writeFileSync(csvFilePath, serializeMoiCsv(records), 'utf8');

        // Also sync to PalDIMicroService/data/
        const microDataDir = path.join(__dirname, 'PalDIMicroService', 'data');
        if (fs.existsSync(path.join(__dirname, 'PalDIMicroService'))) {
          if (!fs.existsSync(microDataDir)) fs.mkdirSync(microDataDir, { recursive: true });
          fs.writeFileSync(path.join(microDataDir, 'moi_national_ids.csv'), serializeMoiCsv(records), 'utf8');
        }

        res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({
          success: true,
          message: `Application ${payload.application_id} saved to CSV database`,
          record: payload
        }));
      } catch (err) {
        res.writeHead(400, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({ success: false, error: err.message }));
      }
    });
    return;
  }

  // POST: Settle fee & Issue National ID (transitions to PAID & ISSUED in CSV)
  if (req.method === 'POST' && req.url === '/api/v1/moi/settle') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      try {
        const payload = JSON.parse(body);
        const records = parseMoiCsv();
        const idx = records.findIndex(r => r.application_id === payload.application_id);

        if (idx === -1) {
          // If not existing, append as completed
          records.push(payload);
        } else {
          records[idx] = {
            ...records[idx],
            ...payload,
            status: 'ISSUED',
            payment_status: 'SETTLED',
            issued_at: new Date().toISOString()
          };
        }

        fs.writeFileSync(csvFilePath, serializeMoiCsv(records), 'utf8');

        // Sync to PalDIMicroService/data/
        const microDataDir = path.join(__dirname, 'PalDIMicroService', 'data');
        if (fs.existsSync(path.join(__dirname, 'PalDIMicroService'))) {
          if (!fs.existsSync(microDataDir)) fs.mkdirSync(microDataDir, { recursive: true });
          fs.writeFileSync(path.join(microDataDir, 'moi_national_ids.csv'), serializeMoiCsv(records), 'utf8');
        }

        res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({
          success: true,
          message: `National ID successfully issued and recorded in CSV registry`,
          record: records[idx >= 0 ? idx : records.length - 1]
        }));
      } catch (err) {
        res.writeHead(400, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({ success: false, error: err.message }));
      }
    });
    return;
  }

  // --- Static File Serving ---
  let reqPath = decodeURI(req.url.split('?')[0]);
  if (reqPath === '/' || reqPath === '') reqPath = '/index.html';

  const filePath = path.join(__dirname, reqPath);
  const ext = path.extname(filePath).toLowerCase();
  const contentType = MIME_TYPES[ext] || 'application/octet-stream';

  fs.readFile(filePath, (err, content) => {
    if (err) {
      if (err.code === 'ENOENT') {
        res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
        res.end('404 Not Found: ' + reqPath);
      } else {
        res.writeHead(500, { 'Content-Type': 'text/plain; charset=utf-8' });
        res.end('500 Server Error: ' + err.code);
      }
    } else {
      res.writeHead(200, { 
        'Content-Type': contentType,
        'Cache-Control': 'no-cache, no-store, must-revalidate'
      });
      res.end(content);
    }
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`PAL-DI Local Server running at http://localhost:${PORT}/`);
});
