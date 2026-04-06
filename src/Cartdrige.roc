module [loadCartridge!]

import Ram 
import pf.File

loadCartridge! : Str, Ram.Ram => Ram.Ram
loadCartridge! = |filename, ram| Ram.write_ram ram (readFile! filename) 0x200

readFile! : Str => List U8
readFile! = |filename|
    File.read_bytes! filename
    |> Result.with_default []

