module [Keypad, is_key_pressed, some_key_pressed, initial_keypad]

Keypad : List Bool

initial_keypad = List.repeat Bool.false 0x10

is_key_pressed : Keypad, U8 -> Bool
is_key_pressed = |keypad, key|
    when keypad |> List.get Num.to_u64(key) is
        Err(OutOfBounds) -> crash "Illegal read to keypad"
        Ok(pressed) -> pressed

some_key_pressed : Keypad -> Result U8 [NoKeyPressed]
some_key_pressed = |keypad|
    keypad
    |> List.find_first_index (|x| x)
    |> Result.map_both
        (|ok| Num.to_u8 ok)
        (|_| NoKeyPressed)
