require "cord" -- scheduler / fiber library
--TMP006 = require "tmp006"
--LCD = require "lcd"
TEMP = require "temp"
temp = TEMP:new()
print("after temp:new")

function poll_temp()  
        temp:init()
        local temp_now= temp:getTemp()
        print("Temp now:"..temp_now)
end

cord.new(poll_temp)

local buzzer = storm.io.D6
local led = storm.io.D3

storm.io.set_mode(storm.io.OUTPUT, buzzer)
storm.io.set_mode(storm.io.OUTPUT, led)


local server_ip = "ff02::1"
local broadcast_port = 1611
local ack_port = 1612
local service_port = 1622
local server_port = 1623

local service_count = 1
service_table = {}
service_table.id = "b"
service_table.desc = "SERVICE"
service_table.servTemp = {s = "subscribeToTemp", desc = "temp", service_type = {"prof"} }

local services = {}
services[1] = "servTemp"
services[2] = "servSong"
services[3] = "servLED"

local service_messages = {
    servTemp = {s = "subscribeToTemp", desc = "temp", service_type = {"prof"} },
    servLED = {s = "setLed", desc = "led", service_type = {"student"} },
    servSong = {s = "setBuzzer", desc = "buzzer", service_type = {"student"} },
}

function temp_setup() 
	cord.new(function() 
	    
        temp:init()
	 
        end)
end


function set_led(value)
    storm.io.set(value,led)
end

function set_buzzer(value)
    storm.io.set(value, buzzer)
end


broadcast_sock = storm.net.udpsocket(broadcast_port, function(payload, from, port)  end)
service_broadcast = function()
   if (service_count > 1) then
       service_table[services[service_count-1]] = nil
   end
   service_table[services[service_count]] = service_messages[services[service_count]]
   local msg = storm.mp.pack(service_table)
   print(msg)
   storm.net.sendto(broadcast_sock, msg, server_ip, broadcast_port)
end

service_listen = function() 
    service_sock = storm.net.udpsocket(service_port, 
			       function(payload, from, port)
                      print(payload)
                      local msg = storm.mp.unpack(payload)
                      resp = {}
                      resp.name = msg.name
                      resp.id = service_table.id
                      resp.payload = ""
                      
                      if (msg.name == "servLED") then 
                          set_led(tonumber(msg.args[1]))
                          resp.payload = "SUCCESS"
                          service_respond(storm.mp.pack(resp))
                      elseif (msg.name == "servSong") then 
                          set_buzzer(tonumber(msg.args[1]))
                          resp.payload = "SUCCESS"
                          service_respond(storm.mp.pack(resp))
                      elseif (msg.name == "servTemp") then
                              cord.new(function()
                                
	                        resp.payload = temp:getTemp()
                                service_respond(storm.mp.pack(resp))
                              end)
                      end
			       end)
end

response_sock = storm.net.udpsocket(server_port, function(payload, from, port) end)
service_respond = function(msg)
   print("responding: ", msg)
   storm.net.sendto(response_sock, msg, server_ip, server_port)
end

ack_listen = function() 
    ack_sock = storm.net.udpsocket(ack_port, 
			   function(payload, from, port)
                  local msg = storm.mp.unpack(payload)
				  print (string.format("from %s port %d: %s",from,port,payload))
                  server_ip = from
                  if msg.name == services[service_count] then service_count = service_count + 1 end
                  storm.os.cancel(broadcast_handle)
                  if service_count <= #services then
                      broadcast_handle = storm.os.invokePeriodically(500*storm.os.MILLISECOND, service_broadcast)
                  end
                  service_listen()
			   end)
end
temp_setup()
ack_listen()
broadcast_handle = storm.os.invokePeriodically(500*storm.os.MILLISECOND, service_broadcast)

cord.enter_loop() -- start event/sleep loop
