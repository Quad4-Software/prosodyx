-- Container health check. Connects to the c2s listener on 127.0.0.1:5222
-- and exits 0 on success, 1 on failure.

local socket = require("socket")

local conn = socket.tcp()
if not conn then
	os.exit(1)
end
conn:settimeout(3)
local ok = conn:connect("127.0.0.1", 5222)
conn:close()
if ok then
	os.exit(0)
end
os.exit(1)
