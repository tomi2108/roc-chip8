module [Emulator, initial_emulator]

import Ram exposing [Ram, initial_ram]
import Stack exposing [Stack, initial_stack]
import Keypad exposing [Keypad, initial_keypad]
import Screen exposing [Screen, initial_screen]
import Cpu exposing [Cpu, initial_cpu]
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
