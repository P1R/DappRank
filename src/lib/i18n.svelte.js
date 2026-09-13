// Lightweight i18n — locale state + dictionary + t() helper.
// No dependencies: the app is a static site on IPFS, so a hand-rolled
// dictionary keeps the build simple. Unknown keys fall back to English.
// `t()` reads the `locale` state, so template expressions re-render on
// language switch (same pattern as modal.svelte.js / theme.svelte.js).

const STORAGE_KEY = "dapprank-locale";

/** @type {{ locale: "en" | "es" }} */
export const i18n = $state({ locale: "en" });

/** @type {Record<string, Record<string, string>>} */
const translations = {
  en: {
    // Common
    "common.close": "Close",
    "common.processing": "Processing…",
    "common.connectWallet": "Connect Wallet",
    "common.connecting": "Connecting…",
    "common.yourBalance": "Your Balance: {balance} {symbol}",
    "common.connectToSeeBalance": "Connect your wallet to see your balance",
    "common.enterAmount": "Enter amount",
    "common.transactionFailed": "Transaction failed: {message}",
    "common.transactionProcessing": "Processing transaction…",
    "common.validAmount": "Please enter a valid amount",

    // Header
    "header.skip": "Skip to main content",
    "header.home": "DappRank home",
    "header.openMenu": "Open menu",
    "header.closeMenu": "Close menu",
    "header.primary": "Primary",
    "header.mobile": "Mobile",
    "header.changeTheme": "Change theme",
    "header.theme": "Theme",
    "header.changeLanguage": "Change language",
    "header.language": "Language",

    // Theme names
    "theme.original": "Emerald",
    "theme.light": "Light",
    "theme.dark": "Dark",

    // Actions
    "action.buyTokens": "Buy Tokens",
    "action.addDapp": "Add Dapp",
    "action.refresh": "Refresh",
    "action.refreshing": "Refreshing…",
    "action.refreshRanking": "Refresh ranking",
    "action.vote": "Vote",
    "action.voteNow": "Vote now",
    "action.registerDapp": "Register your dApp",
    "action.readWhitepaper": "Read the whitepaper",

    // Hero
    "hero.badge": "Live on Sepolia · Indexed by The Graph",
    "hero.title": "Rank dApps. Vote with weight. Beat the whales.",
    "hero.subtitle":
      "DappRank is a decentralized dApp ranking where every vote counts and no whale can buy the top. Square Root Weighted Voting (SRWV) keeps the ranking fair.",
    "hero.howTitle": "How it works",
    "hero.step1Title": "Connect your wallet",
    "hero.step1Text":
      "Link your wallet to read the ranking and start participating.",
    "hero.step2Title": "Get DRNK tokens",
    "hero.step2Text": "Buy DRNK to fuel your votes and earn voting power.",
    "hero.step3Title": "Vote on dApps",
    "hero.step3Text":
      "Your influence grows with √tokens — small holders matter.",
    "hero.whyTitle": "Why DappRank",
    "hero.why1Title": "Anti-whale",
    "hero.why1Text":
      "Voting power grows with the square root of your tokens, so no single holder can dominate the ranking.",
    "hero.why2Title": "Ultrasound money",
    "hero.why2Text": "Voting burns DRNK, steadily reducing supply over time.",
    "hero.why3Title": "On-chain transparency",
    "hero.why3Text":
      "Every vote and burn is indexed on The Graph — no hidden scores.",

    // Investor insights
    "insights.loading": "Loading on-chain insights…",
    "insights.error": "Insights unavailable: {error}",
    "insights.dapps": "Dapps",
    "insights.votes": "Votes",
    "insights.burned": "DRNK burned",
    "insights.held": "DRNK held",
    "insights.topBurned": "Top deflationary dapps",
    "insights.indexedBy": "Indexed live by The Graph",

    // Ranking
    "rank.loading": "Loading ranking…",
    "rank.loadingSub": "Fetching the latest data from the contract.",
    "rank.totalBurned": "Total DRNK Burned:",
    "rank.rating": "Rating",
    "rank.donated": "Donated",
    "rank.burned": "Burned",
    "rank.backing": "Community backing",
    "rank.owner": "Owner: {owner}",
    "rank.vote": "Vote",
    "rank.openOnIpfs": "Open {name} on IPFS",
    "rank.ensv2": "Resolved via ENSv2 (Sepolia)",
    "rank.colRank": "Rank",
    "rank.colDapp": "Dapp",
    "rank.colRating": "Rating",
    "rank.colDonated": "Donated",
    "rank.colBurned": "Burned",
    "rank.colBacking": "Backing",
    "rank.colStatus": "Status",
    "rank.colVote": "Vote",
    "rank.caption": "Ranking of dapps by community rating",
    "rank.empty": "No dApps loaded yet",
    "rank.emptySub":
      "Connect your wallet and click “Refresh” to load the current ranking from the contract.",
    "rank.tierHigh": "Trusted",
    "rank.tierMid": "Mixed",
    "rank.tierLow": "Risky",
    "rank.tierNeutral": "Neutral",
    "rank.statusUnknown": "Unknown",
    "rank.unknownDapp": "Unknown DApp",

    // Vote modal
    "vote.title": "Vote on Dapps",
    "vote.dapp": "Dapp:",
    "vote.selectDapp": "Select a dapp…",
    "vote.amount": "Amount (DRNK):",
    "vote.rate": "Vote Rate (1-100):",
    "vote.power": "Voting power",
    "vote.estimated": "Estimated rating",
    "vote.sqrtNote":
      "The square root slows whale influence: your power grows slower than your tokens.",
    "vote.submit": "Submit Vote",
    "vote.validInput": "Please enter a valid amount and dapp name",
    "vote.rateRange": "Vote rate must be between 1 and 100",
    "vote.connectFirst": "Please connect your wallet first to vote.",
    "vote.tokenNotConnected":
      "Token contract not connected. Reconnect your wallet.",
    "vote.noDrnk":
      "You have no DRNK. Buy tokens with “Buy Tokens” (or get an airdrop) before voting.",
    "vote.insufficient": "Insufficient balance: you have {balance} DRNK.",
    "vote.notFanTopUp":
      "You are not registered as a fan. Buy DRNK with “Buy Tokens” to activate your fan account.",
    "vote.notFanClosed":
      "You are not registered as a fan and the purchase window has expired. Contact the admin for an airdrop.",
    "vote.fanExpiredTopUp":
      "Your fan status expired. Buy DRNK to reactivate it.",
    "vote.fanExpiredClosed":
      "Your fan status expired and the purchase window is closed. Contact the admin for an airdrop.",
    "vote.notActive": "This dapp is not currently active.",
    "vote.approving": "Approving DRNK spend…",
    "vote.success": "Vote submitted successfully!",

    // Buy modal
    "buy.title": "Buy Tokens",
    "buy.amount": "Amount (ETH):",
    "buy.success": "Purchase successful!",
    "buy.connectFirst": "Please connect your wallet first to buy tokens.",

    // Register modal
    "register.title": "Register a Dapp",
    "register.listingFee": "Listing fee: {fee} ETH",
    "register.bonus": "Includes a welcome bonus of {bonus} DRNK",
    "register.name": "Dapp Name",
    "register.namePlaceholder": "e.g. my-dapp",
    "register.nameHint":
      "{count}/{max} characters — this becomes your on-chain identity.",
    "register.cid": "IPFS CID",
    "register.cidPlaceholder": "e.g. bafybeid…",
    "register.cidHint":
      "The content identifier (CID) of your dapp’s metadata on IPFS.",
    "register.forFee": "Register for {fee} ETH",
    "register.connectToRegister":
      "Connect your wallet to register a dapp on-chain.",
    "register.nameRequired": "Please enter a name for your dapp.",
    "register.nameTooLong": "Dapp names must be {max} characters or fewer.",
    "register.cidRequired": "Please enter the IPFS CID of your dapp.",
    "register.cidInvalid": "That doesn’t look like a valid IPFS CID.",
    "register.connectFirst":
      "Please connect your wallet first to register a dapp.",
    "register.walletCancelled":
      "Wallet connection was cancelled. Please try again.",
    "register.exists":
      "That dapp name is already registered. Please choose another.",
    "register.feeUncovered":
      "The listing fee was not covered. Please try again.",
    "register.rejected":
      "Transaction was rejected in your wallet. You can try again.",
    "register.insufficientFunds":
      "Your wallet has insufficient funds to cover the listing fee.",
    "register.failed": "Registration failed: {message}",
    "register.success": "Dapp registered successfully!",

    // Wallet
    "wallet.disconnect": "Disconnect wallet {address}",

    // Footer
    "footer.tagline":
      "The decentralized dApp ranking powered by Square Root Weighted Voting.",
    "footer.about": "About",
    "footer.whitepaper": "Whitepaper",
    "footer.docs": "Docs & guides",
    "footer.contracts": "Smart contracts (Sepolia)",
    "footer.dappsManager": "DappsManager",
    "footer.drnk": "DRNK token",
    "footer.subgraph": "Subgraph",
    "footer.liveEndpoint": "Live endpoint",
    "footer.builtFor": "Built for ETHOnline 2026 · The Graph Prize",
    "footer.source": "Source",
  },

  es: {
    // Common
    "common.close": "Cerrar",
    "common.processing": "Procesando…",
    "common.connectWallet": "Conectar Wallet",
    "common.connecting": "Conectando…",
    "common.yourBalance": "Tu saldo: {balance} {symbol}",
    "common.connectToSeeBalance": "Conecta tu wallet para ver tu saldo",
    "common.enterAmount": "Ingresa un monto",
    "common.transactionFailed": "Transacción fallida: {message}",
    "common.transactionProcessing": "Procesando transacción…",
    "common.validAmount": "Ingresa un monto válido",

    // Header
    "header.skip": "Saltar al contenido principal",
    "header.home": "Inicio de DappRank",
    "header.openMenu": "Abrir menú",
    "header.closeMenu": "Cerrar menú",
    "header.primary": "Principal",
    "header.mobile": "Móvil",
    "header.changeTheme": "Cambiar tema",
    "header.theme": "Tema",
    "header.changeLanguage": "Cambiar idioma",
    "header.language": "Idioma",

    // Theme names
    "theme.original": "Esmeralda",
    "theme.light": "Claro",
    "theme.dark": "Oscuro",

    // Actions
    "action.buyTokens": "Comprar Tokens",
    "action.addDapp": "Agregar Dapp",
    "action.refresh": "Actualizar",
    "action.refreshing": "Actualizando…",
    "action.refreshRanking": "Actualizar ranking",
    "action.vote": "Votar",
    "action.voteNow": "Votar ahora",
    "action.registerDapp": "Registra tu dApp",
    "action.readWhitepaper": "Leer el whitepaper",

    // Hero
    "hero.badge": "En vivo en Sepolia · Indexado por The Graph",
    "hero.title": "Ranking de dApps. Vota con peso. Vence a las ballenas.",
    "hero.subtitle":
      "DappRank es un ranking descentralizado de dApps donde cada voto cuenta y ninguna ballena puede comprar el primer lugar. El Voto Ponderado por Raíz Cuadrada (SRWV) mantiene el ranking justo.",
    "hero.howTitle": "Cómo funciona",
    "hero.step1Title": "Conecta tu wallet",
    "hero.step1Text":
      "Vincula tu wallet para leer el ranking y empezar a participar.",
    "hero.step2Title": "Consigue tokens DRNK",
    "hero.step2Text":
      "Compra DRNK para impulsar tus votos y ganar poder de voto.",
    "hero.step3Title": "Vota en las dApps",
    "hero.step3Text":
      "Tu influencia crece con √tokens — los pequeños importan.",
    "hero.whyTitle": "Por qué DappRank",
    "hero.why1Title": "Anti-ballena",
    "hero.why1Text":
      "El poder de voto crece con la raíz cuadrada de tus tokens, así ningún holder puede dominar el ranking.",
    "hero.why2Title": "Ultrasound money",
    "hero.why2Text":
      "Votar quema DRNK, reduciendo el suministro con el tiempo.",
    "hero.why3Title": "Transparencia on-chain",
    "hero.why3Text":
      "Cada voto y quema se indexa en The Graph — sin puntajes ocultos.",

    // Investor insights
    "insights.loading": "Cargando insights on-chain…",
    "insights.error": "Insights no disponibles: {error}",
    "insights.dapps": "Dapps",
    "insights.votes": "Votos",
    "insights.burned": "DRNK quemado",
    "insights.held": "DRNK en circulación",
    "insights.topBurned": "Top dapps deflacionarias",
    "insights.indexedBy": "Indexado en vivo por The Graph",

    // Ranking
    "rank.loading": "Cargando ranking…",
    "rank.loadingSub": "Obteniendo los últimos datos del contrato.",
    "rank.totalBurned": "Total DRNK quemado:",
    "rank.rating": "Rating",
    "rank.donated": "Donado",
    "rank.burned": "Quemado",
    "rank.backing": "Respaldo de la comunidad",
    "rank.owner": "Owner: {owner}",
    "rank.vote": "Votar",
    "rank.openOnIpfs": "Abrir {name} en IPFS",
    "rank.ensv2": "Resuelto vía ENSv2 (Sepolia)",
    "rank.colRank": "Rank",
    "rank.colDapp": "Dapp",
    "rank.colRating": "Rating",
    "rank.colDonated": "Donado",
    "rank.colBurned": "Quemado",
    "rank.colBacking": "Respaldo",
    "rank.colStatus": "Estado",
    "rank.colVote": "Votar",
    "rank.caption": "Ranking de dApps por rating de la comunidad",
    "rank.empty": "Aún no hay dApps cargadas",
    "rank.emptySub":
      "Conecta tu wallet y haz clic en “Actualizar” para cargar el ranking actual del contrato.",
    "rank.tierHigh": "Confiable",
    "rank.tierMid": "Mixto",
    "rank.tierLow": "Riesgo",
    "rank.tierNeutral": "Neutral",
    "rank.statusUnknown": "Desconocido",
    "rank.unknownDapp": "DApp desconocida",

    // Vote modal
    "vote.title": "Votar en dApps",
    "vote.dapp": "Dapp:",
    "vote.selectDapp": "Selecciona una dapp…",
    "vote.amount": "Monto (DRNK):",
    "vote.rate": "Tasa de voto (1-100):",
    "vote.power": "Poder de voto",
    "vote.estimated": "Rating estimado",
    "vote.sqrtNote":
      "La raíz cuadrada frena el peso de las ballenas: tu influencia crece más lento que tus tokens.",
    "vote.submit": "Enviar Voto",
    "vote.validInput": "Ingresa un monto válido y el nombre de la dapp",
    "vote.rateRange": "La tasa de voto debe estar entre 1 y 100",
    "vote.connectFirst": "Conecta tu wallet primero para votar.",
    "vote.tokenNotConnected":
      "Contrato de token no conectado. Reconecta tu wallet.",
    "vote.noDrnk":
      "No tienes DRNK. Compra tokens con “Comprar Tokens” (o recibe un airdrop) antes de votar.",
    "vote.insufficient": "Saldo insuficiente: tienes {balance} DRNK.",
    "vote.notFanTopUp":
      "No estás registrado como fan. Compra DRNK con “Comprar Tokens” para activar tu cuenta de fan.",
    "vote.notFanClosed":
      "No estás registrado como fan y la ventana de compra ya expiró. Contacta al admin para recibir un airdrop.",
    "vote.fanExpiredTopUp":
      "Tu estatus de fan expiró. Compra DRNK para reactivarlo.",
    "vote.fanExpiredClosed":
      "Tu estatus de fan expiró y la ventana de compra ya cerró. Contacta al admin para recibir un airdrop.",
    "vote.notActive": "Esta dApp no está activa actualmente.",
    "vote.approving": "Aprobando gasto de DRNK…",
    "vote.success": "¡Voto enviado con éxito!",

    // Buy modal
    "buy.title": "Comprar Tokens",
    "buy.amount": "Monto (ETH):",
    "buy.success": "¡Compra exitosa!",
    "buy.connectFirst": "Conecta tu wallet primero para comprar tokens.",

    // Register modal
    "register.title": "Registrar una Dapp",
    "register.listingFee": "Fee de listado: {fee} ETH",
    "register.bonus": "Incluye un bono de bienvenida de {bonus} DRNK",
    "register.name": "Nombre de la Dapp",
    "register.namePlaceholder": "ej. mi-dapp",
    "register.nameHint":
      "{count}/{max} caracteres — esto se convierte en tu identidad on-chain.",
    "register.cid": "CID de IPFS",
    "register.cidPlaceholder": "ej. bafybeid…",
    "register.cidHint":
      "El identificador de contenido (CID) de los metadatos de tu dapp en IPFS.",
    "register.forFee": "Registrar por {fee} ETH",
    "register.connectToRegister":
      "Conecta tu wallet para registrar una dapp on-chain.",
    "register.nameRequired": "Ingresa un nombre para tu dapp.",
    "register.nameTooLong":
      "Los nombres de dapp deben tener {max} caracteres o menos.",
    "register.cidRequired": "Ingresa el CID de IPFS de tu dapp.",
    "register.cidInvalid": "Eso no parece un CID de IPFS válido.",
    "register.connectFirst":
      "Conecta tu wallet primero para registrar una dapp.",
    "register.walletCancelled":
      "La conexión del wallet fue cancelada. Inténtalo de nuevo.",
    "register.exists": "Ese nombre de dapp ya está registrado. Elige otro.",
    "register.feeUncovered":
      "El fee de listado no fue cubierto. Inténtalo de nuevo.",
    "register.rejected":
      "La transacción fue rechazada en tu wallet. Puedes intentarlo de nuevo.",
    "register.insufficientFunds":
      "Tu wallet no tiene fondos suficientes para cubrir el fee de listado.",
    "register.failed": "Registro fallido: {message}",
    "register.success": "¡Dapp registrada con éxito!",

    // Wallet
    "wallet.disconnect": "Desconectar wallet {address}",

    // Footer
    "footer.tagline":
      "El ranking descentralizado de dApps impulsado por Voto Ponderado por Raíz Cuadrada.",
    "footer.about": "Acerca de",
    "footer.whitepaper": "Whitepaper",
    "footer.docs": "Docs y guías",
    "footer.contracts": "Contratos (Sepolia)",
    "footer.dappsManager": "DappsManager",
    "footer.drnk": "Token DRNK",
    "footer.subgraph": "Subgraph",
    "footer.liveEndpoint": "Endpoint en vivo",
    "footer.builtFor": "Hecho para ETHOnline 2026 · The Graph Prize",
    "footer.source": "Código fuente",
  },
};

/**
 * Translate a key for the current locale.
 * @param {string} key
 * @param {Record<string, string | number>} [params]
 * @returns {string}
 */
export function t(key, params = {}) {
  let str = translations[i18n.locale]?.[key] ?? translations.en[key] ?? key;
  for (const [k, v] of Object.entries(params)) {
    str = str.replace(`{${k}}`, String(v));
  }
  return str;
}

/** @param {"en" | "es"} id */
export function setLocale(id) {
  if (!translations[id]) return;
  i18n.locale = id;
  if (typeof document !== "undefined") {
    document.documentElement.lang = id;
  }
  try {
    localStorage.setItem(STORAGE_KEY, id);
  } catch {
    // Ignore storage errors (e.g. private browsing).
  }
}

// Apply the saved preference once at import time, before the first paint.
if (typeof window !== "undefined") {
  /** @type {"en" | "es"} */
  let saved = "en";
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    saved = stored === "es" ? "es" : "en";
  } catch {
    saved = "en";
  }
  setLocale(saved);
}
