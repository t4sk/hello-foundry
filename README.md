# hello-foundry

https://book.getfoundry.sh/

- [ ] install
- [ ] init
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

- auth
- time
- send eth
- event
- test fail
- test custom error
- label for error?
- test signature
- cheatcode
- console
- remapping
- mainnet fork
- crosschain fork
- fuzzing, settings
- differential testing

- formatter
- chisel
- debugger

# TODO:

- tutorials
- refs
- vyper?

### Install (Linux)

```shell
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Init

```shell
forge init
```
