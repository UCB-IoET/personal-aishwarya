require("storm")
require("cord")
require("math")
require("table")
shield = require("starter")

print("Tweet tweet I'm a bird with node ID ", storm.os.nodeid())

sport = 55555

songs = {1,2,3,4,5,6,7,8,9,10} -- TODO change this to freq, duration pairs
count = {0,0,0,0,0,0,0,0,0,0}
--cur_song = math.random(3)
--cur_song=songs[math.random(3)]

-- Listening window
min1 = 100
max1 = 1000
min2 = 100
max2 = 2000

csock = storm.net.udpsocket(math.random(55556, 65535), function() end)

function play_song()
    print("I'm playing song ", song_id)
    shield.Buzz.start()
    for k=1, table.getn(count) do
     if song_id ~= k then
         count[k]=0
     
     else count[k]=count[k]+1
        if count[k] >= 10 then
               math.randomseed(storm.os.now(storm.os.SHIFT_0))
               song_id= math.random(10)
               count[k]=0
        end 
     end 
    end --end for loop
 
    cur_song=songs[song_id]
    shield.Buzz.go(cur_song*storm.os.MILLISECOND)
    storm.os.invokeLater(500 * storm.os.MILLISECOND, listen)
end

function maxkey(t)
    max = 0
    index = 0
    for i = 1, table.getn(t) do
        if t[i] >= max then
            max = t[i]
            index = i
        end
    end
    return index
end

function recv_song(payload, srcip, srcport) --receive new song and add it to table

    in_song_id= tonumber(payload)
    print("incoming song", in_song_id)
    print("from", srcip)
    --print (string.format("Message from %s port %d: Song %s",scrip,srcport,payload))
    song_table[in_song_id] = song_table[in_song_id] + 1
    
end


function listen()
    print("started listening")
    shield.Buzz.stop()
    song_table = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
    song_table[song_id] = song_table[song_id] + 1

    ssock = storm.net.udpsocket(sport, recv_song)       
    
    wait1 = math.random(min1, max1)
    wait2 = math.random(min2, max2)

    storm.os.invokeLater(wait1 * storm.os.MILLISECOND, function() 
                         print("announcing song") 
                         storm.net.sendto(csock, tostring(song_id), "ff02::1", sport) 
                     end)

    storm.os.invokeLater(wait2 * storm.os.MILLISECOND, function()
        storm.net.close(ssock)
        print ("The table is")
        for i=1, table.getn(song_table) do
           print (song_table[i])
        end
        song_id = maxkey(song_table)
        print("my song is now ", song_id)
        play_song()
    end)
end

math.randomseed(storm.os.now(storm.os.SHIFT_0))
song_id= math.random(10) 

play_song()
cord.enter_loop()

