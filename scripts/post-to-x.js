/**
 * Automated X (Twitter) Rate Publisher
 * Posts daily BRH rates and HTD conversion metrics to X
 */

const fs = require('fs');
const path = require('path');
const { TwitterApi } = require('twitter-api-v2');

async function postRateToX() {
  const consumerKey = process.env.X_CONSUMER_KEY;
  const consumerSecret = process.env.X_CONSUMER_SECRET;
  const accessToken = process.env.X_ACCESS_TOKEN;
  const accessTokenSecret = process.env.X_ACCESS_TOKEN_SECRET;

  if (!consumerKey || !consumerSecret || !accessToken || !accessTokenSecret) {
    console.warn('⚠️ Missing X OAuth 1.0a credentials in environment variables (X_CONSUMER_KEY, X_CONSUMER_SECRET, X_ACCESS_TOKEN, X_ACCESS_TOKEN_SECRET).');
    console.warn('Skipping X post.');
    return;
  }

  const projectRoot = path.join(__dirname, '..');
  const quotePath = path.join(projectRoot, 'htd-quote.json');

  if (!fs.existsSync(quotePath)) {
    throw new Error(`Quote file not found at: ${quotePath}`);
  }

  const quote = JSON.parse(fs.readFileSync(quotePath, 'utf8'));

  if (quote.lastTweetedDate === quote.date) {
    console.log(`ℹ️ Notice: Daily quotation for ${quote.date} has already been posted to X (Tweet ID: ${quote.lastTweetId || 'recorded'}). Skipping.`);
    return;
  }

  const tweetText = [
    `🇭🇹 Haitian Dollar Daily (${quote.date})`,
    '',
    '1 HTD = 5.00 HTG (Fixed)',
    `1 HTD ≈ $${quote.reference.htdInUsd} USD`,
    '',
    `Reference: 1 USD = ${quote.reference.htgPerUsd} HTG`,
    `Banking: ${quote.banking.buy} – ${quote.banking.sell} HTG`,
    '',
    '#Haiti #HTD #HaitianDollar #HTG #G #Gourde'
  ].join('\n');

  console.log('📝 Preparing tweet:\n' + tweetText);

  const client = new TwitterApi({
    appKey: consumerKey.trim(),
    appSecret: consumerSecret.trim(),
    accessToken: accessToken.trim(),
    accessSecret: accessTokenSecret.trim(),
  });

  const saveUpdatedQuote = (tweetId) => {
    quote.lastTweetedDate = quote.date;
    if (tweetId) quote.lastTweetId = tweetId;
    fs.writeFileSync(quotePath, JSON.stringify(quote, null, 2) + '\n');
    const publicQuotePath = path.join(projectRoot, 'public', 'htd-quote.json');
    if (fs.existsSync(path.dirname(publicQuotePath))) {
      fs.writeFileSync(publicQuotePath, JSON.stringify(quote, null, 2) + '\n');
    }
  };

  try {
    const rwClient = client.readWrite;
    const response = await rwClient.v2.tweet(tweetText);
    console.log('✅ Tweet posted successfully to X!');
    const tweetId = response && response.data ? response.data.id : null;
    if (tweetId) {
      console.log(`Tweet ID: ${tweetId}`);
    }
    saveUpdatedQuote(tweetId);
  } catch (err) {
    // Handle duplicate tweet gracefully if already posted today
    const errMsg = [
      err.message || '',
      err.data?.title || '',
      err.data?.detail || '',
      JSON.stringify(err.data || '')
    ].join(' ').toLowerCase();

    if (errMsg.includes('duplicate')) {
      console.log('ℹ️ Notice: This daily quotation has already been posted to X. Skipping duplicate tweet.');
      saveUpdatedQuote();
      return;
    }

    console.error('⚠️ Failed to post tweet to X:');
    if (err.data) {
      console.error(JSON.stringify(err.data, null, 2));
      if (err.data.title === 'Payment Required' || err.data.detail === 'credits depleted') {
        console.error('\n👉 X API NOTICE (402 Payment Required):');
        console.error('Your X Developer account has run out of prepaid API credits.');
        console.error('Log in to https://developer.x.com/ and check Billing / Credits to replenish your balance.\n');
      }
    } else {
      console.error(err.message || err);
    }
    throw err;
  }
}

postRateToX().catch(err => {
  console.error('Process exiting with error:', err.message);
  process.exit(1);
});
