/**
 * Haitian Dollar (HTD) - Digicel MonCash Merchant API Client
 * 
 * Supports Sandbox and Production environments.
 * If credentials are unset or placeholders, operates in local simulation mode
 * to allow development and offline testing.
 */

const SANDBOX_BASE = 'https://sandbox.moncashbutton.digicelgroup.com/Api';
const PRODUCTION_BASE = 'https://moncashbutton.digicelgroup.com/Api';

const SANDBOX_GATEWAY = 'https://sandbox.moncashbutton.digicelgroup.com/Moncash-middleware/Payment/Redirect?token=';
const PRODUCTION_GATEWAY = 'https://moncashbutton.digicelgroup.com/Moncash-middleware/Payment/Redirect?token=';

export class MonCashClient {
  constructor(config = {}) {
    this.clientId = config.clientId || process.env.MONCASH_CLIENT_ID || '';
    this.clientSecret = config.clientSecret || process.env.MONCASH_CLIENT_SECRET || '';
    this.env = (config.env || process.env.MONCASH_ENV || 'sandbox').toLowerCase();

    this.baseUrl = this.env === 'production' ? PRODUCTION_BASE : SANDBOX_BASE;
    this.gatewayUrl = this.env === 'production' ? PRODUCTION_GATEWAY : SANDBOX_GATEWAY;

    this._cachedToken = null;
    this._tokenExpiresAt = 0;
  }

  get isConfigured() {
    return (
      Boolean(this.clientId) &&
      Boolean(this.clientSecret) &&
      !this.clientId.includes('REDACTED') &&
      !this.clientSecret.includes('REDACTED')
    );
  }

  /**
   * Fetches or reuses cached OAuth Bearer token using HTTP Basic auth.
   */
  async getAccessToken() {
    if (!this.isConfigured) {
      return 'simulated_oauth_token_' + Date.now();
    }

    const now = Date.now();
    if (this._cachedToken && now < this._tokenExpiresAt - 30000) {
      return this._cachedToken;
    }

    const authHeader = 'Basic ' + Buffer.from(`${this.clientId}:${this.clientSecret}`).toString('base64');
    const response = await fetch(`${this.baseUrl}/oauth/token`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Authorization': authHeader,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: 'grant_type=client_credentials',
    });

    if (!response.ok) {
      const errText = await response.text();
      throw new Error(`MonCash OAuth error (${response.status}): ${errText}`);
    }

    const data = await response.json();
    this._cachedToken = data.access_token;
    // expires_in is in seconds
    const expiresInMs = (data.expires_in || 3600) * 1000;
    this._tokenExpiresAt = now + expiresInMs;

    return this._cachedToken;
  }

  /**
   * Creates a payment order link for user deposit.
   * User pays HTG to MonCash Merchant Account.
   * 
   * @param {Object} params
   * @param {string} params.orderId - Unique order reference ID (e.g. HTD-DEP-10293)
   * @param {number} params.amount - Amount in Haitian Gourdes (HTG)
   * @returns {Promise<{ paymentToken: string, redirectUrl: string, orderId: string, simulated: boolean }>}
   */
  async createPayment({ orderId, amount }) {
    if (!orderId || amount <= 0) {
      throw new Error('Valid orderId and positive amount required');
    }

    if (!this.isConfigured) {
      const simulatedToken = `sim_token_${Date.now()}_${Math.floor(Math.random() * 10000)}`;
      return {
        paymentToken: simulatedToken,
        redirectUrl: `${this.gatewayUrl}${simulatedToken}`,
        orderId,
        simulated: true,
      };
    }

    const token = await this.getAccessToken();
    const response = await fetch(`${this.baseUrl}/v1/CreatePayment`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        orderId,
        amount: Math.round(amount),
      }),
    });

    if (!response.ok) {
      const errText = await response.text();
      throw new Error(`MonCash CreatePayment error (${response.status}): ${errText}`);
    }

    const data = await response.json();
    const paymentToken = data.payment_token?.token || data.token;
    return {
      paymentToken,
      redirectUrl: `${this.gatewayUrl}${paymentToken}`,
      orderId,
      simulated: false,
    };
  }

  /**
   * Retrieves payment status by order ID.
   */
  async retrievePaymentByOrderId(orderId) {
    if (!this.isConfigured) {
      return {
        status: 200,
        payment: {
          reference: `MC-SIM-DEP-${orderId}`,
          orderId,
          amount: 500,
          status: 'SUCCESSFUL',
          date: new Date().toISOString(),
        },
        simulated: true,
      };
    }

    const token = await this.getAccessToken();
    const response = await fetch(`${this.baseUrl}/v1/RetrieveOrderPayment`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ orderId }),
    });

    if (!response.ok) {
      const errText = await response.text();
      throw new Error(`MonCash RetrieveOrderPayment error (${response.status}): ${errText}`);
    }

    const data = await response.json();
    return { ...data, simulated: false };
  }

  /**
   * Performs an outbound transfer (Cash-out / Buyback) from Merchant Reserve to User's phone.
   * 
   * @param {Object} params
   * @param {string} params.receiver - Digicel phone number (+509 or 8 digits)
   * @param {number} params.amount - Net HTG amount to send
   * @param {string} params.desc - Transaction memo (e.g. "HTD Cash-Out")
   * @param {string} params.reference - Unique withdrawal ID
   */
  async transfer({ receiver, amount, desc = 'HTD Cash-Out', reference }) {
    const cleanPhone = receiver.replace(/[^0-9]/g, '');
    const phone = cleanPhone.startsWith('509') ? cleanPhone : `509${cleanPhone}`;

    if (!this.isConfigured) {
      const simulatedTxId = `MC-TXN-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
      return {
        success: true,
        transactionId: simulatedTxId,
        reference: reference || `REF-${Date.now()}`,
        amount,
        receiver: phone,
        simulated: true,
      };
    }

    const token = await this.getAccessToken();
    const response = await fetch(`${this.baseUrl}/v1/Transfert`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        receiver: phone,
        amount: Math.round(amount),
        desc,
        reference,
      }),
    });

    if (!response.ok) {
      const errText = await response.text();
      throw new Error(`MonCash Transfert error (${response.status}): ${errText}`);
    }

    const data = await response.json();
    return {
      success: true,
      transactionId: data.transaction_id || data.reference,
      raw: data,
      simulated: false,
    };
  }
}
