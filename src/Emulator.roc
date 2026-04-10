import Ram
import Stack
import Keypad
import Screen
import Cpu
import Timers

Emulator :: {
	cpu : Cpu,
	ram : Ram,
	stack : Stack,
	screen : Screen,
	keypad : Keypad,
	timers : Timers,
}.{
	new : Emulator
	new = {
		cpu: Cpu.new,
		ram: Ram.new,
		stack: Stack.new,
		screen: Screen.new,
		keypad: Keypad.new,
		timers: Timers.new,
	}
}
