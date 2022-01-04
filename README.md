# cairomate • [![Tests](https://github.com/a5f9t4/cairomate/actions/workflows/tests.yml/badge.svg)](https://github.com/a5f9t4/cairomate/actions/workflows/tests.yml) [![Lints](https://github.com/a5f9t4/cairomate/actions/workflows/lints.yml/badge.svg)](https://github.com/a5f9t4/cairomate/actions/workflows/lints.yml) ![GitHub](https://img.shields.io/github/license/a5f9t4/cairomate) ![GitHub package.json version](https://img.shields.io/github/package-json/v/a5f9t4/cairomate)


**Structured**, **dependable** legos for starknet development.

## Directory Structure

```ml
contracts
├─ defi
│  ├─ ChainlinkPriceOracle — "Simple price oracle using Chainlink's V3 Aggregator"
│  └─ StakingRewards — "Flexible, stripped staking rewards measured by blocks"
├─ interfaces
│  ├─ IAccount — "Account Interface"
│  ├─ IAggregatorV3 — "Chainlink V3 Aggregator Interface"
│  ├─ IERC20 — "ERC20 Contract Interface"
│  ├─ IERC165 — "ERC165 Contract Interface"
│  ├─ IERC721 — "ERC721 Contract Interface"
|  ├─ INERC721 — "N-ERC721 Contract Interface (felt-based ERC721)"
│  └─ IERC1155 — "ERC1155 Contract Interface"
├─ tokens
│  ├─ ERC20 — "Modern and gas efficient ERC20 + EIP-2612 implementation"
│  ├─ ERC721
│  │  ├─ ERC721 - "Modern and gas efficient ERC721 | Uint256-based + EIP-2612 implementation"
│  │  └─ N-ERC721 - "Modern and gas efficient ERC721 | felt-based + EIP-2612 implementation"
│  └─ ERC1155 — "Modern and gas efficient ERC1155 + EIP-165 implementation"
├─ utils
│  ├─ Account — "Stripped account"
│  ├─ Ownable — "Minimal, ownable contract instance"
│  ├─ Context — "Port of OZ's Solidity Context Abstraction"
│  └─ Pausible — "Pausible Solidity Functionality"
tests
├─ test_StakingRewards — "Flexible, stripped staking rewards measured by blocks"
├─ test_ERC20 - "Test ERC20 contract"
├─ test_ERC721 - "Test ERC721 contract"
└─ test_Ownable - "Test Ownable contract"
```

## Directions

- [ ] Flashloan using the Lending Pool
- [ ] Flexible, permissionless AMM (maybe erc1155 based like [Helios](https://github.com/z0r0z/Helios))
- [ ] Lending Pool Yield Rebalancer (aka Yield Aggregator)

## Installation

### First time?

Further installation instructions provided in the [cairo-lang docs](https://www.cairo-lang.org/docs/quickstart.html)

Before installing Cairo on your machine, you need to install `gmp`:
```bash
sudo apt install -y libgmp3-dev # linux
brew install gmp # mac
```
> If you have any troubles installing gmp on your Apple M1 computer, [here’s a list of potential solutions](https://github.com/OpenZeppelin/nile/issues/22).

For VSCode support:

Download `cairo-0.6.2.vsix` from https://github.com/starkware-libs/cairo-lang/releases/tag/v0.6.2

And run:
```bash
code --install-extension cairo-0.6.2.vsix
```

### Set up the project
Clone the repository


```bash
git clone git@github.com:a5f9t4/cairomate.git
```

`cd` into it and create a Python virtual environment:

```bash
cd cairomate
python3 -m venv env
source env/bin/activate
```

Install the [Nile](https://github.com/OpenZeppelin/nile) dev environment and then run `install` to get [the Cairo language](https://www.cairo-lang.org/docs/quickstart.html), a [local network](https://github.com/Shard-Labs/starknet-devnet/), and a [testing framework](https://docs.pytest.org/en/6.2.x/).
```bash
pip3 install cairo-nile
nile install
```

## Usage

### Compile the contracts

```bash
nile compile
```

### Run tests

```bash
pytest
```

### Extending Cairo contracts

There's no clear contract extensibility pattern for Cairo smart contracts yet. In the meantime the best way to extend our contracts is copypasting and modifying them at your own risk. Remember this contracts are still under development and they have not gone through any audit or security review whatsoever.


## Acknowledgements

Big thanks to:

- [StarkWare](https://starkware.co/)
- [OpenZeppelin](https://github.com/OpenZeppelin/cairo-contracts)
- [Rari-Capital](https://github.com/Rari-Capital/solmate)

## Security

This project is still in a very early and experimental phase. It has never been audited nor thoroughly reviewed for security vulnerabilities. Do not use in production.

Please report any security issues you find by opening up an issue in this reposisitory.

## License

Cairomate Contracts are released under the [AGPL-3.0-only](LICENSE).