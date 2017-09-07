local redis = require "resty.redis"
local cookie = require "resty.cookie"

--
-- local ok, err = red:connect("127.0.0.1", 6379)
-- if not ok then
--   ngx.say("fail to connect: ", err)
--   return
-- end
--
-- local ok ,err = red:set("test","key")
-- if not ok then
--   ngx.say("fail to set: ", err)
--   return
-- end
--
-- ngx.say("set result: ", ok)
--
-- local ok ,err = red:get("test")
--
-- if not ok then
--   ngx.say("fail to get: ", err)
--   return
-- end
--
-- ngx.say("get result: ", ok)

local function get_user_name(conn, uri_args)
  -- local name = string.lower(login["login_username"])
  --
  -- local len, err = conn:hlen('user:'..name)
  -- if  len == 0 then
  --   err = 'no such user '..login["login_username"]
  --   return nil, err
  -- end
  --
  -- local password, err = conn:hget('user:'..name, 'password')
  -- if not password then
  --   err = 'found no password'
  --   return nil, err
  -- else
  --   if password ~= login["login_password"] then
  --     err = 'the password is wrong'
  --     return nil, err
  --   end
  -- end
  --
  -- local ok,err = conn:hset('user:'..name, 'login', ngx.time())
  -- if not ok then
  --   err = 'failed to update login time '.. err
  --   return nil, err
  -- end
  local uuid = uri_args["uuid"]
  if not uuid then
    err = 'found no uuid in uri_args '
    return nil, err
  end

  local user_name, err = conn:zrangebyscore('username:uuid', uuid ,uuid)
  if not user_name then
    err = 'failed to get user_name by uuid field ' .. err
  return nil, err
  end

  return user_name
end

ngx.req.read_body()
local uri_args, err = ngx.req.get_uri_args()
if not uri_args then
  ngx.say("failed to get uri args: ", err)
  return
end

local red = redis:new()
local ok, err = red:connect("127.0.0.1", 6379)
if not ok then
  ngx.say("failed to connect: ", err)
  return
end


local name, err = get_user_name(red, uri_args)
if not ok then
  ngx.say('failed to log in: ' .. err)
  return
end

ngx.say(name)

local ok, err = red:set_keepalive(10000, 100)
if not ok then
  ngx.say("failed to set keepalive: ", err)
  return
end

ngx.exit(ngx.HTTP_OK)
