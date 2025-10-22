import { webSockets } from '@libp2p/websockets'
import { webRTC } from '@libp2p/webrtc'
import { noise } from '@chainsafe/libp2p-noise'
import { yamux } from '@chainsafe/libp2p-yamux'
import { bootstrap } from '@libp2p/bootstrap'
import { MemoryDatastore } from 'datastore-core'
import { circuitRelayTransport } from '@libp2p/circuit-relay-v2'
import { identify } from '@libp2p/identify'
import { libp2pDefaults } from 'helia'
import { seeds } from './seeds'

const datastore = new MemoryDatastore();
const defaults = libp2pDefaults();

export const Libp2pOptions = {
    ...defaults,
    peerDiscovery: [
        bootstrap(seeds)

    ],
    datastore,
    addresses: {
        listen: [
            '/p2p-circuit',
            '/webrtc'
        ]
    },
    transports: [
        webSockets(),
        circuitRelayTransport(),
        webRTC()
    ],
    streamMuxers: [yamux()],
    connectionEncrypters: [noise()],
    services: {
        identify: identify()
    }
}
