import { createHelia } from 'helia';
import { unixfs } from '@helia/unixfs';

let heliaNode;

export async function getHelia() {
  if (heliaNode) {
    return heliaNode;
  }

  const newNode = await createHelia();
  const fs = unixfs(newNode);
  heliaNode = { node: newNode, fs };
  return heliaNode;
}
