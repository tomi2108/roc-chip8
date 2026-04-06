module [Timers, get_timer, set_timer, tick_timer]

Timer : U8
Timers : { sound : Timer, delay : Timer }

get_timer : Timer -> U8
get_timer = |timer| timer

set_timer : Timer, U8 -> Timer
set_timer = |timer, to| timer

tick_timer : Timer -> Timer
tick_timer = |timer| timer
