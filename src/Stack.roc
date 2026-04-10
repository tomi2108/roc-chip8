Stack :: { data : List(U16) }.{
	new : Stack
	new = { data: [] }

	push : Stack, U16 -> Stack
	push = |stack, elem|
		stack.data.prepend(elem)

	pop : Stack -> (U16, Stack)
	pop = |stack|
		match stack.data {
			[elem, .. as rest] => (elem, { data: rest })
			# TODO: do  something with this
			[] => (1, { data: [] })
		}
}
