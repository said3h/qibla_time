const path = require('path');
const dotenv = require('dotenv');

function loadScriptEnv() {
  const projectRoot = path.resolve(__dirname, '..');
  const candidates = [
    path.join(projectRoot, '.env.local'),
    path.join(projectRoot, '.env'),
  ];

  for (const envPath of candidates) {
    dotenv.config({ path: envPath, override: false });
  }
}

module.exports = { loadScriptEnv };
