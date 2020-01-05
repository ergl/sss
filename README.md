# Shamir's Secret Sharing Scheme

A basic Shamir's Secret Sharing implementation, built for the Cryptography and Coding Theory course at UCM, 2019/2020.

You can find the Python 3 version in its [own repo](https://github.com/ergl/sss_py).

# Build

A simple `make` will do (provided you have `ponyc` installed).

# Usage

By default, the compiled binary will be located in the `_build` folder.

```
$ ./_build/sss -h
usage: sss [<options>] [<args> ...]

A simple Shamir's secret sharing program

Options:
   -h, --help=false
   -t, --threshold        Share threshold to recover the secret
   -n, --shares           Number of shares to generate
   -e, --encrypt=true     Tells sss to encrypt a secret
   -d, --decrypt=false    Tells sss to decrypt a secret
```
