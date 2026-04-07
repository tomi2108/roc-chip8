module [Screen, screen_clear, screen_get, screen_set, screen_height, screen_width, initial_screen,screen_draw!]

Screen : List (List Bool)

screen_width = 64
screen_height = 32

initial_screen = List.repeat (List.repeat Bool.false screen_height) screen_width

screen_clear : Screen -> Screen
screen_clear = |_screen| initial_screen

screen_set : Screen, U8, U8, Bool -> Screen
screen_set = |screen, x, y, to|
    when List.get(screen, Num.to_u64 x) is
        Err(OutOfBounds) -> crash "Illegal screen set"
        Ok(row) ->
            List.set(
                screen,
                Num.to_u64 x,
                List.set(row, Num.to_u64 y, to),
            )

screen_get : Screen, U8, U8 -> Bool
screen_get = |screen, x, y|
    when
        Result.try(
            List.get(screen, Num.to_u64 x),
            |row| List.get(row, Num.to_u64 y),
        )
    is
        Ok(value) -> value
        Err(OutOfBounds) -> crash "Illegal screen get"

screen_draw! : Screen => {}
screen_draw! = |screen|
    {}
