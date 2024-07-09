-- https://github.com/pkulchenko/ZeroBranePackage/blob/21b1b58ad4df5a61f0c79020b58d180d5c693d98/redbean.lua#L94

import flatten from require "pgmoon.util"

-- socket proxy class to make Redbean socket behave like ngx.socket.tcp
class RedbeanSocket
  connect: (host, port, opts) =>
    @unix_socket = assert unix.socket! unless @unix_socket

    @sock, err = unix.connect @unix_socket, assert(ResolveIp host), port

    unless @sock
      return nil, err\doc!

    if @timeout
      unix.setsockopt @unix_socket, SOL_SOCKET, SO_RCVTIMEO, @timeout
      unix.setsockopt @unix_socket, SOL_SOCKET, SO_SNDTIMEO, @timeout

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
    events = assert unix.poll @unix_socket: unix.POLLOUT
    return nil, "timeout" unless events[@unix_socket]
    return nil, "close" if events[@unix_socket] & CANWRITE == 0
    sent, err = unix.send @unix_socket, data
    return nil, "timeout" if not sent and err\name! == "EAGAIN"
    sent, err

  receive: (...) =>
    pattern = flatten ...

    @buf = "" unless @buf

    CANREAD = unix.POLLIN | unix.POLLRDNORM | unix.POLLRDBAND
    size = tonumber pattern
    if size
        if #@buf < size
            events = assert unix.poll @unix_socket: unix.POLLIN
            return nil, "timeout" unless events[@unix_socket]
            return nil, "close" if events[@unix_socket] & CANREAD == 0
            rec = unix.recv @unix_socket, size-#@buf
            if rec
                @buf ..= rec
            else
                collectgarbage!
                @buf ..= assert unix.recv @unix_socket, 4096
        res = @buf\sub 1, size
        @buf = @buf\sub size+1
        return res

    while not @buf\find "\n"
        rec = unix.recv @unix_socket, 4096
        if rec
            @buf ..= rec
        else
            collectgarbage!
            @buf ..= assert unix.recv @unix_socket, 4096
        
    pos = @buf\find "\n"
    res = @buf\sub(1, pos-1)\gsub "\r", ""
    @buf = @buf\sub pos+1
    res

  close: =>
    assert unix.close @unix_socket

  settimeout: (t) =>
    if t
      t = t/1000

    if @unix_socket
      unix.setsockopt @unix_socket, SOL_SOCKET, SO_RCVTIMEO, t
      unix.setsockopt @unix_socket, SOL_SOCKET, SO_SNDTIMEO, t
    else
      @timeout = t

  -- openresty pooling interface, always return 0 to suggest that the socket
  -- is connecting for the first time
  getreusedtimes: => 0

  setkeepalive: =>
    error "You attempted to call setkeepalive on a Redbean socket. This method is only available for the ngx cosocket API for releasing a socket back into the connection pool"

{ :RedbeanSocket }
