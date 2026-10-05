const https = require('https');
const fs = require('fs');
const path = require('path');

const modelsDir = path.join(__dirname, 'models');
const websiteModelsDir = path.join(__dirname, 'website', 'models');
const docsModelsDir = path.join(__dirname, 'docs', 'models');

[modelsDir, websiteModelsDir, docsModelsDir].forEach(dir => {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
});

const files = [
  'tiny_face_detector_model-weights_manifest.json',
  'tiny_face_detector_model-shard1',
  'face_landmark_68_model-weights_manifest.json',
  'face_landmark_68_model-shard1',
  'face_expression_model-weights_manifest.json',
  'face_expression_model-shard1',
  'face_recognition_model-weights_manifest.json',
  'face_recognition_model-shard1',
  'face_recognition_model-shard2'
];

const baseUrl = 'https://raw.githubusercontent.com/justadudewhohacks/face-api.js/master/weights/';

function downloadFile(file) {
  return new Promise((resolve, reject) => {
    const dest = path.join(modelsDir, file);
    const fileStream = fs.createWriteStream(dest);
    https.get(baseUrl + file, (response) => {
      if (response.statusCode === 200) {
        response.pipe(fileStream);
        fileStream.on('finish', () => {
          fileStream.close(() => {
            // copy to website/models and docs/models
            fs.copyFileSync(dest, path.join(websiteModelsDir, file));
            fs.copyFileSync(dest, path.join(docsModelsDir, file));
            console.log(`Successfully downloaded: ${file}`);
            resolve();
          });
        });
      } else {
        fileStream.close();
        fs.unlink(dest, () => {});
        console.warn(`Failed downloading ${file} with status ${response.statusCode}`);
        resolve(); // don't crash
      }
    }).on('error', (err) => {
      fileStream.close();
      console.warn(`Error downloading ${file}: ${err.message}`);
      resolve();
    });
  });
}

async function run() {
  for (const f of files) {
    await downloadFile(f);
  }
  console.log('Finished downloading face models!');
}

run();
