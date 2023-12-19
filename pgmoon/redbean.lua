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
        unix.setsockopt(self.unix_socket, SOL_SOCKET, SO_RCVTIMEO, self.timeout)
        unix.setsockopt(self.unix_socket, SOL_SOCKET, SO_SNDTIMEO, self.timeout)
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
      }))
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
    receive = function(self, ...)
      local pattern = flatten(...)
      if not (self.buf) then
        self.buf = ""
      end
      local CANREAD = unix.POLLIN | unix.POLLRDNORM | unix.POLLRDBAND
      local size = tonumber(pattern)
      if size then
        if #self.buf < size then
          local events = assert(unix.poll({
            [self.unix_socket] = unix.POLLIN
          }))
          if not (events[self.unix_socket]) then
            return nil, "timeout"
          end
          if events[self.unix_socket] & CANREAD == 0 then
            return nil, "close"
          end
          self.buf = self.buf .. assert(unix.recv(self.unix_socket, size - #self.buf))
        end
        local res = self.buf:sub(1, size)
        self.buf = self.buf:sub(size + 1)
        return res
      end
      while not self.buf:find("\n") do
        self.buf = self.buf .. assert(unix.recv(self.unix_socket, 4096))
      end
      local pos = self.buf:find("\n")
      local res = self.buf:sub(1, pos - 1):gsub("\r", "")
      self.buf = self.buf:sub(pos + 1)
      return res
    end,
    close = function(self)
      return assert(unix.close(self.unix_socket))
    end,
    settimeout = function(self, t)
      if t then
        t = t / 1000
      end
      if self.unix_socket then
        unix.setsockopt(self.unix_socket, SOL_SOCKET, SO_RCVTIMEO, t)
        return unix.setsockopt(self.unix_socket, SOL_SOCKET, SO_SNDTIMEO, t)
      else
        self.timeout = t
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