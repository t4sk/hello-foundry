# hello-foundry

https://github.com/foundry-rs/foundry

https://book.getfoundry.sh/

## Basic

-   [x] Install

```shell
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

-   [x] Init

```shell
forge init
```

-   [x] Basic commands

```shell
forge build
forge test
forge test --match-path test/HelloWorld -vvvv
```

---

-   [x] Test
    -   counter app
    -   test setup, ok, fail
    -   match
    -   verbose
    -   gas report

```shell
forge test --match-path test/Counter.t.sol -vvv --gas-report
```

---

-   [ ] Solidity version and optimizer settings

https://github.com/foundry-rs/foundry/tree/master/config

---

-   [ ] Remapping

```shell
forge remappings
forge install rari-capital/solmate
forge update lib/solmate
forge remove solmate

npm i @openzeppelin/contracts
```

---

-   [ ] Formatter

```shell
forge fmt
```

---

---

-   [ ] console

```shell
forge test --match-path test/Console.t.sol -vv
forge geiger
```

## Intermediate

---

-   [ ] Test auth
-   [ ] Test event (expectEmit)
-   [ ] Test error (expectRevert)
-   [ ] TODO: Test time (`Auction.sol`)
-   [ ] Test label for error
-   [ ] Test send eth (`Wallet.sol`)
    -   [ ] hoax, deal
-   [ ] Test signature
-   [ ] TODO: Cheatcode

    -   env

-   TODO: test multisig, auction?
-   [ ] mainnet fork

```shell
forge test --fork-url $FORK_URL --match-path test/Fork.t.sol -vvv
```

## Advanced

TODO: not working right now

-   [ ] crosschain fork

    -   token bridge

-   [ ] Fuzzing (assume, bound)
-   [ ] Invariant
-   [ ] FFI
-   [ ] Differential testing

```shell
# virtual env
python3 -m pip install --user virtualenv
virtualenv -p python3 venv
source venv/bin/activate

pip install eth-abi
```

## Misc

-   forge geiger

-   [ ] Vyper

https://github.com/0xKitsune/Foundry-Vyper

0. Install vyper

```shell
# virtual env
python3 -m pip install --user virtualenv
virtualenv -p python3 venv
source venv/bin/activate

pip3 install vyper==0.3.7

# Check installation
vyper --version
```

1. Put Vyper contract inside `vyper_contracts`
2. Declare Solidity interface inside `src`
3. Copy & paste `lib/utils/VyperDeployer.sol`
4. Write test

```shell
forge test --match-path test/Vyper.t.sol --ffi
```

-   [ ] ignore error code

```
ignored_error_codes = ["license", "unused-param", "unused-var"]
```

# TODO:

-   chisel?
-   debugger?
-   forge snapshot?
