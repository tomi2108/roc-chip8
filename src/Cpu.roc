module [Cpu, exec_instruction, initial_cpu]

import Memory
import Stack
import Keypad
import Timer

Cpu : { rs : List U8, pc : U16, i : U16 }
State : { memory : Memory.Mem, cpu : Cpu, keypad : Keypad.Keypad, timers : Timer.Timers }

initial_cpu : Cpu
initial_cpu = {
    rs: (List.repeat 16 0 |> List.map Num.to_u8),
    pc: 0x200,
    i: 0,
}

set_register : State, U8, U8 -> State
set_register = |state, reg, val|
    cpu = state.cpu
    { state & cpu: { cpu & rs: List.set cpu.rs Num.to_u64(reg) val } }

get_register : State, U8 -> U8
get_register = |state, reg|
    when List.get state.cpu.rs Num.to_u64(reg) is
        Err(_) -> crash "Illegal read to registers"
        Ok(read) -> read

advance_pc = |state| jump state (state.cpu.pc + 2)
advance_if = |state, condition| if condition then advance_pc state else state

noop : State -> State
noop = |state| state

jump = |state, nnn|
    cpu = state.cpu
    { state & cpu: { cpu & pc: nnn } }

jump_offset = |state, reg, nnn|
    offset = nnn + Num.to_u16(get_register state reg)
    jump state offset

jump_offset_v0 = |state, nnn| jump_offset state 0x0 nnn

ret = |state|
    bytes = Stack.stack_pop state.memory.stack
    jump state bytes

sub_routine = |state, nnn|
    memory = state.memory
    new_stack = Stack.stack_push state.memory.stack state.cpu.pc
    new_state = { state & memory: { memory & stack: new_stack } }
    jump new_state nnn

skip_if_reg = |state, reg, nn|
    val = get_register state reg
    advance_if state (val == nn)

skip_if_not_reg = |state, reg, nn|
    val = get_register state reg
    advance_if state (val != nn)

skip_if_regs = |state, reg1, reg2|
    v1 = get_register state reg1
    v2 = get_register state reg2
    advance_if state (v1 == v2)

skip_if_not_regs = |state, reg1, reg2|
    v1 = get_register state reg1
    v2 = get_register state reg2
    advance_if state (v1 != v2)

skip_if_key = |state, reg|
    key = get_register state reg
    pressed = Keypad.is_key_pressed state.keypad key
    advance_if state pressed

skip_if_not_key = |state, reg|
    key = get_register state reg
    pressed = Keypad.is_key_pressed state.keypad key
    advance_if state (Bool.not pressed)

set_reg_d_timer = |state, reg|
    val = Timer.get_timer state.timers.delay
    set_register state reg val

set_d_timer_reg = |state, reg|
    timers = state.timers
    delay_timer = timers.delay
    { state & timers: { timers & delay: Timer.set_timer state.timers.delay (get_register state reg) } }

set_s_timer_reg = |state, reg|
    timers = state.timers
    sound_timer = timers.sound
    { state & timers: { timers & sound: Timer.set_timer state.timers.sound (get_register state reg) } }

exec_instruction : State, U16 -> State
exec_instruction = |state, bytes|
    n1 = Num.bitwise_and 0xF000 bytes |> Num.shift_right_by 12 |> Num.to_u8
    n2 = Num.bitwise_and 0x0F00 bytes |> Num.shift_right_by 8 |> Num.to_u8
    n3 = Num.bitwise_and 0x00F0 bytes |> Num.shift_right_by 4 |> Num.to_u8
    n4 = Num.bitwise_and 0x000F bytes |> Num.shift_right_by 0 |> Num.to_u8
    nn = Num.bitwise_and 0x00FF bytes |> Num.to_u8
    nnn = Num.bitwise_and 0x0FFF bytes
    when n1 is
        0x1 -> jump state nnn
        _ -> noop state
