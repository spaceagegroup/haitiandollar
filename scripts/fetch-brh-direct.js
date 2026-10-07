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

  // Compute spread percentages
  const bankingSpread = parseFloat((banking.sell - banking.buy).toFixed(4));
  const bankingSpreadPct = parseFloat(((bankingSpread / banking.sell) * 100).toFixed(2));
  const informalSpread = parseFloat((informal.sell - informal.buy).toFixed(4));
  const informalSpreadPct = parseFloat(((informalSpread / informal.sell) * 100).toFixed(2));
  const spreadRatio = parseFloat((informalSpread / (bankingSpread || 1)).toFixed(1));

  // Pre-computed conversion table (1, 10, 100, 1,000 HTD mental anchors)
  const conversionTable = [1, 10, 100, 1000].map(htd => {
    const htg = htd * 5;
    const usd = parseFloat((htg / reference).toFixed(htd >= 10 ? 2 : 4));
    return {
      htd,
      htg,
      usd,
      htdLabel: `${htd.toLocaleString()} HTD`,
      htgLabel: `${htg.toLocaleString()} HTG`,
      usdLabel: `$${usd.toLocaleString('en-US', { minimumFractionDigits: htd >= 10 ? 2 : 4, maximumFractionDigits: 4 })} USD`
    };
  });

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
    status: {
      isFresh: isLiveScrape,
      badge: isLiveScrape ? 'fresh' : 'bulletin',
      labels: {
        en: isLiveScrape ? 'Live BRH Publication' : 'Latest Bulletin (Weekend/Holiday)',
        ht: isLiveScrape ? 'Piblikasyon BRH an Dirèk' : 'Dènye Bilten (Wikenn/Ferye)'
      }
    },
    reference: {
      ...computeHtd(reference),
      raw: reference,
      htgPerUsd: parseFloat(reference.toFixed(4)),
      usdPerHtd: parseFloat((5.0 / reference).toFixed(4)),
      htdPerUsd: parseFloat((reference / 5.0).toFixed(2))
    },
    htdInvariant: {
      peg: 5.0,
      htgPerHtd: 5.0,
      htdPerHtg: 0.2,
      usdPerHtd: parseFloat((5.0 / reference).toFixed(4)),
      htdPerUsd: parseFloat((reference / 5.0).toFixed(2))
    },
    banking: {
      buy: banking.buy,
      sell: banking.sell,
      spread: bankingSpread,
      spreadPct: bankingSpreadPct,
      spreadPercent: bankingSpreadPct,
      ...computeHtd(banking.sell)
    },
    informal: {
      buy: informal.buy,
      sell: informal.sell,
      spread: informalSpread,
      spreadPct: informalSpreadPct,
      spreadPercent: informalSpreadPct,
      ...computeHtd(informal.sell)
    },
    aar: { ...computeHtd(aar), raw: aar, sell: aar, buy: null },
    tma: { ...computeHtd(aar), raw: aar, sell: aar, buy: null },
    spreadComparison: {
      informalToBankingRatio: spreadRatio,
      ratioLabel: `${spreadRatio}x`,
      bankingSpreadHtg: bankingSpread,
      bankingSpreadPercent: bankingSpreadPct,
      informalSpreadHtg: informalSpread,
      informalSpreadPercent: informalSpreadPct
    },
    conversionTable: conversionTable,
    i18n: {
      en: {
        badgeLive: "Live BRH Publication",
        badgeBulletin: "Latest Bulletin (Weekend/Holiday)",
        badgeCached: "Using last cached rates",
        pageTitle: "Banque de la République d'Haïti (BRH) Daily Rates",
        pageSubtitle: "Official foreign exchange benchmark and Haitian Dollar protocol conversion metrics",
        invariantTitle: "Protocol Parity Rule — Fixed Forever",
        invariantRule: "1 HTD = 5.00 HTG (Fixed)",
        invariantExplainer: "This is the century-old monetary convention Haitians have used since 1912. It does not change.",
        impliedValueTitle: "Implied US Dollar Purchasing Power",
        brhReference: "BRH Reference Rate",
        bankingMarket: "Commercial Banking Market",
        informalMarket: "Unbanked Informal Cash Market (Street)",
        aar: "Average Acquisition Rate (AAR / TMA)",
        buy: "Buy",
        sell: "Sell",
        spread: "Spread",
        spreadNotice: `The informal cash market spread (${informalSpread.toFixed(2)} HTG) is ${spreadRatio}x wider than commercial banks.`,
        spreadTooltip: "Spread = Difference between Buy and Sell. The informal market spread is 4x wider than commercial banks.",
        conversionTitle: "HTD Mental Math & Conversion Table",
        conversionSubtitle: "Real-world purchasing power for street commerce and remittances (5 HTG = 1 HTD)",
        showConversionTable: "Show conversion table",
        dataProvidedBy: "Data provided by BRH",
        sources: "Official Sources",
        legalDisclaimer: "Foreign exchange data is compiled directly from the Banque de la République d'Haïti (BRH) daily publications for informational purposes only. Haitian Dollar Inc. is an SEC CIK-registered fintech issuer (CIK 0001906040) and is not affiliated with or endorsed by the BRH. HTD is a digital unit of account fixed to 5 HTG by protocol invariant. This does not constitute financial, investment, or banking advice."
      },
      ht: {
        badgeLive: "Piblikasyon BRH an Dirèk",
        badgeBulletin: "Dènye Bilten (Wikenn/Ferye)",
        badgeCached: "Sèvi ak dènye to kach yo",
        pageTitle: "To Echanj Chak Jou Bank Repiblik Ayiti (BRH)",
        pageSubtitle: "To referans ofisyèl ak metrik konvèsyon pwotokòl Dola Ayisyen (HTD)",
        invariantTitle: "Règ Parite Pwotokòl la — Fikse pou Tout Tan",
        invariantRule: "1 HTD = 5.00 HTG (Fikse)",
        invariantExplainer: "Sa se konvansyon monetè Ayisyen ap itilize depi 1912. Li pa janm chanje.",
        impliedValueTitle: "Valè an Dola Ameriken",
        brhReference: "To Referans BRH",
        bankingMarket: "Mache Bank Komèsyal",
        informalMarket: "Mache Enfòmèl (Lari)",
        aar: "To Mwayen Akizisyon (TMA)",
        buy: "Achte",
        sell: "Vann",
        spread: "Ekara",
        spreadNotice: `Ekara mache enfòmèl la (${informalSpread.toFixed(2)} HTG) se ${spreadRatio} fwa pi laj pase bank komèsyal yo.`,
        spreadTooltip: "Ekara = Diferans ant Achte ak Vann. Ekara mache enfòmèl la 4 fwa pi laj pase bank komèsyal yo.",
        conversionTitle: "Kalkil Rapid & Tab Konvèsyon HTD",
        conversionSubtitle: "Pouvwa acha reyèl pou komès nan lari ak transfè lajan (5 HTG = 1 HTD)",
        showConversionTable: "Gade tab konvèsyon an",
        dataProvidedBy: "Done yo soti dirèkteman nan BRH",
        sources: "Sous ofisyèl",
        legalDisclaimer: "Done tochanj sa yo rasanble dirèkteman nan piblikasyon chak jou Bank Repiblik Ayiti (BRH) pou rezon enfòmasyon sèlman. Haitian Dollar Inc. se yon konpayi fintech ki anrejistre nan SEC (CIK 0001906040) epi li pa afilye ak BRH. HTD se yon inite kont dijital ki fikse a 5 HTG pa règ pwotokòl la. Sa a pa reprezante konsèy finansye, envestisman, oswa sèvis bankè."
      }
    }
  };

  if (!fs.existsSync(publicDir)) fs.mkdirSync(publicDir, { recursive: true });

  fs.writeFileSync(path.join(publicDir, 'htd-quote.json'), JSON.stringify(payload, null, 2) + '\n');
  fs.writeFileSync(path.join(projectRoot, 'htd-quote.json'), JSON.stringify(payload, null, 2) + '\n');

  // Maintain /htd-quote-history.json (capped at 365 days for auditability & charts)
  const historyPath = path.join(projectRoot, 'htd-quote-history.json');
  let history = [];
  if (fs.existsSync(historyPath)) {
    try {
      history = JSON.parse(fs.readFileSync(historyPath, 'utf8'));
      if (!Array.isArray(history)) history = [];
    } catch (e) {
      history = [];
    }
  }

  const historyEntry = {
    date: displayDate,
    updatedAt: now.toISOString(),
    reference: payload.reference.htgPerUsd,
    usdPerHtd: payload.reference.usdPerHtd,
    banking: {
      buy: payload.banking.buy,
      sell: payload.banking.sell,
      spread: payload.banking.spread,
      spreadPct: payload.banking.spreadPct
    },
    informal: {
      buy: payload.informal.buy,
      sell: payload.informal.sell,
      spread: payload.informal.spread,
      spreadPct: payload.informal.spreadPct
    },
    spreadRatio: spreadRatio
  };

  const existingIdx = history.findIndex(h => h.date === displayDate);
  if (existingIdx >= 0) {
    history[existingIdx] = historyEntry;
  } else {
    history.push(historyEntry);
  }

  if (history.length > 365) {
    history = history.slice(-365);
  }

  fs.writeFileSync(path.join(publicDir, 'htd-quote-history.json'), JSON.stringify(history, null, 2) + '\n');
  fs.writeFileSync(path.join(projectRoot, 'htd-quote-history.json'), JSON.stringify(history, null, 2) + '\n');

  console.log('\n==============================================');
  console.log(`✅ BRH RATES RECORDED (${isLiveScrape ? 'LIVE PUBLICATION' : 'PRESERVED/FALLBACK'}):`);
  console.log('==============================================');
  console.log(`📅 Date: ${fetchedAtET}`);
  console.log(`🏛️ Reference Rate: 1 USD = ${reference.toFixed(4)} HTG`);
  console.log(`🏦 Banking Market:  ${banking.buy.toFixed(4)} (buy) / ${banking.sell.toFixed(4)} (sell) [Spread: ${bankingSpread.toFixed(4)} (${bankingSpreadPct}%)]`);
  console.log(`🛒 Informal Market: ${informal.buy.toFixed(4)} (buy) / ${informal.sell.toFixed(4)} (sell) [Spread: ${informalSpread.toFixed(4)} (${informalSpreadPct}%)]`);
  console.log(`⚖️ Spread Ratio: Informal is ${spreadRatio}x wider than Banking`);
  console.log(`💰 1 HTD = 5 HTG = $${(5.0 / reference).toFixed(4)} USD (1 USD = ${(reference / 5.0).toFixed(2)} HTD)`);
  console.log('==============================================\n');
}

scrapeBRH().catch(err => {
  console.error('❌ Scraper failed:', err.message);
  process.exit(1);
});
