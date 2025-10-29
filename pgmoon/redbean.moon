-- https://github.com/pkulchenko/ZeroBranePackage/blob/21b1b58ad4df5a61f0c79020b58d180d5c693d98/redbean.lua#L94

import flatten from require "pgmoon.util"

-- socket proxy class to make Redbean socket behave like ngx.socket.tcp
class RedbeanSocket
  connect: (host, port, opts) =>
    @unix_socket = assert unix.socket! unless @unix_socket

    @sock, err = unix.connect @unix_socket, assert(ResolveIp host), port

    unless @sock
      unix.close @unix_socket
      @unix_socket = nil
      return nil, err\doc!

    if @timeout
      unix.setsockopt @unix_socket, SOL_SOCKET, SO_RCVTIMEO, @timeout / 1000
      unix.setsockopt @unix_socket, SOL_SOCKET, SO_SNDTIMEO, @timeout / 1000

    true

  -- args: [context][, timeout]
  starttls: (...) =>
    error "Not supported at the moment."

  -- returns openssl.x509 object
  getpeercertificate: =>
    error "Not supported at the moment."

  send: (...) =>
    data = flatten ...

    CANWRITE = unix.POLLOUT | unix.POLLWRNORM
    events = assert unix.poll @unix_socket: unix.POLLOUT, @timeout
    return nil, "timeout" unless events[@unix_socket]
    return nil, "close" if events[@unix_socket] & CANWRITE == 0
    size = 0
    while size < #data
      sent, err = unix.send @unix_socket, string.sub data, size + 1
      return nil, "timeout" if not sent and err\name! == "EAGAIN"
      return nil, err\doc! if not sent
      size += sent
      break if sent == 0
    size

  receive: (pattern) =>
    CANREAD = unix.POLLIN | unix.POLLRDNORM | unix.POLLRDBAND
    size = tonumber(pattern)
    buf = ""
    if size
      events = assert unix.poll @unix_socket: unix.POLLIN, @timeout
      return nil, "timeout" unless events[@unix_socket]
      return nil, "close" if events[@unix_socket] & CANREAD == 0
      while #buf < size
        rec = assert unix.recv @unix_socket, size - #buf
        if #rec == 0
          break
        else
          buf ..= rec
    buf

  close: =>
    res = unix.close @unix_socket
    @unix_socket = nil
    res

  settimeout: (t) =>
    @timeout = t
    if @unix_socket
      unix.setsockopt @unix_socket, SOL_SOCKET, SO_RCVTIMEO, t / 1000
      unix.setsockopt @unix_socket, SOL_SOCKET, SO_SNDTIMEO, t / 1000

  -- openresty pooling interface, always return 0 to suggest that the socket
  -- is connecting for the first time
  getreusedtimes: => 0

  setkeepalive: =>
    error "You attempted to call setkeepalive on a Redbean socket. This method is only available for the ngx cosocket API for releasing a socket back into the connection pool"

{ :RedbeanSocket }



