# cairomate

**Structured**, **dependable** legos for starknet development.

## Contracts

```ml
src
├─ Ownable — "Minimal, ownable contract instance"
```

## Installation

Further installation instructions provided in the [cairo-lang docs](https://www.cairo-lang.org/docs/quickstart.html)

Create a cairo python env:

```bash
python3 -m venv ~/cairo_venv
source ~/cairo_venv/bin/activate
```

Install gmp(mac):

```bash
(mac) brew install gmp
(linux) sudo apt install -y libgmp3-dev
```

Install cairo:

```bash
pip3 install cairo-lang
```

For VSCode support:

Download `cairo-0.6.2.vsix` from https://github.com/starkware-libs/cairo-lang/releases/tag/v0.6.2

And run:
```bash
code --install-extension cairo-0.6.2.vsix
```

## Acknowledgements

Big thanks to:

- [StarkWare](https://starkware.co/)
- [OpenZeppelin](https://github.com/OpenZeppelin/cairo-contracts)
- [Rari-Capital](https://github.com/Rari-Capital/solmate)
