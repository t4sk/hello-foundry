# hello-foundry

https://github.com/foundry-rs/foundry

https://book.getfoundry.sh/

### Basic

-   [ ] Install

```shell
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

-   [ ] Init

```shell
forge init
```

-   [ ] Basic commands

```shell
forge build
forge test
forge test --match-path test/HelloWorld -vvvv
```

---

-   [ ] Solidity version and optimizer settings

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

-   [ ] Test (match, test ok, test fail, verbose, gas report)

    -   counter app
    -   match
    -   test ok, failure
    -   verbose
    -   gas report

```shell
forge test --match-path test/Counter.t.sol -vvv --gas-report
forge snapshot
```

---

-   [ ] console

```shell
forge test --match-path test/Console.t.sol -vv
```

### Intermediate

---

-   [ ] Test auth
-   [ ] Test event (expectEmit)
-   [ ] Test error (expectRevert)
-   [ ] Test time
-   [ ] Test label for error
-   [ ] Test send eth
    -   [ ] deal, hoax
-   [ ] Test signature
-   [ ] Cheatcode

    -   env

-   TODO: test eth wallet, multisig, auction?
-   [ ] mainnet fork

```shell
forge test --fork-url $FORK_URL --match-path test/Fork.t.sol -vvv
```

### Advanced

# TODO: not working right now

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

# TODO:

-   [ ] Check foundry book
-   [ ] std storage
-   [ ] vyper?
-   forge geiger

-   chisel?
-   debugger?
