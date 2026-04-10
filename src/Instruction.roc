import Cpu
import Ram
import Screen
import Stack
import Keypad
import Timers
import rand.Random
import pf.Utc

Instruction :: [].{
	exec = |emu| {
		b1 = emu.ram.read(emu.cpu.pc).to_u16()
		b2 = emu.ram.read(emu.cpu.pc + 1).to_u16()
		bytes = b1.shift_left_by(8).bitwise_or(b2)
		instruction = decode({ ..emu, cpu: emu.cpu.advance() }, bytes)
		instruction(em)
	}
}

random : Cpu, U8, U8 -> Cpu
random = |cpu, reg, nn| {
	generator = Random.bounded_u8(0x0, 0xFF)
	{ value: rand } = Random
		.seed(Utc.to_millis_since_epoch(Utc.now!({})).to_u32())
		.step(generator)
	cpu.set_register(reg, rand.bitwise_and(nn))
}

jump_offset : Cpu, U8, U16 -> Cpu
jump_offset = |cpu, reg, nnn| {
	offset = nnn + cpu.get_register(reg).to_u16()
	cpu.jump(offset)
}

jump_offset_v0 : Cpu, U16 -> Cpu
jump_offset_v0 = |cpu, nnn| cpu->jump_offset(0x0, nnn)

ret : (Cpu, Stack) -> (Cpu, Stack)
ret = |(cpu, stack)| {
	(bytes, new_stack) = stack.pop()
	new_cpu = cpu.jump(bytes)
	(new_cpu, new_stack)
}

sub_routine : (Cpu, Stack), U16 -> (Cpu, Stack)
sub_routine = |(cpu, stack), nnn| {
	new_stack = stack.push(cpu.pc)
	new_cpu = cpu.jump(nnn)
	(new_cpu, new_stack)
}

skip_if_reg : Cpu, U8, U8 -> Cpu
skip_if_reg = |cpu, reg, nn| {
	val = cpu.get_register(reg)
	cpu.advance_if(val == nn)
}

skip_if_not_reg : Cpu, U8, U8 -> Cpu
skip_if_not_reg = |cpu, reg, nn| {
	val = cpu.get_register(reg)
	cpu.advance_if(val != nn)
}

skip_if_regs : Cpu, U8, U8 -> Cpu
skip_if_regs = |cpu, reg1, reg2| {
	v1 = cpu.get_register(reg1)
	v2 = cpu.get_register(reg2)
	cpu.advance_if(v1 == v2)
}

skip_if_not_regs : Cpu, U8, U8 -> Cpu
skip_if_not_regs = |cpu, reg1, reg2| {
	v1 = cpu.get_register(reg1)
	v2 = cpu.get_register(reg2)
	cpu.advance_if(v1 != v2)
}

skip_if_key : (Cpu, Keypad), U8 -> Cpu
skip_if_key = |(cpu, keypad), reg| {
	key = cpu.get_register(reg)
	pressed = keypad.is_key_pressed(key)
	cpu.advance_if(pressed)
}

skip_if_not_key : (Cpu, Keypad), U8 -> Cpu
skip_if_not_key = |(cpu, keypad), reg| {
	key = cpu.get_register(reg)
	pressed = keypad.is_key_pressed(key)
	cpu.advance_if(!pressed)
}

set_reg_d_timer : (Cpu, Timers), U8 -> Cpu
set_reg_d_timer = |(cpu, timers), reg| {
	val = timers.get(Delay)
	cpu.set_register(reg, val)
}

set_d_timer_reg : (Cpu, Timers), U8 -> Timers
set_d_timer_reg = |(cpu, timers), reg| {
	val = cpu.get_register(reg)
	timers.set(Delay, val)
}

set_s_timer_reg : (Cpu, Timers), U8 -> Timers
set_s_timer_reg = |(cpu, timers), reg| {
	val = cpu.get_register(reg)
	timers.set(Sound, val)
}

set_nn : Cpu, U8, U8 -> Cpu
set_nn = |cpu, vx, nn| cpu.set_register(vx, nn)

set_regs : Cpu, U8, U8 -> Cpu
set_regs = |cpu, vx, vy| {
	valy = cpu.get_register(vy)
	cpu.set_register(vx, valy)
}

binary_regs : Cpu, U8, U8, (U8, U8 -> U8) -> Cpu
binary_regs = |cpu, vx, vy, op| {
	valx = cpu.get_register(vx)
	valy = cpu.get_register(vy)
	cpu.set_register(vx, op(valx, valy))
}

add_index : Cpu, U8 -> Cpu
add_index = |cpu, vx| {
	valx = cpu.get_register(vx).to_u16()
	overflows = 0x1000 - cpu.i < valx
	new_cpu = cpu.set_index(cpu.i.add_wrap(valx))
	# TODO: this if should be under a config flag
	if overflows new_cpu.set_register(0xF, 1) else new_cpu
}

add_nn : Cpu, U8, U8 -> Cpu
add_nn = |cpu, reg, nn| {
	val = cpu.get_register(reg)
	cpu.set_register(reg, val.add_wrap(nn))
}

add_regs : Cpu, U8, U8 -> Cpu
add_regs = |cpu, vx, vy| {
	valx = cpu.get_register(vx)
	valy = cpu.get_register(vy)
	overflows = U8.from_bool(0xFF - valx < valy)
	cpu
		->binary_regs(vx, vy, |x, y| x.add_wrap(y))
		.set_register(0xF, overflows)
}

sub_regs : Cpu, U8, U8 -> Cpu
sub_regs = |cpu, vx, vy| {
	valx = cpu.get_register(vx)
	valy = cpu.get_register(vy)
	overflows = U8.from_bool(valx >= valy)
	cpu
		->binary_regs(vx, vy, |x, y| x - y)
		.set_register(0xF, overflows)
}

sub_regs_i : Cpu, U8, U8 -> Cpu
sub_regs_i = |cpu, vx, vy| {
	valx = cpu.get_register(vx)
	valy = cpu.get_register(vy)
	overflows = U8.from_bool(valy >= valx)
	cpu
		->binary_regs(vx, vy, |x, y| y - x)
		.set_register(0xF, overflows)
}

shift_left : Cpu, U8, U8 -> Cpu
shift_left = |cpu, vx, vy| {
	valx = cpu.get_register(vx)
	bit = U8.from_bool(valx.bitwise_and(0x80) > 0)
	cpu
	# TODO: this should be under a flag
		->set_regs(vx, vy)
		.set_register(vx, valx.shift_left_by(1))
		.set_register(0xF, bit)
}

shift_right : Cpu, U8, U8 -> Cpu
shift_right = |cpu, vx, vy| {
	valx = cpu.get_register(vx)
	bit = U8.from_bool(valx.bitwise_and(0x1) > 0)
	cpu
	# TODO: this should be under a flag
		->set_regs(vx, vy)
		.set_register(vx, valx.shift_right_by(1))
		.set_register(0xF, bit)
}

get_key : (Cpu, Keypad), U8 -> Cpu
get_key = |(cpu, keypad), reg| {
	match keypad.some_key_pressed() {
		Ok(key) => cpu.set_register(reg, key)
		Err(NoKeyPressed) => cpu.jump(cpu.pc - 2)
	}
}

font_character : Cpu, U8 -> Cpu
font_character = |cpu, reg| {
	val = cpu.get_register(reg)
	character = val.bitwise_and(0x000F).to_u16()
	cpu.set_index(0x50 + character * 5)
}

binary_decimal_conversion : (Cpu, Ram), U8 -> Ram
binary_decimal_conversion = |(cpu, ram), reg| {
	byte = cpu.get_register(reg)
	digit_1 = (byte // 100) % 10
	digit_2 = (byte // 10) % 10
	digit_3 = byte % 10
	ram.write([digit_1, digit_2, digit_3], cpu.i)
}

memory_write : (Cpu, Ram), U8 -> (Cpu, Ram)
memory_write = |(cpu, ram), reg| {
	to_write = 0.to(reg).map(|x| cpu.get_register(x))
	# TODO: this new_cpu should be under a flag
	new_cpu = cpu.set_index(cpu.i + 1 + reg.to_u16())
	new_ram = ram.write(to_write, new_cpu.i)
	(new_cpu, new_ram)
}

memory_read : (Cpu, Ram), U8 -> Cpu
memory_read = |(cpu, ram), reg| {
	# TODO: this new_cpu should be under a flag
	new_cpu = cpu.set_index(cpu.i + 1 + reg.to_u16())
	0.to(reg).fold(
		new_cpu,
		|acc, x| {
			byte = ram.read(x.to_u16() + acc.i)
			acc.set_register(x.to_u8(x), byte)
		},
	)
}

draw : (Cpu, Screen, Ram), U8, U8, U8 -> (Cpu, Screen)
draw = |(cpu, screen, ram), regx, regy, n| {
	valx = cpu.get_register(regx)
	valy = cpu.get_register(regy)
	x0 = valx.bitwise_and(screen.width - 1)
	y0 = valy.bitwise_and(screen.height - 1)
	sprite_bytes = 
		0.until(n)
			.map(|ram_index| ram.read(cpu.i + ram_index.to_u16()))

	(new_screen, new_collided) = 
		sprite_bytes.walk_with_index(
			(screen, Bool.False),
			|acc, byte, row_index|
				0.until(8)
					.walk(
						acc,
						|(scr, col), bit_index| {
							shift = 7 - bit_index.to_u8()
							bit = (byte.shift_right_by(shift).bitwise_and(1)) == 1

							x = (x0 + bit_index.to_u8()) % scr.width
							y = (y0 + row_index.to_u8()) % scr.height
							pixel = scr.get(x, y)
							if bit (scr.set(x, y, !pixel), col or pixel)
							else (scr, col)
						},
					),
		)
	new_cpu = cpu.set_register(0xF, U8.from_bool(new_collided))
	(new_cpu, new_screen)
}

with_cpu = |cpu| |emu| { ..emu, cpu }
with_stack = |stack| |emu| { ..emu, stack }
with_screen = |screen| |emu| { ..emu, screen }
with_ram = |ram| |emu| { ..emu, ram }
with_timers = |timers| |emu| { ..emu, timers }
compose = |f, g| |x| g(f(x))

decode = |emu, bytes| {
	{ cpu, ram, stack, screen, keypad, timers } = emu

	n1 = bytes.shift_right_by(12).to_u8().bitwise_and(0x0F)
	n2 = bytes.shift_right_by(8).to_u8().bitwise_and(0x0F)
	n3 = bytes.shift_right_by(4).to_u8().bitwise_and(0x0F)
	n4 = bytes.to_u8().bitwise_and(0x0F)

	nn = bytes.to_u8().bitwise_and(0x00FF)
	nnn = bytes.bitwise_and(0x0FFF)

	match (n1, n2, n3, n4) {
		(0x0, 0x0, 0xE, 0x0) => screen.clear()->with_screen()
		(0x0, _, _, 0xE) => {
			(c, s) = (cpu, stack)->ret()
			compose(with_cpu(c), with_stack(s))
		}

		(0x1, _, _, _) => cpu.jump(nnn)->with_cpu()
		(0x2, _, _, _) => {
			(c, s) = (cpu, stack)->sub_routine(nnn)
			compose(with_cpu(c), with_stack(s))
		}

		(0x3, _, _, _) => cpu->skip_if_reg(n2, nn)->with_cpu()
		(0x4, _, _, _) => cpu->skip_if_not_reg(n2, nn)->with_cpu()
		(0x5, _, _, _) => cpu->skip_if_regs(n2, n3)->with_cpu()
		(0x6, _, _, _) => cpu->set_nn(n2, nn)->with_cpu()
		(0x7, _, _, _) => cpu->add_nn(n2, nn)->with_cpu()
		(0x8, _, _, 0x0) => cpu->set_regs(n2, n3)->with_cpu()
		(0x8, _, _, 0x1) => cpu->binary_regs(n2, n3, U8.bitwise_or)->with_cpu()
		(0x8, _, _, 0x2) => cpu->binary_regs(n2, n3, U8.bitwise_and)->with_cpu()
		(0x8, _, _, 0x3) => cpu->binary_regs(n2, n3, U8.bitwise_xor)->with_cpu()
		(0x8, _, _, 0x4) => cpu->add_regs(n2, n3)->with_cpu()
		(0x8, _, _, 0x5) => cpu->sub_regs(n2, n3)->with_cpu()
		(0x8, _, _, 0x6) => cpu->shift_right(n2, n3)->with_cpu()
		(0x8, _, _, 0x7) => cpu->sub_regs_i(n2, n3)->with_cpu()
		(0x8, _, _, 0xE) => cpu->shift_left(n2, n3)->with_cpu()
		(0x9, _, _, _) => cpu->skip_if_not_regs(n2, n3)->with_cpu()
		(0xA, _, _, _) => cpu.set_index(nnn)->with_cpu()
		# TODO: config for using jump_offset_v0 instead
		(0xB, _, _, _) => cpu->jump_offset_v0(nnn)->with_cpu()
		(0xC, _, _, _) => cpu->random(n2, nn)->with_cpu()
		(0xD, _, _, _) => {
			(c, s) = (cpu, screen, ram)->draw(n2, n3, n4)
			compose(with_cpu(c), with_screen(s))
		}

		(0xE, _, 0x9, 0xE) => (cpu, keypad)->skip_if_key(n2)->with_cpu()
		(0xE, _, 0xA, 0x1) => (cpu, keypad)->skip_if_not_key(n2)->with_cpu()
		(0xF, _, 0x0, 0x7) => (cpu, timers)->set_reg_d_timer(n2)->with_cpu()
		(0xF, _, 0x0, 0xA) => (cpu, keypad)->get_key(n2)->with_cpu()
		(0xF, _, 0x1, 0x5) => (cpu, timers)->set_d_timer_reg(n2)->with_timers()
		(0xF, _, 0x1, 0x8) => (cpu, timers)->set_s_timer_reg(n2)->with_timers()
		(0xF, _, 0x1, 0xE) => cpu->add_index(n2)->with_cpu()
		(0xF, _, 0x2, 0x9) => cpu->font_character(n2)->with_cpu()
		(0xF, _, 0x3, 0x3) => (cpu, ram)->binary_decimal_conversion(n2)->with_ram()
		(0xF, _, 0x5, 0x5) => {
			(c, r) = (cpu, ram)->memory_write(n2)
			compose(with_cpu(c), with_ram(r))
		}

		(0xF, _, 0x6, 0x5) => (cpu, ram)->memory_read(n2)->with_cpu()
		_ => |_| emu
	}
}
