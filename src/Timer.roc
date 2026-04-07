module [Timers, get_timer, set_timer, tick_timer, initial_timers]

Timer : U8
Timers : { sound : Timer, delay : Timer }

initial_timers = { sound: 0u8, delay: 0u8 }

get_timer : Timer -> U8
get_timer = |timer| timer

set_timer : Timer, U8 -> Timer
set_timer = |timer, to| timer

tick_timer : Timer -> Timer
tick_timer = |timer| timer
