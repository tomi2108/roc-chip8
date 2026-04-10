import pf.Stdout

Screen :: {
	data : List(List(Bool)),
	width : U8,
	height : U8,
}.{

	new : U8, U8 -> Screen
	new = |width, height| {
		data: 0.U8.to(height).map(|_| 0.U8.to(width).map(|_| False)),
		width,
		height,
	}

	clear : Screen -> Screen
	clear = |screen| new(screen.width, screen.height)

	set : Screen, U8, U8, Bool -> Screen
	set = |screen, x, y, to| {
		xi = x.to_u64()
		yi = y.to_u64()
		row = 
			match List.get(screen.data, yi) {
				Ok(r) => r
				Err(_) => {
					crash "Illegal write to screen"
				}
			}

		new_row = row
			.take_first(xi)
			.concat(
				[to].concat(
					row.drop_first(xi + 1),
				),
			)

		new_data = screen.data
			.take_first(yi)
			.concat(
				[new_row].concat(screen.data.drop_first(yi + 1)),
			)

		{ ..screen, data: new_data }
	}

	get : Screen, U8, U8 -> Bool
	get = |screen, x, y| {
		result = screen.data.get(y.to_u64())
			.map_ok(|row| row.get(x.to_u64()))
			.map_ok(|inner| inner ?? False)

		match result {
			Ok(value) => value
			Err(_) => {
				crash "Illegal read to screen"
			}
		}
	}

	draw! : Screen => {}
	draw! = |screen|
		for row in screen.data {
			slice = row
				.map(|col| if col "█" else "░")
				.fold("", |a, b| a.concat(b))

			Stdout.line!(slice)
		}
}
