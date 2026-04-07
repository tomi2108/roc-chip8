app [main!] {
    pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.20.0/X73hGh05nNTkDHU06FHC0YfFaQB1pimX7gncRcao5mU.tar.br",
    rand: "https://github.com/lukewilliamboswell/roc-random/releases/download/0.5.0/yDUoWipuyNeJ-euaij4w_ozQCWtxCsywj68H0PlJAdE.tar.br",
}

import Emulator
import Timer
import Screen

render! = |state|
    new_state =
        state
        |> Emulator.exec_cpu
    Screen.screen_draw! new_state.screen
    new_timers =
        new_state.timers
        |> Timer.tick_timer Sound
        |> Timer.tick_timer Delay
    render! { new_state & timers: new_timers }

main! = |_args|
    initial_state = Emulator.initial_state
    render! initial_state
