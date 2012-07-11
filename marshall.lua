local ffi = require "ffi"
local lua = require "Clua"

local seen = { }

local dump_cache = { }
local function dumper ( L , p , sz , ud )
	ud = tonumber(ffi.cast("int",ud))
	local t = dump_cache [ ud ]
	t [ #t + 1 ] = ffi.string ( p , sz )
	return 0
end
local dump_writer = ffi.cast ( "lua_Writer" , dumper )

local function get ( L , i )
	local t = ffi.C.lua_type ( L , i );
	if t == lua.LUA_TNIL then
	elseif t == lua.LUA_TNUMBER then
		return ffi.C.lua_tonumber ( L , i )
	elseif t == lua.LUA_TBOOLEAN then
		return ffi.C.lua_toboolean ( L , i ) ~= 0
	elseif t == lua.LUA_TSTRING then
		local size = ffi.new ( "size_t[1]" )
		local str = ffi.C.lua_tolstring ( L , i , size )
		return ffi.string ( str , size[0] )
	elseif t == lua.LUA_TLIGHTUSERDATA then
		return ffi.C.lua_touserdata ( L , i )
	else -- userdata, a table, a thread, or a function
		local r
		local ptr = tostring(ffi.C.lua_topointer ( L , i ))
		if seen [ ptr ] then
			return seen [ ptr ]
		end
		if t == lua.LUA_TFUNCTION then
			local C_func = ffi.C.lua_tocfunction ( L , i )
			if C_func ~= nil then
				error ( "Unable to transfer C functions" )
			else
				ffi.C.lua_pushvalue ( L , i )
				local ud = #dump_cache + 1
				local tbl = { }
				dump_cache [ ud ] = tbl
				local err = ffi.C.lua_dump ( L , dump_writer , ffi.cast("void*",ffi.cast("int",ud)) )
				lua.lua_pop ( L , 1 )
				local i=0
				r = load ( function() i=i+1 return tbl[i] end )
			end
		elseif t == lua.LUA_TTHREAD then
			error ( "Unable to transfer threads" )
		elseif t == lua.LUA_TCDATA then
			error ( "Unable to transfer cdata" )
		else
			if t == lua.LUA_TTABLE then
				r = { }
				ffi.C.lua_pushnil ( L )
				while ffi.C.lua_next ( L , i ) ~= 0 do
					local k = get ( L , -2 )
					local v = get ( L , -1 )
					r [ k ] = v
					lua.lua_pop ( L , 1 )
				end
			elseif t == lua.LUA_TUSERDATA then
				error ( "Unable to transfer userdata" )
			else
				error ( "Unknown type: " .. t )
			end
			if ffi.C.lua_getmetatable ( L , i ) ~= 0 then
				setmetatable ( r , get ( L , -1 ) )
				lua.lua_pop ( L , 1 )
			end
		end
		seen [ ptr ] = r
		return r
	end
end

local function set ( v , L )
	local t = type ( v )
	if t == "nil" then
		return ffi.C.lua_pushnil ( L )
	elseif t == "number" then
		return ffi.C.lua_pushnumber ( L , v )
	elseif t == "boolean" then
		return ffi.C.lua_pushboolean ( L , v and 1 or 0 )
	elseif t == "string" then
		return ffi.C.lua_pushlstring ( L , v , #v )
	elseif t == "table" then
		ffi.C.lua_newtable ( L )
		for k , vv in pairs ( v ) do
			set ( k , L )
			set ( vv , L )
			ffi.C.lua_rawset ( L , -3 )
		end
		local mt = debug.getmetatable ( v )
		if mt then
			set ( mt , L )
			ffi.C.lua_setmetatable ( L , -2 )
		end
		return
	elseif t == "userdata" then
		error ( "Unable to transfer userdata" )
	elseif t == "function" then
		local info = debug.getinfo ( v , "S" )
		if info.what == "Lua" then
			local s = string.dump ( v )
			return ffi.C.luaL_loadbuffer ( L , s , #s , info.source )
		else
			error ( "Unable to transfer function" )
		end
	elseif t == "thread" then
		error ( "Unable to transfer threads" )
	else
		error ( "Unknown type: " .. t )
	end
end

return {
	get = get ;
	set = set ;
}
