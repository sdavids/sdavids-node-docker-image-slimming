# Security Policy

## Supported Versions

This project will always provide security fixes for the latest version, e.g. if
the latest version is v1.1.x, then we will provide security fixes for v1.1.x.

## Reporting a Vulnerability

In case you think to have found a security issue with
_sdavids-node-docker-slimming_, please do not open a public issue.

Instead, you can report the issue to [Sebastian Davids](mailto:sdavids@gmx.de).
I will acknowledge receipt of your message in at most three days and try to
clarify further steps.

You can use my public keys to send me an encrypted and/or signed message.

### age

```shell
$ curl https://sdavids.de/sdavids.age | age -R - input.txt > output.txt.age
```

### SSH

```shell
$ curl https://sdavids.de/sdavids.keys | age -R - input.txt > output.txt.age
```

### GPG

```shell
$ curl https://sdavids.de/sdavids.gpg | gpg --import
$ gpg --fingerprint sdavids@gmx.de
```

My fingerprint: `3B05 1F8E AA0B 63D1 7220 168C 99A9 7C77 8DCD F19F`

```shell
$ gpg -esar sdavids@gmx.de -o out.txt.asc in.txt
```
