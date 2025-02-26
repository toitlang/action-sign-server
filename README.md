# Code sign action

A GitHub action to sign Windows executables with a remote code signing server.
Intended to be used with a Certum code signing certificate.

## Usage

### Inputs

- `uri`: The URI of the server that has the USB dongle and runs signing-server (see below).
- `password`: The password to authenticate against the singing-server.

### Examples

#### Sign a single file

```yaml
      - name: Run the action for a single file
        uses: toitlang/action-sign-server@c0ddf849f5d30d53189381ea35daec08b1457e0d  # v1.0.4
        with:
          uri: ${{ vars.SIGNING_URI }}
          password: ${{ secrets.SIGNING_PASSWORD }}
          path: test/test.exe
```

#### Sign multiple files

```yaml
      - name: Run the action for a multiple files
        uses: toitlang/action-sign-server@c0ddf849f5d30d53189381ea35daec08b1457e0d  # v1.0.4
        with:
          uri: ${{ vars.SIGNING_URI }}
          password: ${{ secrets.SIGNING_PASSWORD }}
          path: |
            test/test.exe
            test/test2.exe
```

#### Sign all exe files in a folder

If a given path is a folder, then all exe files (recursively) in that folder
will be signed. Additional paths can be added to the list.

```yaml
      - name: Run the action for all exe files in a folder
        uses: toitlang/action-sign-server@c0ddf849f5d30d53189381ea35daec08b1457e0d  # v1.0.4
        with:
          uri: ${{ vars.SIGNING_URI }}
          password: ${{ secrets.SIGNING_PASSWORD }}
          path: |
            some-folder
            some-other-folder
            test/test.exe
```

## Signing server

This action was written for a Certum open-source certificate. These are
distributed on a USB dongle and the signing process thus can't be automated
without a server that has the USB dongle connected.

The server is a simple HTTP server that listens for requests to sign files. It
then signs the files using the USB dongle and returns the signed file.

We use Cloudflare (`cloudflared`) to tunnel requests to the server, so the server
can be behind a firewall.

The README in the [server](server/) folder contains more information on how to
set up the server.
