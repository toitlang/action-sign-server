// Copyright (C) 2025 Toit language
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the tests/LICENSE file.

import host.file

PREFIX ::= "SIGNED".to-byte-array

validate unsigned-path/string signed-path/string -> bool:
  signed-bytes := file.read-contents signed-path
  unsigned-bytes := file.read-contents unsigned-path
  return signed-bytes == PREFIX + unsigned-bytes

main args:
  if args.size != 2:
    print "Usage: signer.toit <input> <output>"
    exit 1

  input-path := args[0]
  output-path := args[1]

  input-bytes := file.read-contents input-path
  output-bytes := PREFIX + input-bytes

  file.write-contents --path=output-path output-bytes
  print "Signed file written to $output-path"
