import Ram
import pf.File

Cartdrige :: [].{
	load! : Ram, Str => Ram
	load! = |ram, filename| ram.write(read_file!(filename), 0x200)
}

read_file! : Str => List(U8)
read_file! = |filename| File.read_bytes!(filename) ?? []
