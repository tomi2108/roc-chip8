module [initial_stack, Stack, stack_push, stack_pop]

Stack : List U8

initial_stack = []

stack_push : Stack -> Stack
stack_push = |stack| stack

stack_pop : Stack -> U8
stack_pop = |stack| Num.to_u8 0

