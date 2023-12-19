local default_escape_literal = nil
local encode_json
encode_json = function(tbl, escape_literal)
  escape_literal = escape_literal or default_escape_literal
  if not (escape_literal) then
    local Postgres
    Postgres = require("pgmoon").Postgres
    default_escape_literal = function(v)
      return Postgres.escape_literal(nil, v)
    end
    escape_literal = default_escape_literal
  end
  local enc
  if GetRedbeanVersion then
    enc = EncodeJson(tbl)
    enc = enc:gsub("\\u0027", "''")
  else
    local json = require("cjson")
    enc = json.encode(tbl)
  end
  return escape_literal(enc)
end
local decode_json
decode_json = function(str)
  if GetRedbeanVersion then
    return DecodeJson(str)
  else
    local json = require("cjson")
    return json.decode(str)
  end
end
return {
  encode_json = encode_json,
  decode_json = decode_json
}