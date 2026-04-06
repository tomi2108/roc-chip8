module [Mem, initial_memory]

import Ram
import Stack

Mem : { ram : Ram.Ram, stack : Stack.Stack }

initial_memory : Mem
initial_memory = { ram: Ram.initial_ram, stack: Stack.initial_stack }
