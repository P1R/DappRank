import { writable } from 'svelte/store';

export const provider = writable(null);
export const signer = writable(null);
export const signerAddress = writable('');
