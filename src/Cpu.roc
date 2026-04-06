module [Cpu, exec_instruction, initial_cpu]

import Memory

Cpu : {
    rx : List U8,
    pc : U16,
    i : U16,
}

initial_cpu : Cpu
initial_cpu = {
    rx: (List.repeat 16 0 |> List.map Num.to_u8),
    pc: 0x200,
    i: 0,
}

exec_instruction : { memory : Memory.Mem, cpu : Cpu }, U16 -> { memory : Memory.Mem, cpu : Cpu }
exec_instruction = |state, bytes| state
