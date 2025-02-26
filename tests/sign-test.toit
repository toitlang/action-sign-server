// Copyright (C) 2025 Toit language
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the tests/LICENSE file.

import expect show *
import fs
import host.directory
import host.file
import monitor
import system

import ..client.main as client
import ..server.main as server
import .signer show validate
import .test-cli

PASSWORD ::= "password"
PATH ::= "/my-sign"

with-tmp-dir [block]:
  dir := directory.mkdtemp "/tmp/sign-test-"
  try:
    block.call dir
  finally:
    directory.rmdir --recursive --force dir

start-server toit/string -> monitor.Latch:
  signer-dir := fs.dirname system.program-path
  signer-path := fs.join signer-dir "signer.toit"
  port-latch := monitor.Latch
  task --background::
    server.main --port-callback=(:: port-latch.set it) [
      "--password", PASSWORD,
      "--port", "0",
      "--max-connections", "1",
      "--path", PATH,
      toit, signer-path
    ]
  return port-latch

main args:
  if args.size != 1: throw "Expected 'toit' as argument"

  port-latch := start-server args[0]

  with-tmp-dir: | dir |
    unsigned-contents := "Unsigned"
    unsigned-path := fs.join dir "unsigned"
    file.write-contents --path=unsigned-path unsigned-contents

    signed-path := fs.join dir "signed"

    port := port-latch.get
    uri := "http://localhost:$port$PATH"

    test-cli := TestCli

    e := catch:
      // Try with bad password.
      client.main --cli=test-cli [
          "--uri", uri,
          "--password", "bad",
          "--output", signed-path,
          unsigned-path
        ]
    expect e is TestExit
    expect-not (file.is-file signed-path)

    // Try with good password.
    client.main --cli=test-cli [
        "--uri", uri,
        "--password", PASSWORD,
        "--output", signed-path,
        unsigned-path
      ]
    expect (validate unsigned-path signed-path)

