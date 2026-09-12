import { BigInt, store } from "@graphprotocol/graph-ts";
import {
  DappRegistered,
  DappApproved,
  DappBanned,
  VoteCast,
  TokensBurned,
  DappCashOut,
  DappRemoved,
  DappCIDUpdated,
} from "../generated/DappsManager/DappsManager";
import { Dapp, Vote, GlobalStat } from "../generated/schema";

// burnFee (1000 bp = 10%) and DAOFee (100 bp = 1%) are set once in the
// DappsManager constructor and have no setters, so they are constants for the
// life of the subgraph. If they ever become mutable, emit them in an event.
const BURN_FEE_BPS = 1000;
const DAO_FEE_BPS = 100;

function getGlobalStat(): GlobalStat {
  let stat = GlobalStat.load("global");
  if (stat == null) {
    stat = new GlobalStat("global");
    stat.totalDapps = 0;
    stat.totalVotes = BigInt.zero();
    stat.totalBurned = BigInt.zero();
    stat.totalBalance = BigInt.zero();
    stat.save();
  }
  return stat;
}

export function handleDappRegistered(event: DappRegistered): void {
  let dapp = new Dapp(event.params.name);
  dapp.name = event.params.name.toString();
  dapp.cid = event.params.cid;
  dapp.owner = event.params.owner;
  dapp.status = "Submitted";
  dapp.rate = BigInt.zero();
  dapp.weightVotesSum = BigInt.zero();
  dapp.weightTotalSum = BigInt.zero();
  dapp.balance = BigInt.zero();
  dapp.burned = BigInt.zero();
  dapp.createdAt = event.block.timestamp;
  dapp.updatedAt = event.block.timestamp;
  dapp.save();

  let stat = getGlobalStat();
  stat.totalDapps = stat.totalDapps + 1;
  stat.save();
}

export function handleDappApproved(event: DappApproved): void {
  let dapp = Dapp.load(event.params.name);
  if (dapp == null) return;
  dapp.status = "Active";
  dapp.updatedAt = event.block.timestamp;
  dapp.save();
}

export function handleDappBanned(event: DappBanned): void {
  let dapp = Dapp.load(event.params.name);
  if (dapp == null) return;
  dapp.status = "Banned";
  dapp.updatedAt = event.block.timestamp;
  dapp.save();
}

export function handleVoteCast(event: VoteCast): void {
  let dapp = Dapp.load(event.params.dapp);
  if (dapp == null) return;

  let vote = new Vote(
    event.transaction.hash.toHex() + "-" + event.logIndex.toString(),
  );
  vote.dapp = dapp.id;
  vote.voter = event.params.voter;
  vote.voteRate = event.params.voteRate;
  vote.fanWeight = event.params.fanWeight;
  vote.timestamp = event.params.timestamp;
  vote.blockNumber = event.block.number;
  vote.save();

  dapp.weightVotesSum = dapp.weightVotesSum.plus(
    event.params.voteRate.times(event.params.fanWeight),
  );
  dapp.weightTotalSum = dapp.weightTotalSum.plus(event.params.fanWeight);
  dapp.rate = dapp.weightTotalSum.isZero()
    ? BigInt.zero()
    : dapp.weightVotesSum.div(dapp.weightTotalSum);

  // Balance delta for this vote = amount - burned - daoFee.
  // Mirrors the contract's voteDapp() accounting.
  let burnAmount = event.params.amount
    .times(BigInt.fromI32(BURN_FEE_BPS))
    .div(BigInt.fromI32(10000));
  let daoFee = event.params.amount
    .times(BigInt.fromI32(DAO_FEE_BPS))
    .div(BigInt.fromI32(10000));
  let netDelta = event.params.amount.minus(burnAmount).minus(daoFee);
  dapp.balance = dapp.balance.plus(netDelta);
  dapp.updatedAt = event.block.timestamp;
  dapp.save();

  let stat = getGlobalStat();
  stat.totalVotes = stat.totalVotes.plus(BigInt.fromI32(1));
  stat.totalBalance = stat.totalBalance.plus(netDelta);
  stat.save();
}

export function handleTokensBurned(event: TokensBurned): void {
  let dapp = Dapp.load(event.params.dapp);
  if (dapp == null) return;
  dapp.burned = dapp.burned.plus(event.params.amount);
  dapp.updatedAt = event.block.timestamp;
  dapp.save();

  let stat = getGlobalStat();
  stat.totalBurned = stat.totalBurned.plus(event.params.amount);
  stat.save();
}

export function handleDappCashOut(event: DappCashOut): void {
  let dapp = Dapp.load(event.params.dapp);
  if (dapp == null) return;
  dapp.balance = dapp.balance.minus(event.params.amount);
  dapp.updatedAt = event.block.timestamp;
  dapp.save();

  let stat = getGlobalStat();
  stat.totalBalance = stat.totalBalance.minus(event.params.amount);
  stat.save();
}

export function handleDappRemoved(event: DappRemoved): void {
  let dapp = Dapp.load(event.params.name);
  if (dapp == null) return;
  store.remove("Dapp", dapp.id.toHex());

  let stat = getGlobalStat();
  stat.totalDapps = stat.totalDapps - 1;
  stat.save();
}

export function handleDappCIDUpdated(event: DappCIDUpdated): void {
  let dapp = Dapp.load(event.params.name);
  if (dapp == null) return;
  dapp.cid = event.params.cid;
  dapp.updatedAt = event.block.timestamp;
  dapp.save();
}
