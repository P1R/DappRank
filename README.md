# DappRank

## Foundry Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

## Smart Contracts Deployment testing

use tmux or in an alternative shell run anvil
```shell
$ anvil --host 0.0.0.0
```
source the .env which contains the deployment variables
for further information check the [envexample](./envexample) file
```shell
$ source .env
```
execute the deployment of the script
```shell
$ forge script script/DappsManager.s.sol:DappsManagerScript  --rpc-url $PROVIDER_URL --private-key $PK0 --broadcast
```

## References

1. https://ethereum.stackexchange.com/questions/87451/solidity-error-struct-containing-a-nested-mapping-cannot-be-constructed
