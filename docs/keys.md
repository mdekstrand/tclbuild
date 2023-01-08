# Verification Keys

The builds provided through this site are each signed in multiple ways, to allow
verification with tools likely available on a range of systems.

## Minisign

[Minisign](https://jedisct1.github.io/minisign/) is the preferred way to verify the
images, when it is available.  Builds are signed with the following public key:

```
{{#include ../keys/tclbuild.minisign.pub}}
```

It can be downloaded from [`tclbuild.minisign.pub`](dist/tclbuild.minisign.pub).
Signatures are in `.minisig` files accompanying each build.

## Signify

The builds are also signed with OpenBSD's
[signify](https://man.openbsd.org/signify). Builds are signed with the following
public key:

```
{{#include ../keys/tclbuild.signify.pub}}
```

It can be downloaded from [`tclbuild.signify.pub`](dist/tclbuild.signify.pub).
Signatures are in `.sig` files accompanying each build.


## OpenSSL

Finally, the builds are signed with OpenSSL with the following RSA key:

```
{{#include ../keys/tclbuild.openssl.pub}}
```

It can be downloaded from [`tclbuild.openssl.pub`](dist/tclbuild.openssl.pub).
Signatures are in `.rsasig` files accompanying each build.
