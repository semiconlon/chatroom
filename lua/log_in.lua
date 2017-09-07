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

local function check_user(conn, cookie, login)
  local name = string.lower(login["login_username"])

  local len, err = conn:hlen('user:'..name)
  if  len == 0 then
    err = 'no such user '..login["login_username"]
    return nil, err
  end

  local password, err = conn:hget('user:'..name, 'password')
  if not password then
    err = 'found no password'
    return nil, err
  else
    if password ~= login["login_password"] then
      err = 'the password is wrong'
      return nil, err
    end
  end

  local ok,err = conn:hset('user:'..name, 'login', ngx.time())
  if not ok then
    err = 'failed to update login time '.. err
    return nil, err
  end

  local user_uuid, err = conn:zscore('username:uuid', name)
  if not user_uuid then
    err = 'failed to get cookie in uuid field of ' .. name
    return nil, err
  end

  local ok, err = cookie:set({
      key = 'uuid', value = user_uuid,
      path = "/",
      max_age = 500
  })
  if not ok then
      err = 'failed to set uuid cookie ' .. err
      return nil, err
  end

  local ok, err = cookie:set({
      key = 'username' , value = name,
      path = "/",
      max_age = 500
  })
  if not ok then
    err = 'failed to set username cookie ' .. err
    return nil, err
  end

  return true
end

ngx.req.read_body()
local post_args, err = ngx.req.get_post_args()
if not post_args then
  ngx.say("failed to get post args: ", err)
  return
end

local red = redis:new()
local ok, err = red:connect("127.0.0.1", 6379)
if not ok then
  ngx.say("failed to connect: ", err)
  return
end

local ck, err = cookie:new()
if not ck then
    ngx.say("failed to creat cookie instance: ", err)
    return
end

local ok, err = check_user(red, ck, post_args)
if not ok then
  ngx.say('failed to log in: ' .. err)
  return
end

local ok, err = red:set_keepalive(10000, 100)
if not ok then
  ngx.say("failed to set keepalive: ", err)
  return
end

ngx.say('login successed!!!')
ngx.say('<a href="/chatroom.html">聊天室</a>')

ngx.exit(ngx.HTTP_OK)
