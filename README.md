# hello-foundry

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

- auth
- time
- send eth
- event
- test custom error
- test label for error?
- test signature
- cheatcode
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
