module [initial_stack, Stack, stack_push, stack_pop]

Stack : List U16

initial_stack = []

stack_push : Stack, U16 -> Stack
stack_push = |stack, elem| stack |> List.prepend elem

stack_pop : Stack -> (U16, Stack)
stack_pop = |stack|
    when stack is
        [elem, .. as rest] -> (elem, rest)
        [] -> crash "Illegal stack read"
