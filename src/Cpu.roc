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
    offset = nnn + Num.to_u16(state |> get_register reg)
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
    val = state |> get_register reg
    state |> advance_if (val == nn)

skip_if_not_reg = |state, reg, nn|
    val = state |> get_register reg
    state |> advance_if (val != nn)

skip_if_regs = |state, reg1, reg2|
    v1 = state |> get_register reg1
    v2 = state |> get_register reg2
    state |> advance_if (v1 == v2)

skip_if_not_regs = |state, reg1, reg2|
    v1 = state |> get_register reg1
    v2 = state |> get_register reg2
    state |> advance_if (v1 != v2)

skip_if_key = |state, reg|
    key = state |> get_register reg
    pressed = Keypad.is_key_pressed state.keypad key
    state |> advance_if pressed

skip_if_not_key = |state, reg|
    key = state |> get_register reg
    pressed = Keypad.is_key_pressed state.keypad key
    state |> advance_if (Bool.not pressed)

set_reg_d_timer = |state, reg|
    val = Timer.get_timer state.timers.delay
    state |> set_register reg val

set_d_timer_reg = |state, reg|
    timers = state.timers
    delay_timer = timers.delay
    val = state |> get_register reg
    { state & timers: { timers & delay: Timer.set_timer delay_timer val } }

set_s_timer_reg = |state, reg|
    timers = state.timers
    sound_timer = timers.sound
    val = state |> get_register reg
    { state & timers: { timers & sound: Timer.set_timer sound_timer val } }

set_index = |state, nnn|
    cpu = state.cpu
    { state & cpu: { cpu & i: nnn } }

set_nn = |state, vx, nn|
    state |> set_register vx nn

set_regs = |state, vx, vy|
    valy = state |> get_register vy
    state |> set_register vx valy

binary_regs = |state, vx, vy, op|
    valx = state |> get_register vx
    valy = state |> get_register vy
    state |> set_register vx (op vx vy)

add_index = |state, vx|
    valx = state |> get_register vx |> Num.to_u16
    overflows = 0x1000 - state.cpu.i < valx
    new_state = state |> set_index valx
    # TODO: this if should be under a config flag
    if overflows then new_state |> set_register 0xF 1 else new_state

add_nn = |state, reg, nn|
    val = state |> get_register reg
    state |> set_register reg (val + nn)

add_regs = |state, vx, vy|
    valx = state |> get_register vx
    valy = state |> get_register vy
    overflows = Num.from_bool(0xFF - valx < valy)
    state
    |> binary_regs vx vy (|x, y| x + y)
    |> set_register 0xF overflows

sub_regs = |state, vx, vy|
    valx = state |> get_register vx
    valy = state |> get_register vy
    overflows = Num.from_bool(valx >= valy)
    state
    |> binary_regs vx vy (|x, y| x - y)
    |> set_register 0xF overflows

shift_left = |state, vx, vy|
    valx = state |> get_register vx
    bit = (Num.bitwise_and(valx, 0x80) > 0) |> Num.from_bool
    state
    |> set_register vx Num.shift_left_by(valx, 1)
    |> set_register 0xF bit
    # TODO: this should be under a flag
    |> set_regs vx vy

shift_right = |state, vx, vy|
    valx = state |> get_register vx
    bit = (Num.bitwise_and(valx, 0x1) > 0) |> Num.from_bool
    state
    |> set_register vx Num.shift_right_by(valx, 1)
    |> set_register 0xF bit
    # TODO: this should be under a flag
    |> set_regs vx vy

exec_instruction : State, U16 -> State
exec_instruction = |state, bytes|
    n1 = Num.bitwise_and 0xF000 bytes |> Num.shift_right_by 12 |> Num.to_u8
    n2 = Num.bitwise_and 0x0F00 bytes |> Num.shift_right_by 8 |> Num.to_u8
    n3 = Num.bitwise_and 0x00F0 bytes |> Num.shift_right_by 4 |> Num.to_u8
    n4 = Num.bitwise_and 0x000F bytes |> Num.shift_right_by 0 |> Num.to_u8

    nn = Num.bitwise_and 0x00FF bytes |> Num.to_u8
    nnn = Num.bitwise_and 0x0FFF bytes

    when (n1, n2, n3, n4) is
        (0x1, _, _, _) -> jump state nnn
        _ -> noop state
