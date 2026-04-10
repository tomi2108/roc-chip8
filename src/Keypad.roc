Keypad :: { data : List(Bool) }.{

	new : Keypad
	new = { data: List.repeat(False, 0x10) }

	is_key_pressed : Keypad, U8 -> Bool
	is_key_pressed = |keypad, key|
		match keypad.data.get(key.to_u64()) {
			Ok(pressed) => pressed
			Err(OutOfBounds) => {
				crash "Illegal read to keypad"
			}
		}

	some_key_pressed : Keypad -> Try(U8, [NoKeyPressed])
	some_key_pressed = |keypad|
    # TODO: I think we need index here... and I think there is
    # no way to do this currently
		keypad.data
			.keep_if(|x| x)
      .first()
			.map_both(|ok| ok.to_u8(), |_| NoKeyPressed)
}
