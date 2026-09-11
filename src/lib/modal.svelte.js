// Shared modal state so modals can be rendered at the app root (outside the
// header), avoiding any ancestor `transform`/`filter`/`backdrop-filter` that
// would otherwise become the containing block for the fixed overlay.
/** @type {{ active: 'vote' | 'buy' | 'register' | null }} */
export const modalState = $state({
  // 'vote' | 'buy' | 'register' | null
  active: null,
});

/** @param {'vote' | 'buy' | 'register'} name */
export function openModal(name) {
  modalState.active = name;
}

export function closeModal() {
  modalState.active = null;
}
