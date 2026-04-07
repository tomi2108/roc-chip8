module [Keypad, is_key_pressed, some_key_pressed, initial_keypad]

Keypad : List Bool

initial_keypad = List.repeat Bool.false 0x10

is_key_pressed : Keypad, U8 -> Bool
is_key_pressed = |keypad, key| Bool.true

some_key_pressed : Keypad -> Result U8 [NoKeyPressed]
some_key_pressed = |keypad| Ok(0)
