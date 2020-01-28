local config = {}

config.mac = "*****"
config.network = {
    ssid = "Andersen",
    pwd = "*****"
}

config.id = node.chipid()

config.mqtt = {
    client_id         = node.chipid(),
    status            = false,
    broker_ip         = "*****",
    port              = 1883,
    keep_alive_sec    = 120,
    tmr_retry_ms      = 3000,
    status            = false,
    topicPubStatus    = "/aqua/status",
    topicPub          = "/aqua/"..node.chipid(),
    topicSubGet       = "/aqua/get",
    topicSubFeeder    = "/aqua/feeder",
    topicSubLight     = "/aqua/light",
}

config.status = {
    fiding          = false,
    light           = gpio.LOW,
    filterInPause   = false,
    lastSync        = '',
}

return config
