const nodemailer = require('nodemailer');
const env = require('../../config/env');

// SMTP transport (US-21), created the first time it is needed.
// Tests replace sendMail with a fake (jest.spyOn): `npm test` never sends a real email.
// Credentials come only from backend/.env; nothing here is logged.

let transport;

/** True when the server has what it needs to send (host, sender and, in test mode, the test inbox). */
function isConfigured() {
  if (!env.SMTP_HOST || !env.MAIL_FROM) return false;
  if (env.MAIL_MODE === 'test' && !env.MAIL_TEST_TO) return false;
  return true;
}

function getTransport() {
  if (!transport) {
    transport = nodemailer.createTransport({
      host: env.SMTP_HOST,
      port: env.SMTP_PORT,
      secure: env.SMTP_PORT === 465, // 465 = TLS from the start; 587 = STARTTLS
      auth: env.SMTP_USER ? { user: env.SMTP_USER, pass: env.SMTP_PASS } : undefined,
      connectionTimeout: 15000,
      greetingTimeout: 15000,
      socketTimeout: 30000,
    });
  }
  return transport;
}

/** Sends one message ({from, to, cc, replyTo, subject, text, attachments}). */
async function sendMail(message) {
  return getTransport().sendMail(message);
}

module.exports = { isConfigured, sendMail };
