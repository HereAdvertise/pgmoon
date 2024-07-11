local flatten
flatten = require("pgmoon.util").flatten
local RedbeanSocket
do
  local _class_0
  local _base_0 = {
    connect = function(self, host, port, opts)
      if not (self.unix_socket) then
        self.unix_socket = assert(unix.socket())
      end
      local err
      self.sock, err = unix.connect(self.unix_socket, assert(ResolveIp(host)), port)
      if not (self.sock) then
        return nil, err:doc()
      end
      if self.timeout then
        unix.setsockopt(self.unix_socket, SOL_SOCKET, SO_RCVTIMEO, self.timeout / 1000)
        unix.setsockopt(self.unix_socket, SOL_SOCKET, SO_SNDTIMEO, self.timeout / 1000)
      end
      return true
    end,
    starttls = function(self, ...)
      return error("Not supported at the moment.")
    end,
    getpeercertificate = function(self)
      return error("Not supported at the moment.")
    end,
    send = function(self, ...)
      local data = flatten(...)
      local CANWRITE = unix.POLLOUT | unix.POLLWRNORM
      local events = assert(unix.poll({
        [self.unix_socket] = unix.POLLOUT
      }, self.timeout))
      if not (events[self.unix_socket]) then
        return nil, "timeout"
      end
      if events[self.unix_socket] & CANWRITE == 0 then
        return nil, "close"
      end
      local sent, err = unix.send(self.unix_socket, data)
      if not sent and err:name() == "EAGAIN" then
        return nil, "timeout"
      end
      return sent, err
    end,
    receive = function(self, pattern)
      local CANREAD = unix.POLLIN | unix.POLLRDNORM | unix.POLLRDBAND
      local size = tonumber(pattern)
      if size then
        local events = assert(unix.poll({
          [self.unix_socket] = unix.POLLIN
        }, self.timeout))
        if not (events[self.unix_socket]) then
          return nil, "timeout"
        end
        if events[self.unix_socket] & CANREAD == 0 then
          return nil, "close"
        end
        return unix.recv(self.unix_socket, size)
      end
      return ""
    end,
    close = function(self)
      return assert(unix.close(self.unix_socket))
    end,
    settimeout = function(self, t)
      self.timeout = t
      if self.unix_socket then
        unix.setsockopt(self.unix_socket, SOL_SOCKET, SO_RCVTIMEO, t / 1000)
        return unix.setsockopt(self.unix_socket, SOL_SOCKET, SO_SNDTIMEO, t / 1000)
      end
    end,
    getreusedtimes = function(self)
      return 0
    end,
    setkeepalive = function(self)
      return error("You attempted to call setkeepalive on a Redbean socket. This method is only available for the ngx cosocket API for releasing a socket back into the connection pool")
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "RedbeanSocket"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  RedbeanSocket = _class_0
end
return {
  RedbeanSocket = RedbeanSocket
}
