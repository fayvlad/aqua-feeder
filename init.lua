print('start')
local filterPin = 6
gpio.mode(1, gpio.OUTPUT)
gpio.mode(filterPin, gpio.OUTPUT)
gpio.write(1, gpio.LOW)
gpio.write(filterPin, gpio.LOW)

local function initDisplay()

tm1637 = require('tm1637')
tm1637.init(3, 4)
tm1637.set_brightness(1)
tm1637.write_string('00.00')
end

print('initDisplay')
initDisplay()

tmr.create():alarm(2000, tmr.ALARM_SINGLE, function() mainApp() end)

function mainApp()
config = require("config")
print('run wifiApp')
dofile("wifiApp.lua")

gpio.mode(1, gpio.OUTPUT)
gpio.mode(filterPin, gpio.OUTPUT)
pwm.setup(2, 50, 180)

tm1637.set_brightness(2)
--local angles = {108,80,60,40,15}

local goRight = true

function feeder()
    m:publish(config.mqtt.topicPub, 'feeding', 0, 0)
    pwm.start(2)
    if goRight then
        pwm.setduty(2, 40)
        goRight = false
    else
        pwm.setduty(2, 120)
        goRight = true
    end
    tmr.create():alarm(300, tmr.ALARM_SINGLE, function()
         pwm.stop(2)
    end)
end

local function feederTime()
    if config.status.fiding then return nil end
    m:publish(config.mqtt.topicPub, 'feeder time', 0, 0)
    config.status.fiding = true
    config.status.filterInPause = true

    gpio.write(filterPin, gpio.HIGH)
    tmr.create():alarm(10000, tmr.ALARM_SINGLE, function()
        feeder()
    end)
    tmr.create():alarm(180000, tmr.ALARM_SINGLE, function()
        gpio.write(filterPin, gpio.LOW)
        config.status.fiding = false
        config.status.filterInPause = false
        m:publish(config.mqtt.topicPub, 'feeder finish', 0, 0)
    end)
end
local function switchLight()
    m:publish(config.mqtt.topicPub, 'light '.. config.status.light, 0, 0)
    gpio.write(1, config.status.light)
end

function showClock()
    tmr.create():alarm(1000, tmr.ALARM_AUTO, function()
        local sec = rtctime.get()

        if sec == 0 then return nil end

        local tm = rtctime.epoch2cal(sec + 7200)
        local str = string.format("%02d.%02d", tm["hour"], tm["min"])
    
        if tm["sec"]%2==0 then str = string.format("%02d.%02d", tm["hour"], tm["min"])
        else str = string.format("%02d%02d", tm["hour"], tm["min"]) end
    
        tm1637.write_string(str)
    end)
end

function feederMqtt(data)
    print('feederMqtt', data)
    if data == 'fast' then feeder() else feederTime() end
   
end

function lightMqtt(data)
    print('lightMqtt', data)
    if data == 'true' or data == 'on' then config.status.light = gpio.HIGH
    else config.status.light = gpio.LOW end

    switchLight()
end

function getDataForMqtt(data)
    print('getDataForMqtt', data)
    local t = tmr.time()
    config.status.uptime = string.format("%dd %dh %dm %ds",tonumber(t/24/3600),tonumber(t/3600)%24,tonumber(t/60)%60,t%60)
    m:publish(config.mqtt.topicPubStatus, sjson.encode(config.status), 0, 0)
end
end
