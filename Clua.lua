local ffi = require "ffi"
local bit = require "bit"

ffi.cdef [[
typedef struct lua_State lua_State;
typedef int (*lua_CFunction) (lua_State *L);
typedef const char * (*lua_Reader) (lua_State *L, void *ud, size_t *sz);
typedef int (*lua_Writer) (lua_State *L, const void* p, size_t sz, void* ud);
typedef void * (*lua_Alloc) (void *ud, void *ptr, size_t osize, size_t nsize);
typedef double lua_Number;
typedef ptrdiff_t lua_Integer;
extern lua_State *(lua_newstate) (lua_Alloc f, void *ud);
extern void (lua_close) (lua_State *L);
extern lua_State *(lua_newthread) (lua_State *L);
extern lua_CFunction (lua_atpanic) (lua_State *L, lua_CFunction panicf);
extern int (lua_gettop) (lua_State *L);
extern void (lua_settop) (lua_State *L, int idx);
extern void (lua_pushvalue) (lua_State *L, int idx);
extern void (lua_remove) (lua_State *L, int idx);
extern void (lua_insert) (lua_State *L, int idx);
extern void (lua_replace) (lua_State *L, int idx);
extern int (lua_checkstack) (lua_State *L, int sz);
extern void (lua_xmove) (lua_State *from, lua_State *to, int n);
extern int (lua_isnumber) (lua_State *L, int idx);
extern int (lua_isstring) (lua_State *L, int idx);
extern int (lua_iscfunction) (lua_State *L, int idx);
extern int (lua_isuserdata) (lua_State *L, int idx);
extern int (lua_type) (lua_State *L, int idx);
extern const char *(lua_typename) (lua_State *L, int tp);
extern int (lua_equal) (lua_State *L, int idx1, int idx2);
extern int (lua_rawequal) (lua_State *L, int idx1, int idx2);
extern int (lua_lessthan) (lua_State *L, int idx1, int idx2);
extern lua_Number (lua_tonumber) (lua_State *L, int idx);
extern lua_Integer (lua_tointeger) (lua_State *L, int idx);
extern int (lua_toboolean) (lua_State *L, int idx);
extern const char *(lua_tolstring) (lua_State *L, int idx, size_t *len);
extern size_t (lua_objlen) (lua_State *L, int idx);
extern lua_CFunction (lua_tocfunction) (lua_State *L, int idx);
extern void *(lua_touserdata) (lua_State *L, int idx);
extern lua_State *(lua_tothread) (lua_State *L, int idx);
extern const void *(lua_topointer) (lua_State *L, int idx);
extern void (lua_pushnil) (lua_State *L);
extern void (lua_pushnumber) (lua_State *L, lua_Number n);
extern void (lua_pushinteger) (lua_State *L, lua_Integer n);
extern void (lua_pushlstring) (lua_State *L, const char *s, size_t l);
extern void (lua_pushstring) (lua_State *L, const char *s);
extern const char *(lua_pushvfstring) (lua_State *L, const char *fmt,
                                                      va_list argp);
extern const char *(lua_pushfstring) (lua_State *L, const char *fmt, ...);
extern void (lua_pushcclosure) (lua_State *L, lua_CFunction fn, int n);
extern void (lua_pushboolean) (lua_State *L, int b);
extern void (lua_pushlightuserdata) (lua_State *L, void *p);
extern int (lua_pushthread) (lua_State *L);
extern void (lua_gettable) (lua_State *L, int idx);
extern void (lua_getfield) (lua_State *L, int idx, const char *k);
extern void (lua_rawget) (lua_State *L, int idx);
extern void (lua_rawgeti) (lua_State *L, int idx, int n);
extern void (lua_createtable) (lua_State *L, int narr, int nrec);
extern void *(lua_newuserdata) (lua_State *L, size_t sz);
extern int (lua_getmetatable) (lua_State *L, int objindex);
extern void (lua_getfenv) (lua_State *L, int idx);
extern void (lua_settable) (lua_State *L, int idx);
extern void (lua_setfield) (lua_State *L, int idx, const char *k);
extern void (lua_rawset) (lua_State *L, int idx);
extern void (lua_rawseti) (lua_State *L, int idx, int n);
extern int (lua_setmetatable) (lua_State *L, int objindex);
extern int (lua_setfenv) (lua_State *L, int idx);
extern void (lua_call) (lua_State *L, int nargs, int nresults);
extern int (lua_pcall) (lua_State *L, int nargs, int nresults, int errfunc);
extern int (lua_cpcall) (lua_State *L, lua_CFunction func, void *ud);
extern int (lua_load) (lua_State *L, lua_Reader reader, void *dt,
                                        const char *chunkname);
extern int (lua_dump) (lua_State *L, lua_Writer writer, void *data);
extern int (lua_yield) (lua_State *L, int nresults);
extern int (lua_resume) (lua_State *L, int narg);
extern int (lua_status) (lua_State *L);
extern int (lua_gc) (lua_State *L, int what, int data);
extern int (lua_error) (lua_State *L);
extern int (lua_next) (lua_State *L, int idx);
extern void (lua_concat) (lua_State *L, int n);
extern lua_Alloc (lua_getallocf) (lua_State *L, void **ud);
extern void lua_setallocf (lua_State *L, lua_Alloc f, void *ud);
extern void lua_setlevel (lua_State *from, lua_State *to);
typedef struct lua_Debug lua_Debug;
typedef void (*lua_Hook) (lua_State *L, lua_Debug *ar);
extern int lua_getstack (lua_State *L, int level, lua_Debug *ar);
extern int lua_getinfo (lua_State *L, const char *what, lua_Debug *ar);
extern const char *lua_getlocal (lua_State *L, const lua_Debug *ar, int n);
extern const char *lua_setlocal (lua_State *L, const lua_Debug *ar, int n);
extern const char *lua_getupvalue (lua_State *L, int funcindex, int n);
extern const char *lua_setupvalue (lua_State *L, int funcindex, int n);
extern int lua_sethook (lua_State *L, lua_Hook func, int mask, int count);
extern lua_Hook lua_gethook (lua_State *L);
extern int lua_gethookmask (lua_State *L);
extern int lua_gethookcount (lua_State *L);
struct lua_Debug {
  int event;
  const char *name;
  const char *namewhat;
  const char *what;
  const char *source;
  int currentline;
  int nups;
  int linedefined;
  int lastlinedefined;
  char short_src[60];
  int i_ci;
};
typedef struct luaL_Reg {
  const char *name;
  lua_CFunction func;
} luaL_Reg;
extern void (luaL_openlib) (lua_State *L, const char *libname,
                                const luaL_Reg *l, int nup);
extern void (luaL_register) (lua_State *L, const char *libname,
                                const luaL_Reg *l);
extern int (luaL_getmetafield) (lua_State *L, int obj, const char *e);
extern int (luaL_callmeta) (lua_State *L, int obj, const char *e);
extern int (luaL_typerror) (lua_State *L, int narg, const char *tname);
extern int (luaL_argerror) (lua_State *L, int numarg, const char *extramsg);
extern const char *(luaL_checklstring) (lua_State *L, int numArg,
                                                          size_t *l);
extern const char *(luaL_optlstring) (lua_State *L, int numArg,
                                          const char *def, size_t *l);
extern lua_Number (luaL_checknumber) (lua_State *L, int numArg);
extern lua_Number (luaL_optnumber) (lua_State *L, int nArg, lua_Number def);
extern lua_Integer (luaL_checkinteger) (lua_State *L, int numArg);
extern lua_Integer (luaL_optinteger) (lua_State *L, int nArg,
                                          lua_Integer def);
extern void (luaL_checkstack) (lua_State *L, int sz, const char *msg);
extern void (luaL_checktype) (lua_State *L, int narg, int t);
extern void (luaL_checkany) (lua_State *L, int narg);
extern int (luaL_newmetatable) (lua_State *L, const char *tname);
extern void *(luaL_checkudata) (lua_State *L, int ud, const char *tname);
extern void (luaL_where) (lua_State *L, int lvl);
extern int (luaL_error) (lua_State *L, const char *fmt, ...);
extern int (luaL_checkoption) (lua_State *L, int narg, const char *def,
                                   const char *const lst[]);
extern int (luaL_ref) (lua_State *L, int t);
extern void (luaL_unref) (lua_State *L, int t, int ref);
extern int (luaL_loadfile) (lua_State *L, const char *filename);
extern int (luaL_loadbuffer) (lua_State *L, const char *buff, size_t sz,
                                  const char *name);
extern int (luaL_loadstring) (lua_State *L, const char *s);
extern lua_State *(luaL_newstate) (void);
extern const char *(luaL_gsub) (lua_State *L, const char *s, const char *p,
                                                  const char *r);
extern const char *(luaL_findtable) (lua_State *L, int idx,
                                         const char *fname, int szhint);
typedef struct luaL_Buffer {
  char *p;
  int lvl;
  lua_State *L;
  char buffer[8192];
} luaL_Buffer;
extern void (luaL_buffinit) (lua_State *L, luaL_Buffer *B);
extern char *(luaL_prepbuffer) (luaL_Buffer *B);
extern void (luaL_addlstring) (luaL_Buffer *B, const char *s, size_t l);
extern void (luaL_addstring) (luaL_Buffer *B, const char *s);
extern void (luaL_addvalue) (luaL_Buffer *B);
extern void (luaL_pushresult) (luaL_Buffer *B);

extern int luaopen_base(lua_State *L);
extern int luaopen_math(lua_State *L);
extern int luaopen_string(lua_State *L);
extern int luaopen_table(lua_State *L);
extern int luaopen_io(lua_State *L);
extern int luaopen_os(lua_State *L);
extern int luaopen_package(lua_State *L);
extern int luaopen_debug(lua_State *L);
extern int luaopen_bit(lua_State *L);
extern int luaopen_jit(lua_State *L);
extern int luaopen_ffi(lua_State *L);
extern void luaL_openlibs(lua_State *L);
]]

module ( ... )

LUA_MULTRET = -1

LUA_REGISTRYINDEX = (-10000)
LUA_ENVIRONINDEX = (-10001)
LUA_GLOBALSINDEX = (-10002)
function lua_upvalueindex(i) return LUA_GLOBALSINDEX-i end

LUA_YIELD     = 1
LUA_ERRRUN    = 2
LUA_ERRSYNTAX = 3
LUA_ERRMEM    = 4
LUA_ERRERR    = 5

LUA_TNONE          = (-1)

LUA_TNIL           = 0
LUA_TBOOLEAN       = 1
LUA_TLIGHTUSERDATA = 2
LUA_TNUMBER        = 3
LUA_TSTRING        = 4
LUA_TTABLE         = 5
LUA_TFUNCTION      = 6
LUA_TUSERDATA      = 7
LUA_TTHREAD        = 8
LUA_TCDATA         = 10

LUA_HOOKCALL    = 0
LUA_HOOKRET     = 1
LUA_HOOKLINE    = 2
LUA_HOOKCOUNT   = 3
LUA_HOOKTAILRET = 4

LUA_MASKCALL  = bit.lshift(1,LUA_HOOKCALL)
LUA_MASKRET   = bit.lshift(1,LUA_HOOKRET)
LUA_MASKLINE  = bit.lshift(1,LUA_HOOKLINE)
LUA_MASKCOUNT = bit.lshift(1,LUA_HOOKCOUNT)

function lua_pop(L,n) return ffi.C.lua_settop(L, -(n)-1) end

function luaL_dostring ( L , str )
  local r = ffi.C.luaL_loadstring ( L , str )
  if r ~= 0 then
    return r
  else
    return ffi.C.lua_pcall ( L , 0 , LUA_MULTRET , 0 )
  end
end

return _M
