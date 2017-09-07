local redis = require "resty.redis"
local lock = require "lock"
-- local function print_table(t)
--   for k, v in pairs(t) do
--     ngx.say(k,':',v)
--   end
-- end
--

local function create_user(conn, user_lock, sign)
  local name = string.lower(sign["sign_username"])
  -- local err

  local ok = conn:hlen('user:'..name)
  if ok ~= 0 then
    err = 'the user ' .. name .. 'had existed '
    return nil, err
  end

  local ok, err = user_lock:lock(name)
  if not ok then
    err = 'failed to lock user ' .. name .. ' ' .. err
    return nil, err
  end

  local uuid, err = conn:incrby("uuid", 1)
  if not uuid then
    err = 'failed to create user uniqued id ' .. err
    user_lock:unlock()
    return nil, err
  end

  local ok, err = conn:hmset('user:'..name,
  'name' , sign["sign_username"],
  'password', sign["sign_password"],
  'uuid', uuid,
  'email', sign["sign_email"],
  'followers', 0,
  'following', 0,
  'message_id', 0,
  'login', ngx.time()
  )
  if not ok then
    err = 'failed to set the information in user:'.. name .. err
    user_lock:unlock()
    return nil, err
  end

  local ok, err = conn:zadd('username:uuid', uuid, name)
  if not ok then
    err = 'failed to set the information in username:uuid ' .. err
    user_lock:unlock()
    return nil, err
  end

  user_lock:unlock()
  return true

end

ngx.req.read_body()
local post_args, err = ngx.req.get_post_args()
if not post_args then
  ngx.say("failed to get post args: ", err)
  return
end

-- ngx.say(post_args["sign_email"])

local red = redis:new()
local ok, err = red:connect("127.0.0.1", 6379)
if not ok then
  ngx.say("failed to connect: ", err)
  return
end

local create_user_lock, err = lock:new("create_user_lock")
if not create_user_lock then
  ngx.say("failed to create lock: ", err)
  return
end

local ok, err = create_user(red, create_user_lock, post_args)
if not ok then
  ngx.say("failed to create user: ", err)
  return
end




local ok, err = red:set_keepalive(10000, 100)
if not ok then
  ngx.say("failed to set keepalive: ", err)
  return
end

ngx.say("sign up successed")
ngx.say('<a href="/log_in.html">马上登陆</a>')
ngx.exit(ngx.HTTP_OK)
-- ngx.say(type(post_args))
-- print_table(post_args)
--
-- ngx.say(post_args["sign_username"])
