module [loadCartridge!]

import Memory
import pf.File

loadCartridge! : Str, Memory.Ram => Memory.Ram
loadCartridge! = |filename, ram| Memory.write_ram ram (readFile! filename) 0x200

readFile! : Str => List U8
readFile! = |filename|
    File.read_bytes! filename
    |> Result.with_default []

