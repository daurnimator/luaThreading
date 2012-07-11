local ffi = require "ffi"
local lua = require "Clua"
local thread_call = require "init".call

local L = ffi.C.luaL_newstate ( )
ffi.C.luaL_openlibs ( L )
if ffi.C.luaL_loadstring ( L , [[
	local _ , f = ...
	f()
	os.execute ( "sleep " .. (...) )
]] ) ~= 0 then
	error ( get ( L , -1 ) )
end
local thread = thread_call ( L , 0.2, function() print("hi there" ) end)
local res = { thread:join ( ) }




local function pp ( t , indent )
	indent = indent or ""
	if type ( t ) == "table" then
		for k,v in pairs ( t ) do
			print(indent.."["..k.."]={")
			pp ( v , indent.."\t" )
			print(indent.."}")
		end
	else
		print(indent..tostring(t))
	end
end
pp(res)
