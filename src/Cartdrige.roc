module [load_cartridge!]

import Ram
import pf.File

load_cartridge! : Ram.Ram, Str => Ram.Ram
load_cartridge! = |ram, filename| Ram.write_ram ram (read_file! filename) 0x200

read_file! : Str => List U8
read_file! = |filename|
    File.read_bytes! filename
    |> Result.with_default []

