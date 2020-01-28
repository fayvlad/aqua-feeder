print('ntp_sync ...')
local hourCount = 0
local sntpServerIp

local cfg = {
  sntpServerName = '0.pool.ntp.org',
  sntpServerIp = '200.160.7.193',
  sntpRefresh = 24 -- hours
}

function startNtpSync()
  if (hourCount == 0 and true) then
    net.dns.resolve(cfg.sntpServerName, function(sk, ip)
      if (ip) then
        print('Resolved ' .. cfg.sntpServerName .. ' to ' .. ip)
        sntpServerIp = ip
      else
        print('Resolve ' .. cfg.sntpServerName .. ' fail!')
        print('Fallback to ' .. cfg.sntpServerIp)
        sntpServerIp = cfg.sntpServerIp
      end

      doNtpSync()
    end)
  end

  hourCount = hourCount + 1
  if (hourCount >= cfg.sntpRefresh) then
    hourCount = 0
  end
end

function doNtpSync()
    sntp.sync(
    sntpServerIp,
    function(sec,usec,server)
        print('sntp sync success', sec, usec, server)
        tm = rtctime.epoch2cal(rtctime.get())
        print(string.format("%04d/%02d/%02d %02d:%02d:%02d", tm["year"], tm["mon"], tm["day"], tm["hour"], tm["min"], tm["sec"]))
        config.status.lastSync = string.format("%04d/%02d/%02d %02d:%02d:%02d", tm["year"], tm["mon"], tm["day"], tm["hour"], tm["min"], tm["sec"])
    end,
    function(aa,bb)
        print('failed!',aa,bb)
    end
    )
end

tmr.create():alarm(3600000, tmr.ALARM_AUTO, startNtpSync)
startNtpSync()
