import { createHelia } from 'helia';
import { unixfs } from '@helia/unixfs';
import { Libp2pOptions } from './config/libp2p.js';
import { createLibp2p } from 'libp2p';

// ToDo
// -[ ] Add import privKey if exists if not generate new and store it.

let heliaNode;

export async function getHelia() {
  if (heliaNode) {
    return heliaNode;
  }

  try {
    const libp2p = await createLibp2p(Libp2pOptions);
    const node = await createHelia({ libp2p });
    //const node = await createHelia();
    const fs = unixfs(node);
    heliaNode = { node, fs };
    return heliaNode;
  } catch (error) {
    console.error('Error setting up helia', error);
  }
}
