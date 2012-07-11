local ffi = require "ffi"
require "Cpthread"
local pthread = ffi.load "pthread"
local lua = require "Clua"
local marshall = require "marshall"
local get , set = marshall.get , marshall.set

ffi.cdef [[
struct wrapper_args {
	lua_State *L;
	int nargs;
	int nresults;
	int errfunc;
};
extern int call_wrapper ( struct wrapper_args* );
typedef struct {
	pthread_t pthread;
	lua_State* L;
} luaThread;
]]


local entry = ffi.cast ( "void *(*)(void*)" , ffi.load("./call_wrapper.so").call_wrapper )

local function thread_call ( L , ... )
	local pthread_p = ffi.new ( "pthread_t[1]" )
	local n = select ( "#" , ... )
	local args = { ... }
	for i=1,n do
		set ( args [ i ] , L )
	end
	local w_args = ffi.new ( "struct wrapper_args[1]" , { {
			L = L ;
			nargs = n ;
			nresults = lua.LUA_MULTRET ;
			errfunc = 0 ;
		} } )
	local err = pthread.pthread_create ( pthread_p , ffi.NULL , entry , w_args )
	if err ~= 0 then
		error ( ffi.string ( ffi.C.strerror ( ffi.errno() ) ) )
	end
	local thread = ffi.new ( "luaThread" )
	thread.pthread = pthread_p[0]
	thread.L = L
	return thread
end


local function join ( thread )
	local p_ret = ffi.new ( "void*[1]" )
	local err = pthread.pthread_join ( thread.pthread , p_ret )
	if err ~= 0 then
		error ( ffi.string ( ffi.C.strerror ( ffi.errno() ) ) )
	end
	local res = tonumber(ffi.cast("int",p_ret[0]))
	if res ~= 0 then
		local err = get ( thread.L , -1 )
		error ( err )
	end
	local n_results = ffi.C.lua_gettop ( thread.L )
	local tbl = {}
	for i=1,n_results do
		tbl [ i ] = get ( thread.L , i )
	end
	return unpack ( tbl , 1 , n_results )
end

ffi.metatype ( "luaThread" , {
		__index = {
			join = join ;
		} ;
		__gc = function ( t )
			pthread.pthread_detach ( t.pthread )
		end ;
	} )

return {
	call = thread_call ;
}
