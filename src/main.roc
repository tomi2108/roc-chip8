app [main!] {
	pf: platform "https://github.com/lukewilliamboswell/roc-platform-template-zig/releases/download/0.6/2BfGn4M9uWJNhDVeMghGeXNVDFijMfPsmmVeo6M4QjKX.tar.zst",
	# rand: "https://github.com/lukewilliamboswell/roc-random/releases/download/0.5.0/yDUoWipuyNeJ-euaij4w_ozQCWtxCsywj68H0PlJAdE.tar.br",
}

import pf.Stdout
import Emulator
import Instruction
import Cartdrige
import Timer
import Screen
import pf.Sleep

fps = 120

clear_sequence = [27, 91, 50, 74, 27, 91, 72]
clear_screen! = |_| {
	Stdout.line!(Str.from_utf8(clear_sequence)?)
}

render! = |emu| {
	new_emu = Instruction.exec(emu)
	clear_screen!()
	new_emu.screen.draw!()
	new_timers = new_emu
		.tick_timer(Sound)
		.tick_timer(Delay)

	Sleep.millis!(1000 // fps)
	render!({ ..new_emu, timers: new_timers })
}

main! = |_args| {
	filename = "TETRIS"

	emu = Emulator.new
	loaded = Cartdrige.load_cartridge!(emu.ram, filename)

	render!({ ..emu, ram: loaded })
}
