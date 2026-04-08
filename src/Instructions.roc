module [exec]

import Cpu exposing [Cpu, advance_if, advance_pc, set_register, get_register]
import Ram exposing [Ram, read_ram, write_ram]
import Screen exposing [Screen, screen_width, screen_height, screen_get, screen_set, screen_clear]
import Stack exposing [Stack, stack_pop, stack_push]
import Keypad exposing [Keypad]
import Timer exposing [Timers]
import rand.Random
import pf.Utc

random : Cpu, U8, U8 -> Cpu
random = |cpu, reg, nn|
    generator = Random.bounded_u8(0x0, 0xFF)
    { value: rand } =
        Random.seed(Num.to_u32 Utc.to_millis_since_epoch(Utc.now!({})))
        |> Random.step(generator)
    cpu |> set_register reg (Num.bitwise_and rand nn)

jump : Cpu, U16 -> Cpu
jump = |cpu, nnn|
    { cpu & pc: nnn }

jump_offset : Cpu, U8, U16 -> Cpu
jump_offset = |cpu, reg, nnn|
    offset = nnn + Num.to_u16(cpu |> get_register reg)
    cpu |> jump offset

jump_offset_v0 : Cpu, U16 -> Cpu
jump_offset_v0 = |cpu, nnn| jump_offset cpu 0x0 nnn

ret : (Cpu, Stack) -> (Cpu, Stack)
ret = |(cpu, stack)|
    (bytes, new_stack) = stack |> stack_pop
    new_cpu = cpu |> jump bytes
    (new_cpu, new_stack)

sub_routine : (Cpu, Stack), U16 -> (Cpu, Stack)
sub_routine = |(cpu, stack), nnn|
    new_stack = stack |> stack_push cpu.pc
    new_cpu = cpu |> jump nnn
    (new_cpu, new_stack)

skip_if_reg : Cpu, U8, U8 -> Cpu
skip_if_reg = |cpu, reg, nn|
    val = cpu |> get_register reg
    cpu |> advance_if (val == nn)

skip_if_not_reg : Cpu, U8, U8 -> Cpu
skip_if_not_reg = |cpu, reg, nn|
    val = cpu |> get_register reg
    cpu |> advance_if (val != nn)

skip_if_regs : Cpu, U8, U8 -> Cpu
skip_if_regs = |cpu, reg1, reg2|
    v1 = cpu |> get_register reg1
    v2 = cpu |> get_register reg2
    cpu |> advance_if (v1 == v2)

skip_if_not_regs : Cpu, U8, U8 -> Cpu
skip_if_not_regs = |cpu, reg1, reg2|
    v1 = cpu |> get_register reg1
    v2 = cpu |> get_register reg2
    cpu |> advance_if (v1 != v2)

skip_if_key : (Cpu, Keypad), U8 -> Cpu
skip_if_key = |(cpu, keypad), reg|
    key = cpu |> get_register reg
    pressed = keypad |> Keypad.is_key_pressed key
    cpu |> advance_if pressed

skip_if_not_key : (Cpu, Keypad), U8 -> Cpu
skip_if_not_key = |(cpu, keypad), reg|
    key = cpu |> get_register reg
    pressed = keypad |> Keypad.is_key_pressed key
    cpu |> advance_if (!pressed)

set_reg_d_timer : (Cpu, Timers), U8 -> Cpu
set_reg_d_timer = |(cpu, timers), reg|
    val = timers |> Timer.get_timer Delay
    cpu |> set_register reg val

set_d_timer_reg : (Cpu, Timers), U8 -> Timers
set_d_timer_reg = |(cpu, timers), reg|
    val = cpu |> get_register reg
    timers |> Timer.set_timer Delay val

set_s_timer_reg : (Cpu, Timers), U8 -> Timers
set_s_timer_reg = |(cpu, timers), reg|
    val = cpu |> get_register reg
    timers |> Timer.set_timer Sound val

set_index : Cpu, U16 -> Cpu
set_index = |cpu, nnn|
    { cpu & i: nnn }

set_nn : Cpu, U8, U8 -> Cpu
set_nn = |cpu, vx, nn|
    cpu |> set_register vx nn

set_regs : Cpu, U8, U8 -> Cpu
set_regs = |cpu, vx, vy|
    valy = cpu |> get_register vy
    cpu |> set_register vx valy

binary_regs : Cpu, U8, U8, (U8, U8 -> U8) -> Cpu
binary_regs = |cpu, vx, vy, op|
    valx = cpu |> get_register vx
    valy = cpu |> get_register vy
    cpu |> set_register vx (op valx valy)

add_index : Cpu, U8 -> Cpu
add_index = |cpu, vx|
    valx = cpu |> get_register vx |> Num.to_u16
    overflows = 0x1000 - cpu.i < valx
    new_cpu = cpu |> set_index Num.add_wrap(cpu.i, valx)
    # TODO: this if should be under a config flag
    if overflows then new_cpu |> set_register 0xF 1 else new_cpu

add_nn : Cpu, U8, U8 -> Cpu
add_nn = |cpu, reg, nn|
    val = cpu |> get_register reg
    cpu |> set_register reg Num.add_wrap(val, nn)

add_regs : Cpu, U8, U8 -> Cpu
add_regs = |cpu, vx, vy|
    valx = cpu |> get_register vx
    valy = cpu |> get_register vy
    overflows = Num.from_bool(0xFF - valx < valy)
    cpu
    |> binary_regs vx vy (|x, y| Num.add_wrap(x, y))
    |> set_register 0xF overflows

sub_regs : Cpu, U8, U8 -> Cpu
sub_regs = |cpu, vx, vy|
    valx = cpu |> get_register vx
    valy = cpu |> get_register vy
    overflows = Num.from_bool(valx >= valy)
    cpu
    |> binary_regs vx vy (|x, y| x - y)
    |> set_register 0xF overflows

sub_regs_i : Cpu, U8, U8 -> Cpu
sub_regs_i = |cpu, vx, vy|
    valx = cpu |> get_register vx
    valy = cpu |> get_register vy
    overflows = Num.from_bool(valy >= valx)
    cpu
    |> binary_regs vx vy (|x, y| y - x)
    |> set_register 0xF overflows

shift_left : Cpu, U8, U8 -> Cpu
shift_left = |cpu, vx, vy|
    valx = cpu |> get_register vx
    bit = (Num.bitwise_and(valx, 0x80) > 0) |> Num.from_bool
    cpu
    # TODO: this should be under a flag
    |> set_regs vx vy
    |> set_register vx Num.shift_left_by(valx, 1)
    |> set_register 0xF bit

shift_right : Cpu, U8, U8 -> Cpu
shift_right = |cpu, vx, vy|
    valx = cpu |> get_register vx
    bit = (Num.bitwise_and(valx, 0x1) > 0) |> Num.from_bool
    cpu
    # TODO: this should be under a flag
    |> set_regs vx vy
    |> set_register vx Num.shift_right_by(valx, 1)
    |> set_register 0xF bit

get_key : (Cpu, Keypad), U8 -> Cpu
get_key = |(cpu, keypad), reg|
    when keypad |> Keypad.some_key_pressed is
        Ok key -> cpu |> set_register reg key
        Err NoKeyPressed -> cpu |> jump (cpu.pc - 2)

font_character : Cpu, U8 -> Cpu
font_character = |cpu, reg|
    val = cpu |> get_register reg
    character = val |> Num.bitwise_and 0x000F |> Num.to_u16
    cpu |> set_index (0x50u16 + character * 5u16)

binary_decimal_conversion : (Cpu, Ram), U8 -> Ram
binary_decimal_conversion = |(cpu, ram), reg|
    byte = cpu |> get_register reg
    digit_1 = (byte // 100) % 10
    digit_2 = (byte // 10) % 10
    digit_3 = byte % 10
    ram |> write_ram [digit_1, digit_2, digit_3] cpu.i

memory_write : (Cpu, Ram), U8 -> (Cpu, Ram)
memory_write = |(cpu, ram), reg|
    to_write =
        List.range({ start: At 0, end: At reg })
        |> List.map |x|
            cpu |> get_register x
    # TODO: this new_cpu should be under a flag
    new_cpu = cpu |> set_index (cpu.i + Num.to_u16(reg + 1))
    new_ram = ram |> Ram.write_ram to_write new_cpu.i
    (new_cpu, new_ram)

memory_read : (Cpu, Ram), U8 -> Cpu
memory_read = |(cpu, ram), reg|
    # TODO: this new_cpu should be under a flag
    new_cpu = cpu |> set_index (cpu.i + 1 + Num.to_u16(reg))
    List.range({ start: At 0u8, end: At reg })
    |> List.walk
        new_cpu
        |acc, x|
            byte = ram |> read_ram (Num.to_u16(x) + acc.i)
            acc |> set_register Num.to_u8(x) byte

draw : (Cpu, Screen, Ram), U8, U8, U8 -> (Cpu, Screen)
draw = |(cpu, screen, ram), regx, regy, n|
    valx = cpu |> get_register regx
    valy = cpu |> get_register regy
    x0 = Num.bitwise_and valx (screen_width - 1)
    y0 = Num.bitwise_and valy (screen_height - 1)
    sprite_bytes =
        List.range({ start: At 0u8, end: Before n })
        |> List.map |ram_index|
            ram |> read_ram (cpu.i + Num.to_u16 ram_index)
    (new_screen, new_collided) =
        sprite_bytes
        |> List.walk_with_index (screen, Bool.false) |acc, byte, row_index|
            List.range({ start: At 0, end: Before 8 })
            |> List.walk acc |(scr, col), bit_index|
                shift = 7u8 - Num.to_u8 bit_index
                bit =
                    byte
                    |> Num.shift_right_by shift
                    |> Num.bitwise_and 1u8
                    |> (|b| b == 1u8)
                x = (x0 + Num.to_u8 bit_index) % screen_width
                y = (y0 + Num.to_u8 row_index) % screen_height
                pixel = scr |> screen_get x y
                if bit then
                    (screen_set(scr, x, y, Bool.not pixel), col or pixel)
                else
                    (scr, col)
    new_cpu = cpu |> set_register 0xF Num.from_bool(new_collided)
    (new_cpu, new_screen)

with_cpu = |cpu| |emu| { emu & cpu }
with_stack = |stack| |emu| { emu & stack }
with_screen = |screen| |emu| { emu & screen }
with_ram = |ram| |emu| { emu & ram }
with_timers = |timers| |emu| { emu & timers }
compose = |f, g| |x| g (f x)

decode = |emu, bytes|
    { cpu, ram, stack, screen, keypad, timers } = emu

    n1 = bytes |> Num.shift_right_by 12 |> Num.to_u8 |> Num.bitwise_and 0x0Fu8
    n2 = bytes |> Num.shift_right_by 8 |> Num.to_u8 |> Num.bitwise_and 0x0Fu8
    n3 = bytes |> Num.shift_right_by 4 |> Num.to_u8 |> Num.bitwise_and 0x0Fu8
    n4 = bytes |> Num.to_u8 |> Num.bitwise_and 0x0Fu8

    nn = Num.bitwise_and 0x00FF bytes |> Num.to_u8
    nnn = Num.bitwise_and 0x0FFF bytes

    when (n1, n2, n3, n4) is
        (0x0, 0x0, 0xE, 0x0) -> screen_clear screen |> with_screen
        (0x0, _, _, 0xE) ->
            (c, s) = ret (cpu, stack)
            compose (with_cpu c) (with_stack s)

        (0x1, _, _, _) -> jump cpu nnn |> with_cpu
        (0x2, _, _, _) ->
            (c, s) = sub_routine (cpu, stack) nnn
            compose (with_cpu c) (with_stack s)

        (0x3, _, _, _) -> skip_if_reg cpu n2 nn |> with_cpu
        (0x4, _, _, _) -> skip_if_not_reg cpu n2 nn |> with_cpu
        (0x5, _, _, _) -> skip_if_regs cpu n2 n3 |> with_cpu
        (0x6, _, _, _) -> set_nn cpu n2 nn |> with_cpu
        (0x7, _, _, _) -> add_nn cpu n2 nn |> with_cpu
        (0x8, _, _, 0x0) -> set_regs cpu n2 n3 |> with_cpu
        (0x8, _, _, 0x1) -> binary_regs cpu n2 n3 Num.bitwise_or |> with_cpu
        (0x8, _, _, 0x2) -> binary_regs cpu n2 n3 Num.bitwise_and |> with_cpu
        (0x8, _, _, 0x3) -> binary_regs cpu n2 n3 Num.bitwise_xor |> with_cpu
        (0x8, _, _, 0x4) -> add_regs cpu n2 n3 |> with_cpu
        (0x8, _, _, 0x5) -> sub_regs cpu n2 n3 |> with_cpu
        (0x8, _, _, 0x6) -> shift_right cpu n2 n3 |> with_cpu
        (0x8, _, _, 0x7) -> sub_regs_i cpu n2 n3 |> with_cpu
        (0x8, _, _, 0xE) -> shift_left cpu n2 n3 |> with_cpu
        (0x9, _, _, _) -> skip_if_not_regs cpu n2 n3 |> with_cpu
        (0xA, _, _, _) -> set_index cpu nnn |> with_cpu
        # TODO: config for using jump_offset_v0 instead
        (0xB, _, _, _) -> jump_offset_v0 cpu nnn |> with_cpu
        (0xC, _, _, _) -> random cpu n2 nn |> with_cpu
        (0xD, _, _, _) ->
            (c, s) = draw (cpu, screen, ram) n2 n3 n4
            compose (with_cpu c) (with_screen s)

        (0xE, _, 0x9, 0xE) -> skip_if_key (cpu, keypad) n2 |> with_cpu
        (0xE, _, 0xA, 0x1) -> skip_if_not_key (cpu, keypad) n2 |> with_cpu
        (0xF, _, 0x0, 0x7) -> set_reg_d_timer (cpu, timers) n2 |> with_cpu
        (0xF, _, 0x0, 0xA) -> get_key (cpu, keypad) n2 |> with_cpu
        (0xF, _, 0x1, 0x5) -> set_d_timer_reg (cpu, timers) n2 |> with_timers
        (0xF, _, 0x1, 0x8) -> set_s_timer_reg (cpu, timers) n2 |> with_timers
        (0xF, _, 0x1, 0xE) -> add_index cpu n2 |> with_cpu
        (0xF, _, 0x2, 0x9) -> font_character cpu n2 |> with_cpu
        (0xF, _, 0x3, 0x3) -> binary_decimal_conversion (cpu, ram) n2 |> with_ram
        (0xF, _, 0x5, 0x5) ->
            (c, r) = memory_write (cpu, ram) n2
            compose (with_cpu c) (with_ram r)

        (0xF, _, 0x6, 0x5) -> memory_read (cpu, ram) n2 |> with_cpu
        _ -> |_| emu

exec = |emu|
    b1 = read_ram emu.ram (emu.cpu.pc) |> Num.to_u16
    b2 = read_ram emu.ram (emu.cpu.pc + 1) |> Num.to_u16
    bytes = Num.shift_left_by b1 8 |> Num.bitwise_or b2
    cpu = emu.cpu |> advance_pc
    em = { emu & cpu }
    instruction = decode em bytes
    instruction em
