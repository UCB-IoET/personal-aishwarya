--[[
   echo client as server
   currently set up so you should start one or another functionality at the
   stormshell

--]]

require "cord" -- scheduler / fiber library
LED = require("led")
brd = LED:new("GP0")

print("echo test")
brd:flash(4)

local service_table= {
id="HolyCow",

  printHello={ s= "setBool", desc="print Hello"},
}




ipaddr = storm.os.getipaddr()
ipaddrs = string.format("%02x%02x:%02x%02x:%02x%02x:%02x%02x::%02x%02x:%02x%02x:%02x%02x:%02x%02x",
			ipaddr[0],
			ipaddr[1],ipaddr[2],ipaddr[3],ipaddr[4],
			ipaddr[5],ipaddr[6],ipaddr[7],ipaddr[8],	
			ipaddr[9],ipaddr[10],ipaddr[11],ipaddr[12],
			ipaddr[13],ipaddr[14],ipaddr[15])

print("ip addr", ipaddrs)
print("node id", storm.os.nodeid())
cport = 49152

-- create echo server as handler
server = function()
   ssock = storm.net.udpsocket( 1525, 
			       function(payload, from, port)
				  brd:flash(1)
print("From ip:", from)
                               local msg= storm.mp.unpack(payload)
                               print("Incoming msg:",payload)
			       
                              -- if (from== "fe80::212:6d02:0:304d") then

                             -- end 
                               end)

lsock= storm.net.udpsocket(1526, function(payload, from, port)
              print("Incoming on 1526:", payload)
              local uni_in=storm.mp.unpack(payload)
              if (uni_in[1] == "printHello") then
                 print("Hello from ",from)
              end
end)

                                 local temp= {"SetG",{1}}
                                 local uni_msg= storm.mp.pack(temp)
                                 storm.net.sendto(lsock,uni_msg, "fe80::212:6d02:0:304d", 1526)

--local svc_manifest = {id="Holy Cow"}              
local msg = storm.mp.pack(service_table)
storm.os.invokePeriodically(2*storm.os.SECOND, function()
storm.net.sendto(ssock, msg, "ff02::1", 1525)
end)

end

server()			-- every node runs the echo server

-- enable a shell
sh = require "stormsh"
sh.start()
cord.enter_loop() -- start event/sleep loop
