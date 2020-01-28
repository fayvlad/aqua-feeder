local mytimer = tmr.create()

print('timer')

function networkFailure()
   print("Unable to connect")
   wifi.eventmon.unregister(wifi.eventmon.STA_GOT_IP)
   return 0
end

wifi.sta.clearconfig()
wifi.setmode(wifi.STATION)
wifi.sta.setmac(config.mac)
wifi.sta.config(config.network)
wifi.sta.autoconnect(1)
wifi.sta.sethostname("aqua-fai")
print('config')

mytimer:alarm(60000, tmr.ALARM_AUTO, function() networkFailure() end)
wifi.sta.connect()
print('connect')

wifi.eventmon.register(wifi.eventmon.STA_GOT_IP,
    function()
        print("IP*: " .. wifi.sta.getip())
        dofile("ntp_sync.lua")
        showClock()
        dofile("mqtt.lua")
        mytimer:stop()
        wifi.eventmon.unregister(wifi.eventmon.STA_GOT_IP)
    end)
