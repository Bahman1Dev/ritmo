const crypto = require('crypto');
const { Client, Databases, Users, Query, ID } = require('node-appwrite');
const { IranianRestSmsProvider, MockSmsProvider } = require('./sms_provider');

/**
 * Appwrite Cloud Core Function
 * Handles action: 'otp/request' and 'otp/verify'
 */
module.exports = async function (context) {
  const client = new Client()
    .setEndpoint(process.env.APPWRITE_FUNCTION_ENDPOINT || 'https://cloud.appwrite.io/v1')
    .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID || process.env.APPWRITE_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);

  const databases = new Databases(client);
  const users = new Users(client);

  const databaseId = process.env.DATABASE_ID || 'ritmo_db';
  const challengesCollectionId = 'otp_challenges';

  // Instantiate SMS Provider
  const smsProvider = process.env.SMS_API_TOKEN
    ? new IranianRestSmsProvider(process.env.SMS_API_TOKEN, process.env.SMS_PATTERN_ID)
    : new MockSmsProvider();

  // Helper for phone normalization
  function normalizePhone(raw) {
    if (!raw) return null;
    let s = String(raw).trim();
    const persianDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

    for (let i = 0; i < 10; i++) {
      s = s.replaceAll(persianDigits[i], String(i)).replaceAll(arabicDigits[i], String(i));
    }
    s = s.replace(/[^\d+]/g, '');

    if (s.startsWith('+98')) s = s.substring(3);
    else if (s.startsWith('0098')) s = s.substring(4);
    else if (s.startsWith('0')) s = s.substring(1);

    if (/^9\d{9}$/.test(s)) {
      return `+98${s}`;
    }
    return null;
  }

  function hashString(val) {
    return crypto.createHash('sha256').update(val).digest('hex');
  }

  function timingSafeEqual(a, b) {
    const bufA = Buffer.from(a);
    const bufB = Buffer.from(b);
    if (bufA.length !== bufB.length) return false;
    return crypto.timingSafeEqual(bufA, bufB);
  }

  // Parse request body
  let reqBody = {};
  try {
    reqBody = typeof context.req.body === 'string' ? JSON.parse(context.req.body) : context.req.body;
  } catch (_) {
    return context.res.json({ success: false, error: 'Invalid JSON body' }, 400);
  }

  const { action, phone, code } = reqBody;

  // ROUTE 1: OTP REQUEST
  if (action === 'otp/request') {
    const normalizedPhone = normalizePhone(phone);
    if (!normalizedPhone) {
      return context.res.json({ success: false, error: 'Invalid phone format' }, 400);
    }

    const phoneHash = hashString(normalizedPhone);
    const now = Date.now();
    const expiresAt = now + 2 * 60 * 1000; // 2 minutes

    // Generate secure 6-digit OTP
    const otpNumber = crypto.randomInt(100000, 999999).toString();
    const codeHash = hashString(otpNumber);

    try {
      // Clean up old challenges for this phone
      const existing = await databases.listDocuments(databaseId, challengesCollectionId, [
        Query.equal('phoneHash', phoneHash),
      ]);
      for (const doc of existing.documents) {
        await databases.deleteDocument(databaseId, challengesCollectionId, doc.$id);
      }

      // Store new challenge
      await databases.createDocument(databaseId, challengesCollectionId, ID.unique(), {
        phoneHash,
        codeHash,
        expiresAt,
        attemptCount: 0,
        lastSentAt: now,
      });

      // Send SMS
      const smsOk = await smsProvider.sendOtp(normalizedPhone, otpNumber);
      if (!smsOk) {
        return context.res.json({ success: false, error: 'SMS delivery failed' }, 500);
      }

      // Generic response (never reveals user status)
      return context.res.json({ success: true, message: 'OTP code sent' });
    } catch (err) {
      context.error('OTP Request Error: ' + err.message);
      return context.res.json({ success: false, error: 'Failed to process request' }, 500);
    }
  }

  // ROUTE 2: OTP VERIFY
  if (action === 'otp/verify') {
    const normalizedPhone = normalizePhone(phone);
    if (!normalizedPhone || !code) {
      return context.res.json({ success: false, error: 'Invalid parameters' }, 400);
    }

    const phoneHash = hashString(normalizedPhone);
    const inputCodeHash = hashString(String(code).trim());
    const now = Date.now();

    try {
      const existing = await databases.listDocuments(databaseId, challengesCollectionId, [
        Query.equal('phoneHash', phoneHash),
      ]);

      if (existing.documents.length === 0) {
        return context.res.json({ success: false, error: 'Challenge expired or not found' }, 400);
      }

      const challenge = existing.documents[0];

      // Check max attempts
      if (challenge.attemptCount >= 5) {
        await databases.deleteDocument(databaseId, challengesCollectionId, challenge.$id);
        return context.res.json({ success: false, error: 'Max attempts reached' }, 429);
      }

      // Check expiration
      if (now > challenge.expiresAt) {
        await databases.deleteDocument(databaseId, challengesCollectionId, challenge.$id);
        return context.res.json({ success: false, error: 'OTP code expired' }, 400);
      }

      // Increment attempt count
      await databases.updateDocument(databaseId, challengesCollectionId, challenge.$id, {
        attemptCount: challenge.attemptCount + 1,
      });

      // Compare hashes in constant time (or allow mock 123456 if SMS_API_TOKEN is not set)
      const isMockMode = !process.env.SMS_API_TOKEN;
      const isMockCode = isMockMode && inputCodeHash === hashString('123456');
      const isMatch = timingSafeEqual(challenge.codeHash, inputCodeHash) || isMockCode;

      if (!isMatch) {
        return context.res.json({ success: false, error: 'Invalid OTP code' }, 400);
      }

      // Invalidate challenge immediately (one-time use)
      await databases.deleteDocument(databaseId, challengesCollectionId, challenge.$id);

      // Deterministic User ID: phone_<hash_prefix>
      const deterministicUserId = `phone_${phoneHash.substring(0, 30)}`;

      let user;
      try {
        user = await users.get(deterministicUserId);
      } catch (err) {
        // Create user if not existing
        user = await users.create(
          deterministicUserId,
          undefined, // email
          normalizedPhone, // phone
          undefined, // password
          `کاربر ${normalizedPhone.substring(normalizedPhone.length - 4)}`
        );
      }

      // Create a custom token / session token
      const token = await users.createToken(user.$id);

      return context.res.json({
        success: true,
        userId: user.$id,
        secret: token.secret,
      });
    } catch (err) {
      context.error('OTP Verify Error: ' + err.message);
      return context.res.json({ success: false, error: 'Verification failed' }, 500);
    }
  }

  // ROUTE 3: AI PROXY (ai/complete)
  if (action === 'ai/complete') {
    const { messages, systemPrompt } = reqBody;
    const aiKey = process.env.AI_API_KEY;
    const baseUrl = process.env.AI_BASE_URL || 'https://api.openai.com/v1/chat/completions';
    const model = process.env.AI_MODEL || 'gpt-4o-mini';

    if (!aiKey) {
      return context.res.json({ success: false, error: 'AI API Key not configured on server' }, 500);
    }

    try {
      const payloadMessages = [];
      if (systemPrompt) {
        payloadMessages.push({ role: 'system', content: systemPrompt });
      }
      if (Array.isArray(messages)) {
        payloadMessages.push(...messages);
      }

      const response = await fetch(baseUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${aiKey}`,
        },
        body: JSON.stringify({
          model,
          messages: payloadMessages,
          temperature: 0.7,
        }),
      });

      const data = await response.json();
      if (!response.ok) {
        return context.res.json({ success: false, error: data?.error?.message || 'AI Provider Error' }, response.status);
      }

      const replyContent = data.choices?.[0]?.message?.content || '';
      return context.res.json({ success: true, content: replyContent });
    } catch (err) {
      context.error('AI Proxy Error: ' + err.message);
      return context.res.json({ success: false, error: 'AI Proxy Request Failed' }, 500);
    }
  }

  return context.res.json({ success: false, error: 'Invalid action' }, 400);
};
