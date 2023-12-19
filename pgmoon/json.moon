default_escape_literal = nil

encode_json = (tbl, escape_literal) ->
  escape_literal or= default_escape_literal

  unless escape_literal
    import Postgres from require "pgmoon"
    default_escape_literal = (v) ->
      Postgres.escape_literal nil, v

    escape_literal = default_escape_literal

  local enc

  if GetRedbeanVersion
    enc = EncodeJson tbl
    enc = enc\gsub "(.?)\\u0027", (escape) -> "'" if escape != "\\"
  else
    json = require "cjson"
    enc = json.encode tbl

  escape_literal enc

decode_json = (str) ->
  if GetRedbeanVersion
    return DecodeJson str
  else
    json = require "cjson"
    return json.decode str

{ :encode_json, :decode_json }
