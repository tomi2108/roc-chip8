module [Emulator, exec_cpu, initial_emulator]

import Ram exposing [Ram, read_ram, initial_ram]
import Stack exposing [Stack, initial_stack]
import Keypad exposing [Keypad, initial_keypad]
import Screen exposing [Screen, initial_screen]
import Cpu exposing [Cpu, initial_cpu, advance_pc, exec_instruction]
import Timer exposing [Timers, initial_timers]

Emulator : {
    cpu : Cpu,
    ram : Ram,
    stack : Stack,
    screen : Screen,
    keypad : Keypad,
    timers : Timers,
}

initial_emulator : Emulator
initial_emulator = {
    cpu: initial_cpu,
    ram: initial_ram,
    stack: initial_stack,
    screen: initial_screen,
    keypad: initial_keypad,
    timers: initial_timers,
}

exec_cpu : Emulator -> Emulator
exec_cpu = |emu|
    b1 = read_ram emu.ram (emu.cpu.pc) |> Num.to_u16
    b2 = read_ram emu.ram (emu.cpu.pc + 1) |> Num.to_u16
    bytes = Num.shift_left_by b1 8 |> Num.bitwise_or b2

    cpu = emu.cpu |> advance_pc
    { emu & cpu }
    |> exec_instruction bytes

