// Shared modal state so modals can be rendered at the app root (outside the
// header), avoiding any ancestor `transform`/`filter`/`backdrop-filter` that
// would otherwise become the containing block for the fixed overlay.
/** @type {{ active: 'vote' | 'buy' | 'register' | null, selectedDapp: string | null }} */
export const modalState = $state({
  // 'vote' | 'buy' | 'register' | null
  active: null,
  // Raw bytes32 name of the dapp to vote on, set when the vote modal is
  // opened from a specific card/row in the ranking.
  selectedDapp: null,
});

/** @param {'vote' | 'buy' | 'register'} name */
export function openModal(name) {
  modalState.active = name;
}

/** @param {string} dappName Raw bytes32 name of the dapp to vote on. */
export function openVoteModal(dappName) {
  modalState.selectedDapp = dappName;
  modalState.active = "vote";
}

export function closeModal() {
  modalState.active = null;
  modalState.selectedDapp = null;
}
