Timer : [Sound, Delay]

Timers :: { sound : U8, delay : U8 }.{
	new : Timers
	new = { sound: 0, delay: 0 }

	get : Timers, Timer -> U8
	get = |timers, timer|
		match timer {
			Sound => timers.sound
			Delay => timers.delay
		}

	set : Timers, Timer, U8 -> Timers
	set = |timers, timer, to|
		match timer {
			Sound => { ..timers, sound: to }
			Delay => { ..timers, delay: to }
		}

	tick : Timers, Timer -> Timers
	tick = |timers, timer|
		match timer {
			Sound => { ..timers, sound: if timers.sound.is_zero() 0 else (timers.sound - 1) }
			Delay => { ..timers, delay: if timers.delay.is_zero() 0 else (timers.delay - 1) }
		}
}
