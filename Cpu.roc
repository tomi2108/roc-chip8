module [exec_cpu]

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

exec_cpu : Ram, Cpu -> Cpu
exec_cpu = |ram, cpu| 
  byte_1 = Memory.read_ram ram cpu.pc
  byte_2 = Memory.read_ram ram (cpu.pc+1)
  return cpu
