module [Timers, get_timer, set_timer, tick_timer, initial_timers]

Timer : [Sound, Delay]
Timers : { sound : U8, delay : U8 }

initial_timers = { sound: 0u8, delay: 0u8 }

get_timer : Timers, Timer -> U8
get_timer = |timers, timer|
    when timer is
        Sound -> timers.sound
        Delay -> timers.delay

set_timer : Timers, Timer, U8 -> Timers
set_timer = |timers, timer, to|
    when timer is
        Sound -> { timers & sound: to }
        Delay -> { timers & delay: to }

tick_timer : Timers, Timer -> Timers
tick_timer = |timers, timer|
    when timer is
        Sound -> { timers & sound: Num.sub_wrap(timers.sound, 1) }
        Delay -> { timers & delay: Num.sub_wrap(timers.delay, 1) }
