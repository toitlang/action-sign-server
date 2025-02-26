// Copyright (C) 2025 Toit language
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import certificate-roots
import cli show *
import host.file
import http
import io
import net

VERSION ::= 0

main args/List:
  main args --cli=null

main args/List --cli/Cli?:
  certificate-roots.install-all-trusted-roots

  cmd := Command "sign"
      --help="""
        Sign Windows executables.

        Connects to the given URI and sends the executable to be signed.
        Receives the signed executable and saves it to the given output file.
        """
      --options=[
        Option "uri"
            --help="The URI to connect to."
            --type="uri"
            --required,
        Option "password"
            --help="The password to use."
            --required,
        Option "output" --short-name="o"
            --help="The output file to save the signed executable."
            --required,
      ]
      --rest=[
        Option "input"
            --help="The input file to sign."
            --required,
      ]
      --run=:: sign it
  cmd.run args --cli=cli

sign invocation/Invocation:
  ui := invocation.cli.ui

  uri := invocation["uri"]
  password := invocation["password"]
  output := invocation["output"]
  input := invocation["input"]

  buffer := io.Buffer

  buffer.write-byte VERSION

  if password.size > 0xff: ui.abort "Password too long."
  buffer.write-byte password.size
  buffer.write password

  input-bytes := file.read-contents input
  buffer.little-endian.write-int32 input-bytes.size
  buffer.write input-bytes

  payload := buffer.bytes

  network := net.open
  client := http.Client network

  try:
    response := client.post --uri=uri
        --content-type="application/octet-stream"
        payload
    if response.status-code != 200:
      body-bytes := response.body.read-all
      ui.emit --error """
          Failed to sign.
          Status code: $response.status-code
          Status message: $response.status-message
          Body: $body-bytes.to-string-non-throwing
          """
      ui.abort "Failed to sign"

    signed := response.body.read-all
    file.write-contents --path=output signed
  finally:
    client.close
    network.close
