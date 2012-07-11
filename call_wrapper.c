#include <luajit-2.0/lua.h>

struct wrapper_args {
	lua_State *L;
	int nargs;
	int nresults;
	int errfunc;
};

extern int call_wrapper ( struct wrapper_args* a ) {
	return lua_pcall ( a->L , a->nargs , a->nresults , a->errfunc );
}
