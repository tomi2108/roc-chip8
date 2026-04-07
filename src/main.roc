app [main!] {
    pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.20.0/X73hGh05nNTkDHU06FHC0YfFaQB1pimX7gncRcao5mU.tar.br",
    rand: "https://github.com/lukewilliamboswell/roc-random/releases/download/0.5.0/yDUoWipuyNeJ-euaij4w_ozQCWtxCsywj68H0PlJAdE.tar.br",
}

import pf.Stdout
import Emulator
import Cartdrige
import Timer
import Screen
import pf.Sleep

fps = 10

clear_sequence = [27, 91, 50, 74, 27, 91, 72]
clear_screen! = |_|
    c = Str.from_utf8(clear_sequence)?
    Stdout.line!(c)

render! = |state|
    new_state =
        state
        |> Emulator.exec_cpu
    _ = clear_screen!
    Screen.screen_draw! new_state.screen
    new_timers =
        new_state.timers
        |> Timer.tick_timer Sound
        |> Timer.tick_timer Delay
    Sleep.millis! (1000 // fps)
    render! { new_state & timers: new_timers }

main! = |_args|
    filename = "TETRIS"

    initial_state = Emulator.initial_state
    mem = initial_state.memory

    loaded_ram =
        mem.ram
        |> Cartdrige.load_cartridge! filename

    render! { initial_state & memory: { mem & ram: loaded_ram } }

