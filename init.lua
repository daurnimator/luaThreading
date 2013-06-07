local syscall = require "syscall"
local syscall_helpers = require "syscall.helpers"
local ffi = require "ffi"

local function assert ( cond , ... )
	collectgarbage ( "collect" ) -- force gc, to test for bugs
	if not cond then
		error ( (...) , 2 )
	else
		return cond , ...
	end
end

local process_methods = { }
local process_mt = {
	__index = process_methods ;
	__tostring = function ( t )
		return string.format ( "process{pid=%d}" , t.pid )
	end ;
}
function process_methods:wait ( )
	return assert ( syscall.waitpid ( self.pid , "clone" ) )
end

function process_methods:recv ( io , flags )
	local mc = syscall.types.t.cmsghdr(nil,nil,nil,1024)
	local msg = syscall.types.t.msghdr {
		msg_iov = io.iov ;
		msg_iovlen = #io ;
		msg_control = mc ;
		msg_controllen = #mc ;
	}
	local count = assert ( self.socket:recvmsg ( msg , flags ) )
	local flags = msg.msg_flags
	for mc, cmsg in msg:cmsgs ( ) do
		for fd in cmsg:fds ( ) do
			self:on_fd ( fd )
		end
		local pid , uid , gid = cmsg:credentials ( )
		if pid then
			self:on_credentials ( pid , uid , gid )
		end
	end
	if count > 0 and self.on_data then
		self:on_data ( io , count )
	end
end
function process_methods:send ( ... )
	return assert ( self.socket:send ( ... ) )
end
function process_methods:sendfds ( ... )
	return assert ( util.sendfds ( self.socket , ... ) )
end

local function new_process ( func )
	local sv = assert ( syscall.socketpair ( "unix" , "stream" ) )
	collectgarbage ( "collect" ) -- Collect garbage before cloning so it won't happen twice.
	local pid = assert ( syscall.clone ( "IO" ) )
	if pid == 0 then
		assert ( sv[2]:setsockopt ( "socket" , "passcred" , true ) )
		sv[1]:close ( )
		return syscall.exit ( func ( sv[2] ) )
	else
		assert ( sv[1]:setsockopt ( "socket" , "passcred" , true ) )
		sv[2]:close ( )
		return setmetatable ( {
			pid    = pid ;
			socket = sv[1] ;
		} , process_mt )
	end
end

local voidalign = ffi.alignof(ffi.typeof("void *"))

local mythread = new_process ( function ( sock )
	local buf1 = syscall.types.t.buffer(1,"a") -- need to send one byte
	local io = syscall.types.t.iovecs{{buf1, 1}}
	local fds = {0}
	local fa = syscall.types.t.ints(#fds, fds)
	local fasize = ffi.sizeof(fa)

	local val = {
		syscall.types.t.cmsghdr("socket", "rights", fa, fasize) ;
		syscall.types.t.cmsghdr("socket", "credentials", syscall.types.t.ucred {
			pid = syscall.getpid() ;
			uid = syscall.getuid() ;
			gid = syscall.getgid() ;
		})
	}

	local buf , len , offsets = syscall_helpers.align_types ( voidalign , val )
	for i=1,#val do
		ffi.copy ( buf+offsets[i] , val[i] , #val[i] )
	end

	local msg = syscall.types.t.msghdr {
		msg_iov = io.iov;
		msg_iovlen = #io;
		msg_control = buf;
		msg_controllen = len;
	}
	assert(sock:sendmsg(msg, 0))
	--sock:send ( "Hi\n" )
end )

local buflen = 200
local buf = ffi.new ( "char[?]" , buflen )
--local len = mythread:recv ( buf , buflen )
--print ( ffi.string ( buf , len ) )


function mythread:on_data ( iov , count )
	print("DATA",iov,count)
end
function mythread:on_fd ( fd )
	print("FD",fd)
end
function mythread:on_credentials ( pid , uid , gid )
	print("CRED",pid , uid , gid)
end

local buf1 = syscall.types.t.buffer(10) -- assume user wants to receive single byte to get cmsg
local iov = syscall.types.t.iovecs{{buf1, 1}}

local ret = mythread:recv ( iov )

local ret = mythread:wait()
--print(ret.status)

