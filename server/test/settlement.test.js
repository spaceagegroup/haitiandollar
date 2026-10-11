import test from 'node:test';
import assert from 'node:assert/strict';
import { MonCashClient } from '../src/moncash_client.js';

test('MonCashClient simulation mode when unconfigured', async () => {
  const client = new MonCashClient({ clientId: '', clientSecret: '', env: 'sandbox' });
  assert.equal(client.isConfigured, false);

  // Test Create Payment
  const payment = await client.createPayment({ orderId: 'TEST-ORD-1', amount: 500 });
  assert.equal(payment.simulated, true);
  assert.ok(payment.redirectUrl.includes('sandbox.moncashbutton.digicelgroup.com'));
  assert.ok(payment.paymentToken.startsWith('sim_token_'));

  // Test Retrieve Payment
  const check = await client.retrievePaymentByOrderId('TEST-ORD-1');
  assert.equal(check.simulated, true);
  assert.equal(check.payment.status, 'SUCCESSFUL');

  // Test Transfer (Cash-Out)
  const transfer = await client.transfer({
    receiver: '37123456',
    amount: 485,
    reference: 'TEST-WTH-1',
  });
  assert.equal(transfer.success, true);
  assert.equal(transfer.simulated, true);
  assert.equal(transfer.receiver, '50937123456');
  assert.ok(transfer.transactionId.startsWith('MC-TXN-'));
});
