module [State, exec_cpu, initial_state]

import Memory
import Keypad
import Ram
import Screen
import Cpu
import Timer

State : {
    cpu : Cpu.Cpu,
    memory : Memory.Mem,
    screen : Screen.Screen,
    keypad : Keypad.Keypad,
    timers : Timer.Timers,
}

initial_state : State
initial_state = {
    cpu: Cpu.initial_cpu,
    memory: Memory.initial_memory,
    screen: Screen.initial_screen,
    keypad: Keypad.initial_keypad,
    timers: Timer.initial_timers,
}

exec_cpu : State -> State
exec_cpu = |state|
    b1 = Ram.read_ram state.memory.ram (state.cpu.pc) |> Num.to_u16
    b2 = Ram.read_ram state.memory.ram (state.cpu.pc + 1) |> Num.to_u16
    bytes = Num.shift_left_by b1 8 |> Num.bitwise_or b2

    state
    |> Cpu.advance_pc
    |> Cpu.exec_instruction bytes

