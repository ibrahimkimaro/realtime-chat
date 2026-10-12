/**
 * Token generator helper for Phoenix Realtime Chat.
 * Use this in your Node.js backend (Express, Fastify, NestJS)
 * to generate connection tokens for your frontend clients.
 */
const crypto = require("crypto");

function generateChatToken(userId, username, name, isAdmin = false, secretKey = "dev-only-change-me", ttlSeconds = 3600) {
  const claims = {
    sub: String(userId),
    name: name,
    username: username,
    admin: Boolean(isAdmin),
    exp: Math.floor(Date.now() / 1000) + ttlSeconds,
  };
  const part = Buffer.from(JSON.stringify(claims)).toString("base64url");
  const sig = crypto.createHmac("sha256", secretKey).update(`chat.${part}`).digest("base64url");
  return `${part}.${sig}`;
}

if (require.main === module) {
  const demoToken = generateChatToken(
    "11111111-2222-3333-4444-555555555555",
    "john_doe",
    "John Doe",
    false
  );
  console.log("Generated Chat Token:");
  console.log(demoToken);
  console.log("\nConnect URL:");
  console.log(`ws://localhost:4000/socket?token=${demoToken}`);
}

module.exports = { generateChatToken };
