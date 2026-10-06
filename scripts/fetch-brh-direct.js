/**
 * BRH Daily Rates Scraper
 * Pulls from: https://www.brh.ht/taux-du-jour/
 * Extracts:
 *   1. Informal Market (Purchases, Sales, Spread)
 *   2. Banking Market (Purchases, Sales, Spread)
 *   3. Reference Rate (Taux de Référence)
 *   4. Average Acquisition Rate (AAR)
 */

const fs = require('fs');
const path = require('path');
const cheerio = require('cheerio');

async function fetchWithRetry(url, options = {}, retries = 3, backoffMs = 4000) {
  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      console.log(`📡 [Attempt ${attempt}/${retries}] Fetching BRH daily rates from ${url}...`);
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 25000); // 25s timeout

      const response = await fetch(url, {
        ...options,
        signal: controller.signal,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
          'Accept-Language': 'fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7',
          ...(options.headers || {})
        }
      });

      clearTimeout(timeoutId);

      if (response.ok) {
        const text = await response.text();
        if (text && text.length > 500) {
          return text;
        }
        console.warn(`[Attempt ${attempt}] BRH response was unusually small (${text ? text.length : 0} bytes).`);
      } else {
        console.warn(`[Attempt ${attempt}] BRH server responded with HTTP status ${response.status}`);
      }
    } catch (err) {
      console.warn(`[Attempt ${attempt}] Network error: ${err.message}`);
    }

    if (attempt < retries) {
      console.log(`⏳ Waiting ${backoffMs / 1000}s before next retry...`);
      await new Promise(r => setTimeout(r, backoffMs));
      backoffMs *= 1.5;
    }
  }
  return null;
}

async function scrapeBRH() {
  const url = 'https://www.brh.ht/taux-du-jour/';
  const projectRoot = path.join(__dirname, '..');
  const publicDir = path.join(projectRoot, 'public');
  const currentQuotePath = path.join(projectRoot, 'htd-quote.json');

  // Load existing quote if available for fallback preservation
  let existingQuote = null;
  if (fs.existsSync(currentQuotePath)) {
    try {
      existingQuote = JSON.parse(fs.readFileSync(currentQuotePath, 'utf8'));
    } catch (e) {}
  }

  const html = await fetchWithRetry(url);
  const isLiveScrape = Boolean(html);

  if (!isLiveScrape) {
    console.warn('⚠️ Unable to retrieve live HTML from BRH after retries. Preserving previous quotation data if available.');
  }

  const $ = cheerio.load(html || '<html><body></body></html>');

  // Helper: extract numeric value from a table row (supports English and French BRH terms)
  function findRowValue(labels, columnIndex) {
    if (!Array.isArray(labels)) labels = [labels];
    let value = null;
    $('table tr').each((_, row) => {
      if (value !== null) return;
      const cells = $(row).find('td, th');
      const first = cells.eq(0).text().trim().toUpperCase();
      for (const label of labels) {
        if (first.includes(label.toUpperCase())) {
          const target = cells.eq(columnIndex);
          if (target.length) {
            const txt = target.text().trim().replace(',', '.');
            const num = parseFloat(txt);
            if (!isNaN(num)) {
              value = num;
              break;
            }
          }
        }
      }
    });
    return value;
  }

  // Fallbacks: prioritize existingQuote, then standard defaults
  const fbRef = existingQuote?.reference?.raw || 130.5300;
  const fbBankBuy = existingQuote?.banking?.buy || 130.2834;
  const fbBankSell = existingQuote?.banking?.sell || 131.2205;
  const fbBankSpread = existingQuote?.banking?.spread || 0.9371;
  const fbInfBuy = existingQuote?.informal?.buy || 130.9000;
  const fbInfSell = existingQuote?.informal?.sell || 135.6000;
  const fbInfSpread = existingQuote?.informal?.spread || 4.7000;
  const fbAar = existingQuote?.aar?.raw || 131.2205;

  const informal = {
    buy: findRowValue(['INFORMAL MARKET', 'MARCHÉ INFORMEL', 'MARCHE INFORMEL'], 1) || fbInfBuy,
    sell: findRowValue(['INFORMAL MARKET', 'MARCHÉ INFORMEL', 'MARCHE INFORMEL'], 2) || fbInfSell,
    spread: findRowValue(['INFORMAL MARKET', 'MARCHÉ INFORMEL', 'MARCHE INFORMEL'], 3) || fbInfSpread
  };

  const banking = {
    buy: findRowValue(['BANKING MARKET', 'MARCHÉ BANCAIRE', 'MARCHE BANCAIRE'], 1) || fbBankBuy,
    sell: findRowValue(['BANKING MARKET', 'MARCHÉ BANCAIRE', 'MARCHE BANCAIRE'], 2) || fbBankSell,
    spread: findRowValue(['BANKING MARKET', 'MARCHÉ BANCAIRE', 'MARCHE BANCAIRE'], 3) || fbBankSpread
  };

  const reference = findRowValue(['REFERENCE RATE', 'TAUX DE RÉFÉRENCE', 'TAUX DE REFERENCE', 'RÉFÉRENCE', 'REFERENCE'], 1) || fbRef;
  const aar = findRowValue(['AVERAGE ACQUISITION', 'ACQUISITION', 'TMA', 'AAR'], 2) || fbAar;

  // Validate reference sanity (e.g. 50 < HTG < 500)
  if (reference < 50 || reference > 500) {
    throw new Error(`Scraped reference rate out of bounds: ${reference}`);
  }

  // Compute HTD values for each rate (1 HTD = 5 HTG convention)
  const computeHtd = (htgRate) => ({
    htgPerUsd: parseFloat(htgRate.toFixed(4)),
    htdInUsd: parseFloat((5.0 / htgRate).toFixed(4)),
    usdInHtd: parseFloat((htgRate / 5.0).toFixed(2))
  });

  const now = new Date();
  const displayDate = now.toLocaleDateString('en-US', {
    timeZone: 'America/New_York',
    month: 'short', day: 'numeric', year: 'numeric'
  });
  const dayOfWeek = now.toLocaleDateString('en-US', {
    timeZone: 'America/New_York',
    weekday: 'long'
  });
  const timeET = now.toLocaleTimeString('en-US', {
    timeZone: 'America/New_York',
    hour: 'numeric',
    minute: '2-digit'
  });
  const fetchedAtET = `${dayOfWeek}, ${displayDate} at ${timeET} ET`;

  const payload = {
    date: displayDate,
    day: dayOfWeek,
    fetchedAtET: fetchedAtET,
    source: "Banque de la République d'Haïti (BRH)",
    sourceUrl: url,
    updatedAt: now.toISOString(),
    liveScraped: isLiveScrape,
    lastTweetedDate: existingQuote?.lastTweetedDate || null,
    lastTweetId: existingQuote?.lastTweetId || null,
    reference: { ...computeHtd(reference), raw: reference },
    banking: {
      buy: banking.buy,
      sell: banking.sell,
      spread: banking.spread,
      ...computeHtd(banking.sell)
    },
    informal: {
      buy: informal.buy,
      sell: informal.sell,
      spread: informal.spread,
      ...computeHtd(informal.sell)
    },
    aar: { ...computeHtd(aar), raw: aar }
  };

  if (!fs.existsSync(publicDir)) fs.mkdirSync(publicDir, { recursive: true });

  fs.writeFileSync(path.join(publicDir, 'htd-quote.json'), JSON.stringify(payload, null, 2) + '\n');
  fs.writeFileSync(path.join(projectRoot, 'htd-quote.json'), JSON.stringify(payload, null, 2) + '\n');

  console.log('\n==============================================');
  console.log(`✅ BRH RATES RECORDED (${isLiveScrape ? 'LIVE PUBLICATION' : 'PRESERVED/FALLBACK'}):`);
  console.log('==============================================');
  console.log(`📅 Date: ${fetchedAtET}`);
  console.log(`🏛️ Reference Rate: 1 USD = ${reference.toFixed(4)} HTG`);
  console.log(`🏦 Banking Market:  ${banking.buy.toFixed(4)} (buy) / ${banking.sell.toFixed(4)} (sell) [Spread: ${banking.spread.toFixed(4)}]`);
  console.log(`🛒 Informal Market: ${informal.buy.toFixed(4)} (buy) / ${informal.sell.toFixed(4)} (sell) [Spread: ${informal.spread.toFixed(4)}]`);
  console.log(`💰 1 HTD = 5 HTG = $${(5.0 / reference).toFixed(4)} USD (1 USD = ${(reference / 5.0).toFixed(2)} HTD)`);
  console.log('==============================================\n');
}

scrapeBRH().catch(err => {
  console.error('❌ Scraper failed:', err.message);
  process.exit(1);
});
