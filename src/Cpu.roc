module [Cpu, exec_instruction, initial_cpu, advance_pc]

import Memory
import Ram
import Screen
import Stack
import Keypad
import Timer
import rand.Random

Cpu : { rs : List U8, pc : U16, i : U16 }
State : {
    memory : Memory.Mem,
    cpu : Cpu,
    keypad : Keypad.Keypad,
    timers : Timer.Timers,
    screen : Screen.Screen,
}

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

random = |state, reg, nn|
    generator = Random.bounded_u8(0x0, 0xFF)
    { value: rand } =
        Random.seed(123)
        |> Random.step(generator)
    state |> set_register reg (Num.bitwise_and rand nn)

jump = |state, nnn|
    cpu = state.cpu
    { state & cpu: { cpu & pc: nnn } }

jump_offset = |state, reg, nnn|
    offset = nnn + Num.to_u16(state |> get_register reg)
    state |> jump offset

jump_offset_v0 = |state, nnn| jump_offset state 0x0 nnn

ret = |state|
    (bytes, new_stack) = Stack.stack_pop state.memory.stack
    mem = state.memory
    new_state = { state & memory: { mem & stack: new_stack } }
    new_state |> jump bytes

sub_routine = |state, nnn|
    memory = state.memory
    new_stack = Stack.stack_push state.memory.stack state.cpu.pc
    new_state = { state & memory: { memory & stack: new_stack } }
    new_state |> jump nnn

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
    val = Timer.get_timer state.timers Delay
    state |> set_register reg val

set_d_timer_reg = |state, reg|
    val = state |> get_register reg
    new_timers = state.timers |> Timer.set_timer Delay val
    { state & timers: new_timers }

set_s_timer_reg = |state, reg|
    val = state |> get_register reg
    new_timers = state.timers |> Timer.set_timer Sound val
    { state & timers: new_timers }

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
    state |> set_register vx (op valx valy)

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

sub_regs_i = |state, vx, vy|
    valx = state |> get_register vx
    valy = state |> get_register vy
    overflows = Num.from_bool(valy >= valx)
    state
    |> binary_regs vx vy (|x, y| y - x)
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

get_key = |state, reg|
    when Keypad.some_key_pressed state.keypad is
        Ok(key) ->
            state |> set_register reg key

        Err(NoKeyPressed) ->
            state |> jump (state.cpu.pc - 2)

font_character = |state, reg|
    val = state |> get_register reg
    character = val |> Num.bitwise_and 0x000F |> Num.to_u16
    state |> set_index (0x50 + character * 5)

binary_decimal_conversion = |state, reg|
    byte = state |> get_register reg
    digit_1 = (byte // 100) % 10
    digit_2 = (byte // 10) % 10
    digit_3 = byte % 10
    mem = state.memory
    new_ram = mem.ram |> Ram.write_ram [digit_1, digit_2, digit_3] state.cpu.i
    { state & memory: { mem & ram: new_ram } }

# TODO:
# if (config_get_int_value(cpu_config, "memory_access_modify_index"))
# registers.R_I += reg + 1;
memory_write = |state, reg|
    mem = state.memory
    to_write =
        List.range({ start: At 0, end: At reg })
        |> List.map |x|
            state |> get_register x

    new_ram = state.memory.ram |> Ram.write_ram to_write state.cpu.i
    { state & memory: { mem & ram: new_ram } }

# TODO:
# if (config_get_int_value(cpu_config, "memory_access_modify_index"))
# registers.R_I += reg + 1;
memory_read = |state, reg|
    List.range({ start: At 0u8, end: At reg })
    |> List.walk
        state
        |acc, x|
            byte = acc.memory.ram |> Ram.read_ram (Num.to_u16(x) + acc.cpu.i)
            acc |> set_register Num.to_u8(x) byte

draw = |state, regx, regy, n|
    valx = state |> get_register regx
    valy = state |> get_register regy
    x0 = Num.bitwise_and valx (Screen.screen_width - 1)
    y0 = Num.bitwise_and valy (Screen.screen_height - 1)
    sprite_bytes =
        List.range({ start: At 0u8, end: Before n })
        |> List.map |mem_index|
            state.memory.ram |> Ram.read_ram (state.cpu.i + Num.to_u16 mem_index)
    (new_screen, new_collided) =
        sprite_bytes
        |> List.walk_with_index (state.screen, Bool.false) |acc, byte, row_index|
            List.range({ start: At 0, end: Before 8 })
            |> List.walk acc |(scr, col), bit_index|
                shift = 7u8 - Num.to_u8 bit_index
                bit =
                    byte
                    |> Num.shift_right_by shift
                    |> Num.bitwise_and 1u8
                    |> (|b| b == 1u8)
                x = (x0 + Num.to_u8 bit_index) % Screen.screen_width
                y = (y0 + Num.to_u8 row_index) % Screen.screen_height
                pixel = Screen.screen_get(scr, x, y)
                if bit then
                    (Screen.screen_set(scr, x, y, Bool.not pixel), col or pixel)
                else
                    (scr, col)
    new_state = state |> set_register 0xF Num.from_bool(new_collided)
    { new_state & screen: new_screen }

screen_clear = |state|
    new_screen = Screen.screen_clear state.screen
    { state & screen: new_screen }

exec_instruction : State, U16 -> State
exec_instruction = |state, bytes|
    n1 = Num.bitwise_and 0xF000 bytes |> Num.shift_right_by 12 |> Num.to_u8
    n2 = Num.bitwise_and 0x0F00 bytes |> Num.shift_right_by 8 |> Num.to_u8
    n3 = Num.bitwise_and 0x00F0 bytes |> Num.shift_right_by 4 |> Num.to_u8
    n4 = Num.bitwise_and 0x000F bytes |> Num.shift_right_by 0 |> Num.to_u8

    nn = Num.bitwise_and 0x00FF bytes |> Num.to_u8
    nnn = Num.bitwise_and 0x0FFF bytes

    when (n1, n2, n3, n4) is
        (0x0, 0x0, 0xE, 0x0) -> screen_clear state
        (0x0, _, _, 0xE) -> ret state
        (0x1, _, _, _) -> jump state nnn
        (0x2, _, _, _) -> sub_routine state nnn
        (0x3, _, _, _) -> skip_if_reg state n2 nn
        (0x4, _, _, _) -> skip_if_not_reg state n2 nn
        (0x5, _, _, _) -> skip_if_regs state n2 n3
        (0x6, _, _, _) -> set_nn state n2 nn
        (0x7, _, _, _) -> add_nn state n2 nn
        (0x8, _, _, 0x0) -> set_regs state n2 n3
        (0x8, _, _, 0x1) -> binary_regs state n2 n3 Num.bitwise_or
        (0x8, _, _, 0x2) -> binary_regs state n2 n3 Num.bitwise_and
        (0x8, _, _, 0x3) -> binary_regs state n2 n3 Num.bitwise_xor
        (0x8, _, _, 0x4) -> add_regs state n2 n3
        (0x8, _, _, 0x5) -> sub_regs state n2 n3
        (0x8, _, _, 0x6) -> shift_right state n2 n3
        (0x8, _, _, 0x7) -> sub_regs_i state n2 n3
        (0x8, _, _, 0xE) -> shift_left state n2 n3
        (0x9, _, _, _) -> skip_if_not_regs state n2 n3
        (0xA, _, _, _) -> set_index state nnn
        # TODO: config for using jump_offset_v0 instead
        (0xB, _, _, _) -> jump_offset state n2 nnn
        (0xC, _, _, _) -> random state n2 nn
        (0xD, _, _, _) -> draw state n2 n3 n4
        (0xE, _, 0x9, 0xE) -> skip_if_key state n2
        (0xE, _, 0xA, 0x1) -> skip_if_not_key state n2
        (0xF, _, 0x0, 0x7) -> set_reg_d_timer state n2
        (0xF, _, 0x0, 0xA) -> get_key state n2
        (0xF, _, 0x1, 0x5) -> set_d_timer_reg state n2
        (0xF, _, 0x1, 0x8) -> set_s_timer_reg state n2
        (0xF, _, 0x1, 0xE) -> add_index state n2
        (0xF, _, 0x2, 0x9) -> font_character state n2
        (0xF, _, 0x3, 0x3) -> binary_decimal_conversion state n2
        (0xF, _, 0x5, 0x5) -> memory_write state n2
        (0xF, _, 0x6, 0x5) -> memory_read state n2
        _ -> noop state
