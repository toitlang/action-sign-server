// Copyright (C) 2025 Toit language
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import cli show *
import host.directory
import host.file
import host.pipe
import http
import http.server as http
import io
import monitor
import net

main args/List:
  main args --port-callback=null

main args/List --port-callback/Lambda?:
  cmd := Command "sign"
      --help="""
        Sign Windows executables.

        Listens on the given port for requests to sign executables.
        """
      --options=[
        Option "password"
            --help="The password to use."
            --required,
        OptionInt "port" --short-name="p"
            --help="The port to listen on."
            --type="int"
            --required,
        OptionString "path"
            --help="The path to listen on."
            --default="/sign",
        OptionInt "max-connections"
            --help="The maximum number of connections to accept."
            --default=20,
        OptionInt "max-parallel-signs"
            --help="The maximum number of parallel sign requests."
            --default=1,
      ]
      --rest=[
        Option "sign-command"
            --help="The command to sign."
            --required
            --multi,
      ]
      --run=::
        server := Server it --port-callback=port-callback
        server.serve
  cmd.run args

with-tmp-dir [block]:
  dir := directory.mkdtemp "/tmp/sign-"
  try:
    block.call dir
  finally:
    directory.rmdir --recursive --force dir

class Server:
  port_/int
  path_/string
  max-connections_/int
  sign-command_/List
  password_/string
  server_/http.Server? := null
  ui_/Ui
  port-callback_/Lambda?
  sign-semaphore_/monitor.Semaphore

  started-at/Time := Time.now
  sign-requests/int := 0
  successful-signs/int := 0

  constructor invocation/Invocation --port-callback/Lambda?:
    port_ = invocation["port"]
    path_ = invocation["path"]
    sign-command_ = invocation["sign-command"]
    max-connections_ = invocation["max-connections"]
    max-parallel-signs := invocation["max-parallel-signs"]
    sign-semaphore_ = monitor.Semaphore --count=max-parallel-signs
    password_ = invocation["password"]
    ui_ = invocation.cli.ui
    port-callback_ = port-callback

  serve:
    network := net.open
    socket := network.tcp-listen port_
    actual-port := socket.local-address.port
    server := http.Server --max-tasks=max-connections_
    ui_.emit --info "Listening on port $actual-port."
    if port-callback_: port-callback_.call actual-port
    server.listen socket:: | request response-writer |
      handle_ request response-writer

  handle_ request/http.Request writer/http.ResponseWriter:
    ui_.emit --info "Received request: $request.path"
    if request.path == path_:
      sign-requests++
      e := catch:
        signed := extract-and-sign_ request.body --password=password_
        // We send binary back.
        writer.headers.set "Content-length" "$signed.size"
        writer.headers.set "Content-Type" "application/octet-stream"
        writer.write-headers 200
        writer.out.write signed
      if e:
        request.body.drain
        writer.headers.set "Content-Type" "text/plain"
        writer.write-headers 500
        writer.out.write "Failed to sign: $e"
      else:
        successful-signs++
    else if request.path == "/" or request.path == "index.html" or request.path == "status":
      html := status-page started-at --total=sign-requests --successful=successful-signs
      writer.headers.set "Content-Type" "text/html"
      writer.write-headers 200
      writer.out.write html
    else:
      writer.headers.set "Content-Type" "text/plain"
      writer.write-headers 404
      writer.out.write "Not found\n"
    writer.close

  extract-and-sign_ data/io.Reader --password/string -> ByteArray:
    sign-semaphore_.down
    try:
      return extract-and-sign__ data --password=password
    finally:
      sign-semaphore_.up

  extract-and-sign__ data/io.Reader --password/string -> ByteArray:
    ui_.emit --verbose "Extracting and signing."

    version := data.read-byte
    if version != 0: ui_.abort "Unsupported version: $version"

    password-size := data.read-byte
    given-password := data.read-string password-size
    ui_.emit --debug "Received password of size $password-size."

    if given-password != password:
      ui_.emit --debug "Rejecting invalid password."
      throw "Invalid password"

    executable-size := data.little-endian.read-int32
    ui_.emit --debug "Attempting to read $executable-size bytes."
    executable := data.read-bytes executable-size
    ui_.emit --debug "Read unsigned executable."

    with-tmp-dir: | dir/string |
      unsigned := "$dir/unsigned.exe"
      signed := "$dir/signed.exe"
      file.write-contents --path=unsigned executable

      command := sign-command_ + [unsigned, signed]
      ui_.emit --debug "Invoking: $command"
      exit-value := pipe.run-program command
      ui_.emit --debug "Exited with $exit-value."
      if exit-value != 0:
        throw "Failed to sign"

      return file.read-contents signed
    unreachable

status-page started-at/Time --total/int --successful/int -> string:
  now := Time.now
  elapsed := Duration.since started-at
  return """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Sign Server Status</title>
        <style>
            body {
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                background-color: #f4f4f4;
                margin: 0;
                padding: 0;
                display: flex;
                justify-content: center;
                align-items: center;
                min-height: 100vh;
            }

            .div-container {
                background-color: #fff;
                border-radius: 8px;
                box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
                padding: 30px;
                width: 400px;
                text-align: center;
            }

            h1 {
                color: #333;
                margin-bottom: 20px;
            }

            p {
                color: #555;
                line-height: 1.6;
                margin-bottom: 15px;
                text-align: left;
            }

            .p strong {
                font-weight: bold;
                color: #333;
            }

            .p.elapsed {
                color: #007bff;
            }

            .p.started-at {
                color: #28a745;
            }
        </style>
    </head>
    <body>
        <div class="div-container">
            <h1>Sign Server Status</h1>
            <p><strong class="started-at">Started at:</strong> $started-at</p>
            <p><strong class="elapsed">Uptime:</strong> $elapsed</p>
            <p><strong>Total sign requests:</strong> $total</p>
            <p><strong>Successful signs:</strong> $successful</p>
        </div>
    </body>
    </html>
    """
