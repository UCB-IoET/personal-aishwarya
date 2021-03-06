----------------------------------------------
-- Starter Shield Module
--
-- Provides a module for each resource on the starter shield
-- in a cord-based concurrency model
-- and mapping to lower level abstraction provided
-- by storm.io @ toolchains/storm_elua/src/platform/storm/libstorm.c
----------------------------------------------

require("storm") -- libraries for interfacing with the board and kernel
require("cord") -- scheduler / fiber library
----------------------------------------------
-- Shield module for starter shield
----------------------------------------------
local shield = {}

----------------------------------------------
-- LED module
-- provide basic LED functions
----------------------------------------------
local LED = {}

LED.pins = {["blue"]="D2",["green"]="D3",["red"]="D4",["red2"]="D5"}

LED.start = function()
-- configure LED pins for output
   storm.io.set_mode(storm.io.OUTPUT, storm.io.D2,
		     storm.io.D3,
		     storm.io.D4,
		     storm.io.D5)
end

LED.stop = function()
-- configure pins to a low power state
end

-- LED color functions
-- These should rarely be used as an active LED burns a lot of power
LED.on = function(color)
   storm.io.set(1,storm.io[LED.pins[color]])
end

LED.off = function(color)
   storm.io.set(0,storm.io[LED.pins[color]])
end

LED.flash=function(color,duration)
   local pin = LED.pins[color] or LED.pins["red2"]
   duration = duration or 10
   storm.io.set(1,storm.io[pin])
   storm.os.invokeLater(duration*storm.os.MILLISECOND,
			function() 
			   storm.io.set(0,storm.io[pin]) 
			end)
end

----------------------------------------------
-- Buzz module
-- provide basic buzzer functions
----------------------------------------------
local Buzz = {}

Buzz.start = function ()
    storm.io.set_mode(storm.io.OUTPUT, storm.io.D6)
end

Buzz.go = function(period)
    Buzz.continue_buzzing = true
    storm.os.invokeLater(period, function ()
        storm.io.set(1, storm.io.D6)
        storm.io.set(0, storm.io.D6)
        if Buzz.continue_buzzing then
            Buzz.go(period)
        end
    end)
end

Buzz.stop = function()
    Buzz.continue_buzzing = false
end

----------------------------------------------
-- Button module
-- provide basic button functions
----------------------------------------------
local Button = {}

Button.pins = {["left"]="D11", ["middle"]="D10", ["right"]="D9"}

Button.start = function() 
    storm.io.set_mode(storm.io.INPUT, storm.io.D9)
    storm.io.set_mode(storm.io.INPUT, storm.io.D10)
    storm.io.set_mode(storm.io.INPUT, storm.io.D11)
    storm.io.set_pull(storm.io.PULL_UP, storm.io.D9)
    storm.io.set_pull(storm.io.PULL_UP, storm.io.D10)
    storm.io.set_pull(storm.io.PULL_UP, storm.io.D11)
end

-- Get the current state of the button
-- can be used when polling buttons
-- BUTTON is "left", "right", or "middle"
-- Returns 1 if the button is not pressed and 0 if it is pressed
-- Button.pressed = function(button)
--  return storm.io.get(storm.io[Button.pins[button]])
-- end

-------------------
-- Button events
-- each registers a call back on a particular transition of a button
-- valid transitions are:
--   FALLING - when a button is pressed
--   RISING - when it is released
--   CHANGE - either case
-- Only one transition can be in effect for a button
-- must be used with cord.enter_loop
-- none of these are debounced.
-------------------
--[[
Button.whenever = function(button, transition, action)
    local pin = storm.io[Button.pins[button]]
--[[    return storm.io.watch_all(storm.io[transition], pin, action)
end

Button.when = function(button, transition, action)
    local pin = storm.io[Button.pins[button]]
--[[    return storm.io.watch_single(storm.io[transition], pin, action)
end

Button.wait = function(button)
    local pin = storm.io[Button.pins[button]]
--[[    cord.await(storm.io.watch_single, storm.io.FALLING, pin)
end
]]

-- A version of Button.whenever that is more reliable. Whenever a button is pressed, waits
-- for a fixed time before registering any additional events, largely preventing the
-- action from ocurring multiple times.
-- The watch is returned in an array-like table. To cancel the watch, cancel the first
-- element with storm.io.watch_cancel and cancel the second element IF IT IS NOT NIL
-- with storm.os.cancel.
-- If your application requires multiple button presses in quick succession, you should
-- consider lowering Button.GAP
Button.GAP = 250
Button.whenever_gap = function(button, transition, action)
    local pin = storm.io[Button.pins[button]]
    local a = {[0]=nil, [1]=nil}
    a[0] = storm.io.watch_single(storm.io[transition], pin, function ()
        print("pressed")
        action()
        a[1] = storm.os.invokeLater(Button.GAP * storm.os.MILLISECOND, function ()
            local new = Button.whenever_gap(button, transition, action)
            a[0] = new[0]
            a[1] = new[1]
            end)
    end)
    return a
end

----------------------------------------------
shield.LED = LED
shield.Buzz = Buzz
shield.Button = Button
return shield


