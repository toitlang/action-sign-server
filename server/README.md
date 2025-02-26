# Signing server

This server is a simple HTTP server that listens for requests to sign files. It
then signs the files using the USB dongle and returns the signed file.

We use Cloudflare (`cloudflared`) to tunnel requests to the server, so the server
can be behind a firewall.

The server implements a protocol that is implemented by the [client](../client),
which is used by this GitHub action.

## Usage

```sh
server --password=PASSWORD --port=PORT command to sign
```

For example, using a `certum.sh` script we run our server as follows:
```sh
server \
    --verbosity-level=debug \
    --password="$password" \
    --port=9876 \
    bash "$certum_sh" "$pin_secret" "$pkcs11_so" "$certificate" "$key"
```
Note the `bash "$certum_sh" "$pin_secret" "$pkcs11_so" "$certificate" "$key"`
command that is passed to the server. This command is executed by the server
to sign the files. In addition to the given arguments, the server also passes
the path to the unsigned file and the path to the signed file.

## Certum Setup

See [our setup guide](https://github.com/toitlang/setup-sign) for how to set up
a server with a Certum USB dongle.
