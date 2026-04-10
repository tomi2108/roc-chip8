import pf.Stdout

Screen :: {
	data : List(List(Bool)),
	width : U8,
	height : U8,
}.{

	new : Screen
	new = {
		data: 0.to(height).map(|_| 0.to(width).map(|_| False)),
		width: 64,
		height: 32,
	}

	clear : Screen -> Screen
	clear = |_screen| new

	set : Screen, U8, U8, Bool -> Screen
	set = |screen, x, y, to|
		match screen.data.get(y.to_u64()) {
			Ok(row) =>
				screen.data.set(
					y.to_u64(),
					row.set(x.to_u64(), to),
				)
			Err(OutOfBounds) => {
				crash "Illegal write to screen"
			}
		}

	get : Screen, U8, U8 -> Bool
	get = |screen, x, y|
		match Try.try(
			screen.data.get(y.to_u64()),
			|row| row.get(x.to_u64()),
		) {
			Ok(value) => value
			Err(OutOfBounds) => {
				crash "Illlegal read to screen"
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
