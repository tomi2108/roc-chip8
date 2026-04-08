module [Cpu, initial_cpu, advance_if, advance_pc, get_register, set_register]

Cpu : { rs : List U8, pc : U16, i : U16 }

initial_cpu : Cpu
initial_cpu = {
    rs: (List.repeat 0 16 |> List.map Num.to_u8),
    pc: 0x200,
    i: 0,
}

advance_pc : Cpu -> Cpu
advance_pc = |cpu| { cpu & pc: cpu.pc + 2 }

advance_if : Cpu, Bool -> Cpu
advance_if = |cpu, condition| if condition then advance_pc cpu else cpu

set_register : Cpu, U8, U8 -> Cpu
set_register = |cpu, reg, val|
    { cpu & rs: List.set cpu.rs Num.to_u64(reg) val }

get_register : Cpu, U8 -> U8
get_register = |cpu, reg|
    when List.get cpu.rs Num.to_u64(reg) is
        Err _ -> crash "Illegal read to registers"
        Ok read -> Num.to_u8(read)

