shield=require("starter")

shield.Buzz.start();
shield.Buzz.go(3*storm.os.MILLISECOND)
storm.os.invokeLater(500*storm.os.MILLISECOND, function()
                        shield.Buzz.stop()
                        end)

cord.enter_loop()

