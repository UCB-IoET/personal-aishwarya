require "cord"
shield= require "starter"
buttons = {[1] = "right", [2] = "middle", [3] = "left"}

--ports
sport_broadcast = 1611
sport_broadcast_ack = 1612
sport_send = 1622
sport_listen = 1623
sport_send_ping = 1623
sport_listen_ping = 1624


User_interface = function()

cord.new( function()

while (interface == 0) do
     print "Press 1 for Student, 2 for Professor, 3 for Staff:"
     local option = io.read()
     --print("Options"..option)
     local broadcast_reg

--[[     if (option == "1") then
	broadcast_reg.student = "true"
  
     elseif (option == "2") then
        broadcast_reg.prof = "true"
  
     elseif (option == "3") then
        broadcast_reg.staf = "true"
     end]]--

for i = 1, 3 do
    shield.Button.whenever_gap(buttons[i], "FALLING", function ()
        if (i==1) then 
          broadcast_reg.student = "true"
  
        elseif (i == "2") then
          broadcast_reg.prof = "true"
  
        elseif (i == "3") then
          broadcast_reg.staf = "true"
     end
    end)
end


broadcast_reg.id=storm.os.nodeid()
broadcast_reg.desc="NEW_CLIENT"

storm.mp.pack(broadcast_reg)
sock=storm.net.udpsocket(55, function(payload,from,port)
                                           -- in case of response, but not in this application
                                           end)

storm.net.sendto(55, broadcast_reg, "ff02::1", sport_boadcast)
    
--cord.await(storm.os.watch_single(storm.io["FALLING"], 

     local available_choices = {}
     local available_choice_index = 1

     for i = 1, service_count - 1 do
	if (service_table[i].service_type == serv_type) then
		print(i..". "..service_table[i].desc.."\n")
		available_choices[available_choice_index] = i
		available_choice_index = available_choice_index + 1
	end
     end
       
     local service_choice_string = io.read()
     local service_choice = tonumber(service_choice_string)
     
     local service_msg = {}
     if (service_table[service_choice].s == "lcdDisp") then
			print("Input message to be displayed: ")
                	local lcd_message = io.read()
     			service_msg.name = service_table[service_choice].name
			service_msg.args = {lcd_message}   
    elseif  (service_table[service_choice].s == "subscribeToTemp") then
     			service_msg.name = service_table[service_choice].name
			service_msg.args = {}
    elseif (service_table[service_choice].s == "setLed") then
			print("Turn Light on/off (1/0)? ")
                	local light = io.read()
     			service_msg.name = service_table[service_choice].name
			service_msg.args = {tonumber(light)}   
    elseif (service_table[service_choice].s == "setBuzzer") then
			print("Turn Buzzer on/off (1/0)? ")
                        local buzz = io.read()
     			service_msg.name = service_table[service_choice].name
			service_msg.args = {tonumber(buzz)}   
   elseif (service_table[service_choice].s == "setRelay") then
			print("Turn Buzzer on/off (1/0)? ")
                	local relay = io.read()
     			service_msg.name = service_table[service_choice].name
			service_msg.args = {tonumber(relay)}   
    end
    local service_msg_payload = storm.mp.pack(service_msg)
    service_invoke = storm.os.invokePeriodically(7*storm.os.SECOND, function () storm.net.sendto(ssock_service,service_msg_payload, service_table[service_choice].from, sport_send) end) 

    interface = 1
    end
    interface = 0
  end)
end

