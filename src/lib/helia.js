import { createHelia } from 'helia';
import { unixfs } from '@helia/unixfs';
import { helia as heliaStore } from '../stores/helia.js';

let heliaNode;

export async function getHelia() {
  if (heliaNode) {
    return heliaNode;
  }

  const newNode = await createHelia();
  const fs = unixfs(newNode);
  heliaNode = { node: newNode, fs };

  heliaStore.set(heliaNode);
  return heliaNode;
}
