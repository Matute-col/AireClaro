// Runs before every test file, before the app is loaded.
//
// Safety rule: tests must NEVER touch the main database.
// - DATABASE_URL is replaced with TEST_DATABASE_URL (a Neon branch only for tests).
// - If TEST_DATABASE_URL is missing, DATABASE_URL is set to '' so no test can reach
//   the main database; tests that need the database are skipped (see helpers/db.js).
// - If both URLs point to the same host, the run stops.
// Connection strings are never printed.
const fs = require('fs');
const os = require('os');
const path = require('path');
const dotenv = require('dotenv');

const envFile = path.join(__dirname, '..', '.env');
const fileVars = fs.existsSync(envFile) ? dotenv.parse(fs.readFileSync(envFile)) : {};

const mainUrl = fileVars.DATABASE_URL || '';
const testUrl = process.env.TEST_DATABASE_URL || fileVars.TEST_DATABASE_URL || '';

function hostOf(url) {
  try {
    return new URL(url).hostname;
  } catch {
    throw new Error('TEST_DATABASE_URL o DATABASE_URL no tienen un formato de URL válido');
  }
}

if (testUrl && mainUrl && hostOf(testUrl) === hostOf(mainUrl)) {
  throw new Error(
    'TEST_DATABASE_URL apunta al mismo servidor que DATABASE_URL. ' +
      'Usa la rama "test" de Neon para no ensuciar la base principal.',
  );
}

// Set before dotenv runs in src/config/env.js; dotenv never overrides existing variables.
process.env.NODE_ENV = 'test';
process.env.DATABASE_URL = testUrl;
process.env.TEST_DB_VERIFIED = testUrl ? 'true' : 'false';
process.env.JWT_SECRET = 'test-secret-only-for-jest-0123456789abcdef';
process.env.JWT_EXPIRES_IN = '7d';
process.env.MAIL_MODE = 'test';
process.env.LOG_ERROR_DETAILS = 'false';
// Evidence uploads go to a temporary folder, never to backend/uploads/.
process.env.UPLOAD_DIR = path.join(os.tmpdir(), 'aireclaro-test-uploads');
// Email (US-21): fake values so the sending can be tested. Tests replace the SMTP
// transport with a fake: no real email is ever sent from jest.
process.env.MAIL_TEST_TO = 'buzon-prueba@example.com';
process.env.MAIL_FROM = 'AireClaro <no-responder@example.com>';
process.env.SMTP_HOST = 'smtp.example.invalid';
process.env.SMTP_USER = '';
process.env.SMTP_PASS = '';
