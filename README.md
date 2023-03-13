# hello-foundry

```shell
npm i
```

https://book.getfoundry.sh/

- [ ] install

```shell
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

- [ ] init

```shell
forge init
```

- [ ] basic commands - compile and test
- [ ] solc version and optimizer settings
- hello world
  - [ ] fmt
  - [ ] test

```shell
forge fmt
forge test --match-path test/HelloWorld -vvvv
```

- test (match, test ok, fail, verbose, gas report)

  - counter app
  - match
  - test ok, failure
  - verbose
  - gas report

```shell
forge test --match-path test/Counter.t.sol -vvv --gas-report
```

- console

```shell
forge test --match-path test/Console.t.sol -vv
```

- [ ] auth
- [ ] event (expectEmit)
- [ ] test error (expectRevert)
- [ ] time
- [ ] test label for error
- [ ] send eth
  - [ ] deal, hoax
- [ ] signature
- cheatcode
  - env
- [ ] remapping
```shell
forge remappings
forge install rari-capital/solmate
forge update lib/solmate
forge remove solmate

npm i @openzeppelin/contracts
```
- test multisig?
- [ ] mainnet fork
```shell
forge test --fork-url $FORK_URL --match-path test/Fork.t.sol -vvv
```
# TODO: not working right now
- [ ] crosschain fork
  - token bridge

- [ ] fuzzing (assume, bound)
- [ ] invariant
- [] ffi
- differential testing

```shell
# virtual env
python3 -m pip install --user virtualenv
virtualenv -p python3 venv
source venv/bin/activate

pip install eth-abi
```

- [ ] formatter
```shell
forge fmt
```
- debugger

# TODO:

- [ ] std storage
- vyper?

- chisel
