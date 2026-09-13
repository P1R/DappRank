import { ethers } from "ethers";

// ============================================================================
// ENSv2 (Sepolia) — capa de resolución de nombres para DappRank
// ============================================================================
// Integración con el premio ENS — "Best Integration of ENSv2 into an Existing
// Project (Continuity)". DappRank identifica cada dApp con un bytes32 opaco;
// ENSv2 les da un nombre legible: <dappname>.dapprank.eth.
//
// Direcciones canónicas del deployment ENSv2 en Sepolia (2026-06-29):
//   https://github.com/ensdomains/contracts-v2/blob/main/contracts/docs/addresses/sepolia.md
//
// El entry point de resolución es UpgradableUniversalResolverProxy, que
// resuelve nombres v1 y v2 (lo usan las apps oficiales de ENS).
// ============================================================================

/** @type {string} UpgradableUniversalResolverProxy (Sepolia) */
export const ENSV2_UNIVERSAL_RESOLVER =
  "0xeEeEEEeE14D718C2B47D9923Deab1335E144EeEe";

/** @type {string} Dominio raíz de DappRank en ENSv2 */
export const DAPPRANK_ENS_DOMAIN =
  import.meta.env.VITE_DAPPRANK_ENS_DOMAIN || "dapprank.eth";

/** RPC público de Sepolia para resolución sin wallet conectada. */
const PUBLIC_SEPOLIA_RPC = "https://ethereum-sepolia-rpc.publicnode.com";

const UNIVERSAL_RESOLVER_ABI = [
  "function resolve(bytes name, bytes data) external view returns (bytes memory, address)",
];

const RESOLVER_ABI = [
  "function text(bytes32 node, string key) external view returns (string memory)",
  "function addr(bytes32 node) external view returns (address)",
];

/** Clave de texto donde guardamos el CID IPFS de la dApp en su subname. */
export const ENS_CID_KEY = "dapprank.cid";

/**
 * ENS namehash (EIP-137) — el mismo algoritmo que usa ENSv2 para los nodes.
 * @param {string} name
 * @returns {string} node (hex bytes32)
 */
export function namehash(name) {
  let node =
    "0x0000000000000000000000000000000000000000000000000000000000000000";
  if (name) {
    const labels = name.split(".");
    for (let i = labels.length - 1; i >= 0; i--) {
      const labelHash = ethers.keccak256(ethers.toUtf8Bytes(labels[i]));
      node = ethers.keccak256(ethers.concat([node, labelHash]));
    }
  }
  return node;
}

/**
 * DNS-encode un nombre ("a.b.eth" -> \x01a\x01b\x03eth\x00). El
 * UniversalResolver espera el nombre en este formato, no UTF-8 plano.
 * @param {string} name
 * @returns {Uint8Array}
 */
export function dnsEncode(name) {
  const parts = name.split(".").map((label) => {
    const bytes = ethers.toUtf8Bytes(label);
    const out = new Uint8Array(bytes.length + 1);
    out[0] = bytes.length;
    out.set(bytes, 1);
    return out;
  });
  const total = parts.reduce((n, p) => n + p.length, 0) + 1;
  const result = new Uint8Array(total);
  let offset = 0;
  for (const part of parts) {
    result.set(part, offset);
    offset += part.length;
  }
  result[offset] = 0; // label raíz
  return result;
}

/**
 * Construye el nombre ENS de una dApp: <label>.dapprank.eth
 * @param {string} label
 * @returns {string}
 */
export function dappEnsName(label) {
  return `${label}.${DAPPRANK_ENS_DOMAIN}`;
}

/**
 * Convierte el bytes32 del contrato/subgraph a label legible.
 * @param {string} rawName bytes32 hex
 * @returns {string}
 */
export function labelFromBytes32(rawName) {
  try {
    return ethers.toUtf8String(rawName).replace(/\0/g, "").trim();
  } catch {
    return "";
  }
}

/**
 * Resuelve un record de texto vía UniversalResolverV2 (ENSv2).
 * @param {import("ethers").AbstractProvider | null} provider
 * @param {string} name nombre ENS completo (ej. "desci.dapprank.eth")
 * @param {string} key clave del record
 * @returns {Promise<string | null>}
 */
export async function resolveTextRecord(provider, name, key) {
  const rpc = provider ?? new ethers.JsonRpcProvider(PUBLIC_SEPOLIA_RPC);
  const resolver = new ethers.Contract(
    ENSV2_UNIVERSAL_RESOLVER,
    UNIVERSAL_RESOLVER_ABI,
    rpc,
  );
  const iface = new ethers.Interface(RESOLVER_ABI);
  const node = namehash(name);
  const data = iface.encodeFunctionData("text", [node, key]);
  const [result] = await resolver.resolve(dnsEncode(name), data);
  const value = iface.decodeFunctionResult("text", result)[0];
  return value || null;
}

/**
 * Resuelve la dirección ETH asociada a un nombre ENSv2.
 * @param {import("ethers").AbstractProvider | null} provider
 * @param {string} name
 * @returns {Promise<string | null>}
 */
export async function resolveAddr(provider, name) {
  const rpc = provider ?? new ethers.JsonRpcProvider(PUBLIC_SEPOLIA_RPC);
  const resolver = new ethers.Contract(
    ENSV2_UNIVERSAL_RESOLVER,
    UNIVERSAL_RESOLVER_ABI,
    rpc,
  );
  const iface = new ethers.Interface(RESOLVER_ABI);
  const node = namehash(name);
  const data = iface.encodeFunctionData("addr", [node]);
  const [result] = await resolver.resolve(dnsEncode(name), data);
  const value = iface.decodeFunctionResult("addr", result)[0];
  return value || null;
}

/**
 * Enriquece la lista de dApps con su nombre ENSv2 y records resueltos.
 * No bloquea: muta los items en su lugar conforme llegan los resultados y
 * marca `ensResolved: false` si el subname no existe (fallback al bytes32).
 *
 * @param {Array<Record<string, any>>} dapps items de ethVars.dappsList
 * @param {import("ethers").AbstractProvider | null} [provider]
 * @returns {Promise<void>}
 */
export async function attachEnsNames(dapps, provider = null) {
  if (!Array.isArray(dapps) || dapps.length === 0) return;
  const rpc = provider ?? new ethers.JsonRpcProvider(PUBLIC_SEPOLIA_RPC);
  const resolver = new ethers.Contract(
    ENSV2_UNIVERSAL_RESOLVER,
    UNIVERSAL_RESOLVER_ABI,
    rpc,
  );
  const iface = new ethers.Interface(RESOLVER_ABI);

  for (const dapp of dapps) {
    const label = labelFromBytes32(dapp.name);
    if (!label) continue;
    const ensName = dappEnsName(label);
    dapp.ensName = ensName;
    dapp.ensResolved = false;
    try {
      const node = namehash(ensName);
      const data = iface.encodeFunctionData("text", [node, ENS_CID_KEY]);
      const [result] = await resolver.resolve(dnsEncode(ensName), data);
      const cid = iface.decodeFunctionResult("text", result)[0];
      dapp.ensCid = cid || null;
      dapp.ensResolved = true;
    } catch {
      // El subname no está registrado (o la resolución falló): se mantiene el
      // nombre bytes32 como fallback.
      dapp.ensResolved = false;
    }
  }
}
