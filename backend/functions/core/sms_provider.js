/**
 * Abstract SMS Provider interface and implementations for Iranian SMS Gateways
 */

class SmsProvider {
  /**
   * Sends an OTP code to normalized Iranian phone number
   * @param {string} phone e.g. +989123456789
   * @param {string} code 6-digit OTP code
   * @returns {Promise<boolean>} success
   */
  async sendOtp(phone, code) {
    throw new Error('sendOtp method must be implemented');
  }
}

/**
 * Generic Iranian REST SMS Provider (Kavenegar / Melipayamak / Ghasedak)
 */
class IranianRestSmsProvider extends SmsProvider {
  constructor(apiToken, patternId) {
    super();
    this.apiToken = apiToken;
    this.patternId = patternId;
  }

  async sendOtp(phone, code) {
    if (!this.apiToken || !this.patternId) {
      console.warn('SMS API Token or Pattern ID not set. SMS sending bypassed.');
      return false;
    }

    try {
      // Example call structure for Kavenegar / Iranian REST Gateway
      const cleanPhone = phone.replace('+98', '0');
      const url = `https://api.kavenegar.com/v1/${this.apiToken}/verify/lookup.json?receptor=${cleanPhone}&token=${code}&template=${this.patternId}`;

      const response = await fetch(url);
      const data = await response.json();

      if (data && data.return && data.return.status === 200) {
        return true;
      }
      console.error('SMS Gateway Error Response status:', data?.return?.status);
      return false;
    } catch (err) {
      console.error('SMS Gateway HTTP Exception:', err.message);
      return false;
    }
  }
}

/**
 * Mock SMS Provider for testing/development
 */
class MockSmsProvider extends SmsProvider {
  async sendOtp(phone, code) {
    // NEVER log OTP code in production.
    console.log(`[MockSmsProvider] Simulated SMS sent to ${phone.substring(0, 7)}***`);
    return true;
  }
}

module.exports = {
  SmsProvider,
  IranianRestSmsProvider,
  MockSmsProvider,
};
