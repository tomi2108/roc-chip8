Stack :: { data : List(U16) }.{
	new : Stack
	new = { data: [] }

	push : Stack, U16 -> Stack
	push = |stack, elem| { ..stack, data: [elem].concat(stack.data) }

	pop : Stack -> (U16, Stack)
	pop = |stack|
		match stack.data {
			[elem, .. as rest] => (elem, { ..stack, data: rest })
			[] => {
				crash "Illegal read to stack"
			}
		}
}
