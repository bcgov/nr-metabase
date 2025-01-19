const crypto = require('crypto');

function encrypt(plaintext, key, iv) {
  const cipher = crypto.createCipheriv('aes-256-cbc', Buffer.from(key), Buffer.from(iv));
  let encrypted = cipher.update(plaintext, 'utf8', 'base64');
  encrypted += cipher.final('base64');
  return encrypted;
}

function decrypt(encryptedText, key, iv) {
  const decipher = crypto.createDecipheriv('aes-256-cbc', Buffer.from(key), Buffer.from(iv), { 'padding': 'pkcs7' });
  let decrypted = decipher.update(encryptedText, 'base64', 'utf8');
  decrypted += decipher.final('utf8');
  return decrypted;
}

if (process.argv.length < 4) {
  console.error('Usage: node encrypt.js <key> <iv>');
  process.exit(1);
}

const key = process.argv[2];
const iv = process.argv[3];
const plaintext = 'abc';

const encryptedText = encrypt(plaintext, key, iv);
console.log('Encrypted:', encryptedText);

const decryptedText = decrypt(encryptedText, key, iv);
console.log('Decrypted:', decryptedText);
