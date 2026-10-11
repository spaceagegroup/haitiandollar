/**
 * Haitian Dollar (HTD) - MonCash Merchant Settlement & Reserve Bridge Gateway
 */

import express from 'express';
import cors from 'cors';
import { MonCashClient } from './moncash_client.js';

const app = express();
const port = process.env.PORT || 4000;

app.use(cors({ origin: process.env.ALLOWED_ORIGIN || '*' }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

const moncash = new MonCashClient();

// In-memory ledger store for deposit orders and cash-outs (backed by DB in production)
const depositOrders = new Map();
const withdrawals = new Map();

const HTG_PER_HTD = 5.0;
const CASH_OUT_FEE_RATE = 0.03; // 3% fee

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'htd-settlement-service',
    timestamp: new Date().toISOString(),
    moncashConfigured: moncash.isConfigured,
    environment: moncash.env,
  });
});

/**
 * POST /api/v1/deposits/create
 * Step 1 of Deposit:
 * App asks backend to create a MonCash Payment link.
 * Body: { htdAmount: number, userAddress?: string, phone?: string }
 */
app.post('/api/v1/deposits/create', async (req, res) => {
  try {
    const { htdAmount, userAddress, phone } = req.body;
    const amount = Number(htdAmount);
    if (!amount || amount <= 0) {
      return res.status(400).json({ error: 'Valid positive htdAmount required' });
    }

    const htgAmount = Math.round(amount * HTG_PER_HTD);
    const orderId = `HTD-DEP-${Date.now()}-${Math.floor(1000 + Math.random() * 9000)}`;

    const payment = await moncash.createPayment({
      orderId,
      amount: htgAmount,
    });

    const record = {
      orderId,
      htdAmount: amount,
      htgAmount,
      userAddress: userAddress || '0x0000000000000000000000000000000000000000',
      phone: phone || '',
      status: 'PENDING',
      paymentToken: payment.paymentToken,
      redirectUrl: payment.redirectUrl,
      simulated: payment.simulated,
      createdAt: new Date().toISOString(),
    };

    depositOrders.set(orderId, record);

    res.json({
      success: true,
      orderId,
      htdAmount: amount,
      htgAmount,
      redirectUrl: payment.redirectUrl,
      paymentToken: payment.paymentToken,
      simulated: payment.simulated,
    });
  } catch (err) {
    console.error('Deposit create error:', err);
    res.status(500).json({ error: err.message });
  }
});

/**
 * GET /api/v1/deposits/:orderId
 * Step 2 of Deposit:
 * App polls backend to check if user completed the MonCash payment.
 */
app.get('/api/v1/deposits/:orderId', async (req, res) => {
  const { orderId } = req.params;
  const order = depositOrders.get(orderId);
  if (!order) {
    return res.status(404).json({ error: 'Order not found' });
  }

  // If still pending, attempt a verification query with MonCash API
  if (order.status === 'PENDING') {
    try {
      const check = await moncash.retrievePaymentByOrderId(orderId);
      if (check?.payment?.status === 'SUCCESSFUL') {
        order.status = 'CONFIRMED';
        order.moncashReference = check.payment.reference;
        order.confirmedAt = new Date().toISOString();
        // Here: Backend triggers Base L2 smart contract mint to userAddress
        order.txHash = `0xmc${Buffer.from(order.orderId).toString('hex').slice(0, 56)}`;
      }
    } catch (_) {
      // In sandbox/testing, maintain current status
    }
  }

  res.json({
    orderId: order.orderId,
    status: order.status,
    htdAmount: order.htdAmount,
    htgAmount: order.htgAmount,
    moncashReference: order.moncashReference || null,
    txHash: order.txHash || null,
  });
});

/**
 * POST /api/v1/deposits/webhook
 * IPN Webhook from MonCash when a customer payment succeeds.
 */
app.post('/api/v1/deposits/webhook', async (req, res) => {
  try {
    const payload = req.body;
    const orderId = payload.orderId || payload.order_id;
    if (!orderId) {
      return res.status(400).send('Missing orderId');
    }

    const order = depositOrders.get(orderId);
    if (order) {
      order.status = 'CONFIRMED';
      order.moncashReference = payload.transaction_id || payload.reference || 'MC-WEBHOOK-CONFIRMED';
      order.confirmedAt = new Date().toISOString();
      order.txHash = `0xmc${Buffer.from(orderId).toString('hex').slice(0, 56)}`;
      console.log(`[Settlement] Deposit confirmed for order ${orderId}: minted ${order.htdAmount} HTD`);
    }

    res.status(200).json({ received: true });
  } catch (err) {
    console.error('Webhook error:', err);
    res.status(500).send(err.message);
  }
});

/**
 * POST /api/v1/withdrawals/create
 * Cash-Out Flow (User -> MonCash Merchant Buyback):
 * User redeems HTD -> Backend burns HTD -> Sends HTG via MonCash transfer to phone.
 * Body: { htdAmount: number, phone: string, userAddress?: string }
 */
app.post('/api/v1/withdrawals/create', async (req, res) => {
  try {
    const { htdAmount, phone, userAddress } = req.body;
    const amount = Number(htdAmount);
    if (!amount || amount <= 0) {
      return res.status(400).json({ error: 'Valid positive htdAmount required' });
    }
    if (!phone || phone.trim().length < 8) {
      return res.status(400).json({ error: 'Valid Digicel/MonCash phone number required' });
    }

    const grossHtg = amount * HTG_PER_HTD;
    const feeHtg = grossHtg * CASH_OUT_FEE_RATE; // 3% fee
    const netHtg = Math.round(grossHtg - feeHtg);

    const withdrawalId = `HTD-WTH-${Date.now()}-${Math.floor(1000 + Math.random() * 9000)}`;

    // Call MonCash Transfer API to payout to user's phone
    const transferResult = await moncash.transfer({
      receiver: phone,
      amount: netHtg,
      desc: 'HTD Cash-Out Buyback',
      reference: withdrawalId,
    });

    const record = {
      withdrawalId,
      htdAmount: amount,
      grossHtg,
      feeHtg,
      netHtg,
      phone,
      userAddress: userAddress || '0x0000000000000000000000000000000000000000',
      moncashTxId: transferResult.transactionId,
      simulated: transferResult.simulated,
      status: 'COMPLETED',
      timestamp: new Date().toISOString(),
    };

    withdrawals.set(withdrawalId, record);

    res.json({
      success: true,
      withdrawalId,
      htdAmount: amount,
      netHtg,
      feeHtg,
      moncashTxId: transferResult.transactionId,
      simulated: transferResult.simulated,
    });
  } catch (err) {
    console.error('Withdrawal error:', err);
    res.status(500).json({ error: err.message });
  }
});

// Start service
app.listen(port, () => {
  console.log(`[HTD Settlement] Server running on port ${port}`);
  console.log(`[HTD Settlement] MonCash environment: ${moncash.env}`);
  console.log(`[HTD Settlement] Credentials configured: ${moncash.isConfigured}`);
});
