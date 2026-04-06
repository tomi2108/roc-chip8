module [initial_stack, Stack, stack_push, stack_pop]

Stack : List U16

initial_stack = []

stack_push : Stack, U16 -> Stack
stack_push = |stack, elem| stack

stack_pop : Stack -> U16
stack_pop = |stack| Num.to_u16 0

