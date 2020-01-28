collectgarbageCounter = 0
local onOffline = function(client) mqttConnect(true) end
local mqttTmr = tmr.create()

local onConnect = function(client)
    mqttTmr:stop()
    config.mqtt.status = true
    print("MQTT connected success")
    local topics = {}
    topics[config.mqtt.topicSubFeeder] = 0
    topics[config.mqtt.topicSubLight] = 0
    topics[config.mqtt.topicSubGet] = 0

    client:subscribe(topics, function(client) print("subscribe success") end)
    client:publish(config.mqtt.topicPub, "online - feeder".. node.heap(), 0, 0, function(client) print("sent online") end)
end

local onMessage = function(client, topic, data)
    print(topic .. ":" .. data )
    if (topic == config.mqtt.topicSubFeeder) then feederMqtt(data)
    elseif (topic == config.mqtt.topicSubLight) then lightMqtt(data)
    elseif (topic == config.mqtt.topicSubGet) then getDataForMqtt(data) end

    collectgarbageCounter = collectgarbageCounter + 1
    if collectgarbageCounter > 10 then
        collectgarbageCounter = 0
        collectgarbage("collect")
        print("Collect garbage")
    end
end

function mqttConnect(firstReconnect)
    if firstReconnect then
        config.mqtt.status = false
        mqttClean()
    end

    mqttTmr:alarm(config.mqtt.tmr_retry_ms, tmr.ALARM_AUTO, function()
        print("MQTT Waiting for a network")
        mqttClean()
        if wifi.sta.status() == wifi.STA_GOTIP then
            print("MQTT Got a network")
            m = mqtt.Client(wifi.sta.getip(), config.mqtt.keep_alive_sec)
            m:lwt(config.mqtt.topicPub, "feeder offline", 0, 0)
            m:on("offline", onOffline)
            m:on("message", onMessage)
            do_mqtt_connect()
        end
    end)
end

function do_mqtt_connect()
  print("--do_mqtt_connect--"..node.heap())
  m:connect(config.mqtt.broker_ip, config.mqtt.port, 0, onConnect, function(client, reason)
      print(client, reason)
  end)
end

function mqttClean()
    if m ~= nil then
        m:close()
        m = nil
        collectgarbage("collect")
        print("MQTT cleaned")
    end
end

mqttConnect()
