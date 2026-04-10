Cpu :: {
	rs : List(U8),
	pc : U16,
	i : U16,
}.{

	new : Cpu
	new = {
		rs: List.repeat(0, 16),
		pc: 0x200,
		i: 0,
	}

	set_index : Cpu, U16 -> Cpu
	set_index = |cpu, nnn| { ..cpu, i: nnn }

	jump : Cpu, U16 -> Cpu
	jump = |cpu, nnn| { ..cpu, pc: nnn }

	advance : Cpu -> Cpu
	advance = |cpu| { ..cpu, pc: cpu.pc + 2 }

	advance_if : Cpu, Bool -> Cpu
	advance_if = |cpu, condition| if condition cpu.advance() else cpu

	set_register : Cpu, U8, U8 -> Cpu
	set_register = |cpu, reg, val| {
		idx = reg.to_u64()

		before = cpu.rs.take_first(idx)
		after = cpu.rs.drop_first(idx + 1)

		{ ..cpu, rs: before.concat([val].concat(after)) }
	}

	get_register : Cpu, U8 -> U8
	get_register = |cpu, reg|
		match cpu.rs.get(reg.to_u64()) {
			Ok(read) => read
			Err(_) => {
				crash "Illegal read to registers"
			}
		}
}
