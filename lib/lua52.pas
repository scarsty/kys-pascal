(******************************************************************************
 *                                                                            *
 *  File:        lua52.pas                                                    *
 *                                                                            *
 *  Authors:     TeCGraf           (C headers + actual Lua libraries)         *
 *               Lavergne Thomas   (original translation to Pascal)           *
 *               Bram Kuijvenhoven (update to Lua 5.1.1 for FreePascal)       *
 *               Egor Skriptunoff  (update to Lua 5.2.1 for FreePascal)       *
 *                                                                            *
 *  Description: Basic Lua library                                            *
 *               Lua auxiliary library                                        *
 *               Standard Lua libraries                                       *
 *  This is 3-in-1 replacement for FPC modules lua.pas,lauxlib.pas,lualib.pas *
 *                                                                            *
 ******************************************************************************)

(*
** $Id: lua.h,v 1.283 2012/04/20 13:18:26 roberto Exp $
** $Id: lauxlib.h,v 1.120 2011/11/29 15:55:08 roberto Exp $
** $Id: lualib.h,v 1.43 2011/12/08 12:11:37 roberto Exp $
** Lua - A Scripting Language
** Lua.org, PUC-Rio, Brazil (http://www.lua.org)
** See Copyright Notice at the end of this file
*)
(*
** Translated to pascal by Lavergne Thomas
** Notes :
**    - Pointers type was prefixed with 'P'
**    - lua_upvalueindex constant was transformed to function
**    - Some compatibility function was isolated because with it you must have
**      lualib.
**    - LUA_VERSION was suffixed by '_' for avoiding name collision.
** Bug reports :
**    - thomas.lavergne@laposte.net
**   In french or in english
*)
(*
** Updated to Lua 5.1.1 by Bram Kuijvenhoven (bram at kuijvenhoven dot net),
**   Hexis BV (http://www.hexis.nl), the Netherlands
** Notes:
**    - Only tested with FPC (FreePascal Compiler)
**    - Using LuaBinaries styled DLL/SO names, which include version names
**    - LUA_YIELD was suffixed by '_' for avoiding name collision
*)
(*
** Updated to Lua 5.2.1 by Egor Skriptunoff
** Notes:
**    - Only tested with FPC (FreePascal Compiler)
**    - Functions dealing with luaL_Reg were overloaded to accept pointer
**      or open array parameter.  In any case, do not forget to terminate
**      your array with "sentinel".
**    - All floating-point exceptions were forcibly disabled in Windows
**      to overcome well-known bug
** Bug reports:
**    - egor.skriptunoff at gmail.com
**   In russian or in english
*)


//--------------------------
// What was not translated:
//--------------------------
// macro
//    #define luaL_opt(L,f,n,d)  (lua_isnoneornil(L,(n)) ? (d) : f(L,(n)))

// Generic Buffer manipulation functions and macros were not translated.
// They are not required in Pascal programs due to powerful String type.
//    luaL_addchar, luaL_addsize, luaL_buffinit, luaL_prepbuffsize,
//    luaL_addlstring, luaL_addstring, luaL_addvalue, luaL_pushresult,
//    luaL_pushresultsize, luaL_buffinitsize, luaL_prepbuffer

// Functions defined with LUA_COMPAT_MODULE are deprecated.
// They were translated but commented intentionally.
// Uncomment them if you really need.
//    luaL_pushmodule, luaL_openlib, luaL_register


{$IFDEF FPC}{$MODE OBJFPC}{$H+}{$ENDIF}

unit lua52;

interface

const
{$IFDEF MSWINDOWS}
  LUA_LIB_NAME = 'lua52.dll';
{$ELSE}
{$IFDEF DARWIN}
  LUA_LIB_NAME = 'liblua.a';
{$ENDIF}
{$IFDEF ANDROID}
  LUA_LIB_NAME = 'liblua.so';
{$ENDIF}
{$ENDIF}

{$IFDEF fpc}

{$ELSE}

type
  PtrInt = longint;
  PtrUInt = longword;
  PLongBool = ^longbool;
{$ENDIF}

const
  LUA_VERSION_MAJOR = '5';
  LUA_VERSION_MINOR = '2';
  LUA_VERSION_NUM = 502;
  LUA_VERSION_RELEASE = '1';
  LUA_VERSION_ = 'Lua 5.2'; // LUA_VERSION was suffixed by '_' for avoiding name collision
  LUA_RELEASE = 'Lua 5.2.1';
  LUA_COPYRIGHT = 'Lua 5.2.1  Copyright (C) 1994-2012 Lua.org, PUC-Rio';
  LUA_AUTHORS = 'R. Ierusalimschy, L. H. de Figueiredo, W. Celes';
  LUA_SIGNATURE = #27'Lua'; // mark for precompiled code '<esc>Lua'
  LUA_MULTRET = -1; // option for multiple returns in 'lua_pcall' and 'lua_call'

  // pseudo-indices
  LUA_REGISTRYINDEX = -1001000;

function lua_upvalueindex(I: integer): integer;

// thread status
const
  LUA_OK = 0;
  LUA_YIELD_ = 1; // LUA_YIELD was suffixed by '_' for avoiding name collision
  LUA_ERRRUN = 2;
  LUA_ERRSYNTAX = 3;
  LUA_ERRMEM = 4;
  LUA_ERRGCMM = 5;
  LUA_ERRERR = 6;
  LUA_ERRFILE = LUA_ERRERR + 1; // extra error code for `luaL_load'

type
  // Type of Numbers in Lua
  lua_Integer = PtrInt;
  lua_Unsigned = PtrUInt;
  lua_Number = double;

  Plua_Number = ^lua_Number;

  size_t = cardinal;
  Psize_t = ^size_t;

  Plua_State = Pointer;

  lua_CFunction = function(L: Plua_State): integer; cdecl;

  // functions that read/write blocks when loading/dumping Lua chunks
  lua_Reader = function(L: Plua_State; ud: Pointer; sz: Psize_t): PChar; cdecl;
  lua_Writer = function(L: Plua_State; const p: Pointer; sz: size_t; ud: Pointer): integer; cdecl;

  // prototype for memory-allocation functions
  lua_Alloc = function(ud, ptr: Pointer; osize, nsize: size_t): Pointer; cdecl;

const
  // basic types
  LUA_TNONE = -1;
  LUA_TNIL = 0;
  LUA_TBOOLEAN = 1;
  LUA_TLIGHTUSERDATA = 2;
  LUA_TNUMBER = 3;
  LUA_TSTRING = 4;
  LUA_TTABLE = 5;
  LUA_TFUNCTION = 6;
  LUA_TUSERDATA = 7;
  LUA_TTHREAD = 8;
  LUA_NUMTAGS = 9;

  // minimum Lua stack available to a C function
  LUA_MINSTACK = 20;

  // predefined values in the registry */
  LUA_RIDX_MAINTHREAD = 1;
  LUA_RIDX_GLOBALS = 2;
  LUA_RIDX_LAST = LUA_RIDX_GLOBALS;

// state manipulation
function lua_newstate(f: lua_Alloc; ud: Pointer): Plua_state; cdecl;
procedure lua_close(L: Plua_State); cdecl;
function lua_newthread(L: Plua_State): Plua_State; cdecl;
function lua_atpanic(L: Plua_State; panicf: lua_CFunction): lua_CFunction; cdecl;
function lua_version(L: Plua_State): Plua_Number; cdecl;

// basic stack manipulation
function lua_absindex(L: Plua_State; idx: integer): integer; cdecl;
function lua_gettop(L: Plua_State): integer; cdecl;
procedure lua_settop(L: Plua_State; idx: integer); cdecl;
procedure lua_pushvalue(L: Plua_State; Idx: integer); cdecl;
procedure lua_remove(L: Plua_State; idx: integer); cdecl;
procedure lua_insert(L: Plua_State; idx: integer); cdecl;
procedure lua_replace(L: Plua_State; idx: integer); cdecl;
procedure lua_copy(L: Plua_State; fromidx, toidx: integer); cdecl;
function lua_checkstack(L: Plua_State; sz: integer): longbool; cdecl;
procedure lua_xmove(from, to_: Plua_State; n: integer); cdecl;

// access functions (stack -> C)
function lua_isnumber(L: Plua_State; idx: integer): longbool; cdecl;
function lua_isstring(L: Plua_State; idx: integer): longbool; cdecl;
function lua_iscfunction(L: Plua_State; idx: integer): longbool; cdecl;
function lua_isuserdata(L: Plua_State; idx: integer): longbool; cdecl;
function lua_type(L: Plua_State; idx: integer): integer; cdecl;
function lua_typename(L: Plua_State; tp: integer): PChar; cdecl;
function lua_tonumberx(L: Plua_State; idx: integer; isnum: PLongBool): lua_Number; cdecl;
function lua_tointegerx(L: Plua_State; idx: integer; isnum: PLongBool): lua_Integer; cdecl;
function lua_tounsignedx(L: Plua_State; idx: integer; isnum: PLongBool): lua_Unsigned; cdecl;
function lua_toboolean(L: Plua_State; idx: integer): longbool; cdecl;
function lua_tolstring(L: Plua_State; idx: integer; len: Psize_t): PChar; cdecl;
function lua_rawlen(L: Plua_State; idx: integer): size_t; cdecl;
function lua_tocfunction(L: Plua_State; idx: integer): lua_CFunction; cdecl;
function lua_touserdata(L: Plua_State; idx: integer): Pointer; cdecl;
function lua_tothread(L: Plua_State; idx: integer): Plua_State; cdecl;
function lua_topointer(L: Plua_State; idx: integer): Pointer; cdecl;

//  Arithmetic functions
const
  LUA_OPADD = 0; (* ORDER TM *)
  LUA_OPSUB = 1;
  LUA_OPMUL = 2;
  LUA_OPDIV = 3;
  LUA_OPMOD = 4;
  LUA_OPPOW = 5;
  LUA_OPUNM = 6;

procedure lua_arith(L: Plua_State; op: integer); cdecl;

//  Comparison functions
const
  LUA_OPEQ = 0;
  LUA_OPLT = 1;
  LUA_OPLE = 2;

function lua_rawequal(L: Plua_State; idx1, idx2: integer): longbool; cdecl;
function lua_compare(L: Plua_State; idx1, idx2, op: integer): longbool; cdecl;

// push functions (C -> stack)
procedure lua_pushnil(L: Plua_State); cdecl;
procedure lua_pushnumber(L: Plua_State; n: lua_Number); cdecl;
procedure lua_pushinteger(L: Plua_State; n: lua_Integer); cdecl;
procedure lua_pushunsigned(L: Plua_State; n: lua_Unsigned); cdecl;
procedure lua_pushlstring(L: Plua_State; const s: PChar; l_: size_t); cdecl;
procedure lua_pushstring(L: Plua_State; const s: PChar); cdecl; overload;
procedure lua_pushstring(L: Plua_State; const s: string); overload; // added for Pascal
function lua_pushvfstring(L: Plua_State; const fmt: PChar; argp: Pointer): PChar; cdecl;
function lua_pushfstring(L: Plua_State; const fmt: PChar): PChar; cdecl; varargs;
procedure lua_pushcclosure(L: Plua_State; fn: lua_CFunction; n: integer); cdecl;
procedure lua_pushboolean(L: Plua_State; b: longbool); cdecl;
procedure lua_pushlightuserdata(L: Plua_State; p: Pointer); cdecl;
procedure lua_pushthread(L: Plua_State); cdecl;

// get functions (Lua -> stack)
procedure lua_getglobal(L: Plua_State; const var_: PChar); cdecl;
procedure lua_gettable(L: Plua_State; idx: integer); cdecl;
procedure lua_getfield(L: Plua_state; idx: integer; k: PChar); cdecl;
procedure lua_rawget(L: Plua_State; idx: integer); cdecl;
procedure lua_rawgeti(L: Plua_State; idx, n: integer); cdecl;
procedure lua_rawgetp(L: Plua_State; idx: integer; p: Pointer); cdecl;
procedure lua_createtable(L: Plua_State; narr, nrec: integer); cdecl;
function lua_newuserdata(L: Plua_State; sz: size_t): Pointer; cdecl;
function lua_getmetatable(L: Plua_State; objindex: integer): integer; cdecl;
procedure lua_getuservalue(L: Plua_State; idx: integer); cdecl;

// set functions (stack -> Lua)
procedure lua_setglobal(L: Plua_State; const var_: PChar); cdecl;
procedure lua_settable(L: Plua_State; idx: integer); cdecl;
procedure lua_setfield(L: Plua_State; idx: integer; k: PChar); cdecl;
procedure lua_rawset(L: Plua_State; idx: integer); cdecl;
procedure lua_rawseti(L: Plua_State; idx, n: integer); cdecl;
procedure lua_rawsetp(L: Plua_State; idx: integer; p: Pointer); cdecl;
function lua_setmetatable(L: Plua_State; objindex: integer): integer; cdecl;
procedure lua_setuservalue(L: Plua_State; idx: integer); cdecl;

// 'load' and 'call' functions (load and run Lua code)
procedure lua_callk(L: Plua_State; nargs, nresults, ctx: integer; k: lua_CFunction); cdecl;
procedure lua_call(L: Plua_State; nargs, nresults: integer);
function lua_getctx(L: Plua_State; ctx: PInteger): integer; cdecl;
function lua_pcallk(L: Plua_State; nargs, nresults, errfunc, ctx: integer; k: lua_CFunction): integer; cdecl;
function lua_pcall(L: Plua_State; nargs, nresults, errf: integer): integer;
function lua_load(L: Plua_State; reader: lua_Reader; dt: Pointer; const chunkname, mode: PChar): integer; cdecl;
function lua_dump(L: Plua_State; writer: lua_Writer; Data: Pointer): integer; cdecl;

// coroutine functions
function lua_yieldk(L: Plua_State; nresults, ctx: integer; k: lua_CFunction): integer; cdecl;
function lua_yield(L: Plua_State; nresults: integer): integer;
function lua_resume(L, from: Plua_State; narg: integer): integer; cdecl;
function lua_status(L: Plua_State): integer; cdecl;

//  garbage-collection function and options
const
  LUA_GCSTOP = 0;
  LUA_GCRESTART = 1;
  LUA_GCCOLLECT = 2;
  LUA_GCCOUNT = 3;
  LUA_GCCOUNTB = 4;
  LUA_GCSTEP = 5;
  LUA_GCSETPAUSE = 6;
  LUA_GCSETSTEPMUL = 7;
  LUA_GCSETMAJORINC = 8;
  LUA_GCISRUNNING = 9;
  LUA_GCGEN = 10;
  LUA_GCINC = 11;

function lua_gc(L: Plua_State; what, Data: integer): integer; cdecl;

// miscellaneous functions
function lua_error(L: Plua_State): integer; cdecl;
function lua_next(L: Plua_State; idx: integer): integer; cdecl;
procedure lua_concat(L: Plua_State; n: integer); cdecl;
procedure lua_len(L: Plua_State; idx: integer); cdecl;
function lua_getallocf(L: Plua_State; ud: PPointer): lua_Alloc; cdecl;
procedure lua_setallocf(L: Plua_State; f: lua_Alloc; ud: Pointer); cdecl;

// some useful macros
function lua_tonumber(L: Plua_State; idx: integer): lua_Number;
function lua_tointeger(L: Plua_State; idx: integer): lua_Integer;
function lua_tounsigned(L: Plua_State; idx: integer): lua_Unsigned;
procedure lua_pop(L: Plua_State; n: integer);
procedure lua_newtable(L: Plua_state);
procedure lua_register(L: Plua_State; const n: PChar; f: lua_CFunction);
procedure lua_pushcfunction(L: Plua_State; f: lua_CFunction);
function lua_isfunction(L: Plua_State; n: integer): boolean;
function lua_istable(L: Plua_State; n: integer): boolean;
function lua_islightuserdata(L: Plua_State; n: integer): boolean;
function lua_isnil(L: Plua_State; n: integer): boolean;
function lua_isboolean(L: Plua_State; n: integer): boolean;
function lua_isthread(L: Plua_State; n: integer): boolean;
function lua_isnone(L: Plua_State; n: integer): boolean;
function lua_isnoneornil(L: Plua_State; n: integer): boolean;
procedure lua_pushliteral(L: Plua_State; s: PChar);
procedure lua_pushglobaltable(L: Plua_State);
function lua_tostring(L: Plua_State; i: integer): PChar;

// Debug API
const
  // Event codes
  LUA_HOOKCALL = 0;
  LUA_HOOKRET = 1;
  LUA_HOOKLINE = 2;
  LUA_HOOKCOUNT = 3;
  LUA_HOOKTAILCALL = 4;

  // Event masks
  LUA_MASKCALL = 1 shl Ord(LUA_HOOKCALL);
  LUA_MASKRET = 1 shl Ord(LUA_HOOKRET);
  LUA_MASKLINE = 1 shl Ord(LUA_HOOKLINE);
  LUA_MASKCOUNT = 1 shl Ord(LUA_HOOKCOUNT);

  LUA_IDSIZE = 60;

type
  lua_Debug = record (* activation record *)
    event: integer;
    Name: PChar; (* (n) *)
    namewhat: PChar; (* (n) `global', `local', `field', `method' *)
    what: PChar; (* (S) `Lua', `C', `main', `tail'*)
    Source: PChar; (* (S) *)
    currentline: integer; (* (l) *)
    linedefined: integer; (* (S) *)
    lastlinedefined: integer; (* (S) *)
    nups: byte; (* (u) number of upvalues *)
    nparams: byte; (* (u) number of parameters *)
    isvararg: bytebool; (* (u) *)
    istailcall: bytebool; (* (t) *)
    short_src: array[0..LUA_IDSIZE - 1] of char; (* (S) *)
    (* private part *)
    i_ci: Pointer; (* active function *) // ptr to struct CallInfo
  end;
  Plua_Debug = ^lua_Debug;

  // Functions to be called by the debugger in specific events
  lua_Hook = procedure(L: Plua_State; ar: Plua_Debug); cdecl;

function lua_getstack(L: Plua_State; level: integer; ar: Plua_Debug): integer; cdecl;
function lua_getinfo(L: Plua_State; const what: PChar; ar: Plua_Debug): integer; cdecl;
function lua_getlocal(L: Plua_State; const ar: Plua_Debug; n: integer): PChar; cdecl;
function lua_setlocal(L: Plua_State; const ar: Plua_Debug; n: integer): PChar; cdecl;
function lua_getupvalue(L: Plua_State; funcindex, n: integer): PChar; cdecl;
function lua_setupvalue(L: Plua_State; funcindex, n: integer): PChar; cdecl;
function lua_upvalueid(L: Plua_State; funcindex, n: integer): Pointer; cdecl;
procedure lua_upvaluejoin(L: Plua_State; funcindex1, n1, funcindex2, n2: integer); cdecl;
function lua_sethook(L: Plua_State; func: lua_Hook; mask: integer; Count: integer): integer; cdecl;
function lua_gethook(L: Plua_State): lua_Hook; cdecl;
function lua_gethookmask(L: Plua_State): integer; cdecl;
function lua_gethookcount(L: Plua_State): integer; cdecl;

// pre-defined references
const
  LUA_NOREF = -2;
  LUA_REFNIL = -1;

// compatibility with ref system
procedure lua_unref(L: Plua_State; ref: integer);
procedure lua_getref(L: Plua_State; ref: integer);

type
  luaL_Reg = record
    Name: PChar;
    func: lua_CFunction;
  end;
  PluaL_Reg = ^luaL_Reg;

procedure luaL_checkversion_(L: Plua_State; ver: lua_Number); cdecl;
procedure luaL_checkversion(L: Plua_State);
function luaL_getmetafield(L: Plua_State; obj: integer; const e: PChar): integer; cdecl;
function luaL_callmeta(L: Plua_State; obj: integer; const e: PChar): integer; cdecl;
function luaL_tolstring(L: Plua_State; idx: integer; len: Psize_t): PChar; cdecl;
function luaL_argerror(L: Plua_State; numarg: integer; const extramsg: PChar): integer; cdecl;
function luaL_checklstring(L: Plua_State; numArg: integer; l_: Psize_t): PChar; cdecl;
function luaL_optlstring(L: Plua_State; numArg: integer; const def: PChar; l_: Psize_t): PChar; cdecl;
function luaL_checknumber(L: Plua_State; numArg: integer): lua_Number; cdecl;
function luaL_optnumber(L: Plua_State; nArg: integer; def: lua_Number): lua_Number; cdecl;
function luaL_checkinteger(L: Plua_State; numArg: integer): lua_Integer; cdecl;
function luaL_optinteger(L: Plua_State; nArg: integer; def: lua_Integer): lua_Integer; cdecl;
function luaL_checkunsigned(L: Plua_State; numArg: integer): lua_Unsigned; cdecl;
function luaL_optunsigned(L: Plua_State; numArg: integer; def: lua_Unsigned): lua_Unsigned; cdecl;
procedure luaL_checkstack(L: Plua_State; sz: integer; const msg: PChar); cdecl;
procedure luaL_checktype(L: Plua_State; narg, t: integer); cdecl;
procedure luaL_checkany(L: Plua_State; narg: integer); cdecl;
function luaL_newmetatable(L: Plua_State; const tname: PChar): integer; cdecl;
procedure luaL_setmetatable(L: Plua_State; const tname: PChar); cdecl;
function luaL_testudata(L: Plua_State; ud: integer; const tname: PChar): Pointer; cdecl;
function luaL_checkudata(L: Plua_State; ud: integer; const tname: PChar): Pointer; cdecl;
procedure luaL_where(L: Plua_State; lvl: integer); cdecl;
function luaL_error(L: Plua_State; const fmt: PChar; args: array of const): integer;
  cdecl; external LUA_LIB_NAME; // note: C's ... to array of const conversion is not portable to Delphi
function luaL_checkoption(L: Plua_State; narg: integer; def: PChar; lst: PPChar): integer; cdecl;
function luaL_fileresult(L: Plua_State; stat: integer; const fname: PChar): integer; cdecl;
function luaL_execresult(L: Plua_State; stat: integer): integer; cdecl;
function luaL_ref(L: Plua_State; t: integer): integer; cdecl;
procedure luaL_unref(L: Plua_State; t, ref: integer); cdecl;
function luaL_loadfilex(L: Plua_State; const filename, mode: PChar): integer; cdecl;
function luaL_loadfile(L: Plua_State; const filename: PChar): integer;
function luaL_loadbufferx(L: Plua_State; const buff: PChar; sz: size_t; const Name, mode: PChar): integer; cdecl;
function luaL_loadstring(L: Plua_State; const s: PChar): integer; cdecl;
function luaL_newstate: Plua_State; cdecl;
function luaL_len(L: Plua_State; idx: integer): integer; cdecl;
function luaL_gsub(L: Plua_State; const s, p, r: PChar): PChar; cdecl;
procedure luaL_setfuncs(L: Plua_State; lr: array of luaL_Reg; nup: integer); overload;
procedure luaL_setfuncs(L: Plua_State; lr: PluaL_Reg; nup: integer); cdecl; overload;
function luaL_getsubtable(L: Plua_State; idx: integer; const fname: PChar): integer; cdecl;
procedure luaL_traceback(L, L1: Plua_State; msg: PChar; level: integer); cdecl;
procedure luaL_requiref(L: Plua_State; const modname: PChar; openf: lua_CFunction; glb: longbool); cdecl;

// some useful macros
procedure luaL_newlibtable(L: Plua_State; lr: array of luaL_Reg); overload;
procedure luaL_newlibtable(L: Plua_State; lr: PluaL_Reg); overload;
procedure luaL_newlib(L: Plua_State; lr: array of luaL_Reg); overload;
procedure luaL_newlib(L: Plua_State; lr: PluaL_Reg); overload;
procedure luaL_argcheck(L: Plua_State; cond: boolean; numarg: integer; extramsg: PChar);
function luaL_checkstring(L: Plua_State; n: integer): PChar;
function luaL_optstring(L: Plua_State; n: integer; d: PChar): PChar;
function luaL_checkint(L: Plua_State; n: integer): integer;
function luaL_optint(L: Plua_State; n, d: integer): integer;
function luaL_checklong(L: Plua_State; n: integer): longint;
function luaL_optlong(L: Plua_State; n: integer; d: longint): longint;
function luaL_typename(L: Plua_State; i: integer): PChar;
function luaL_dofile(L: Plua_State; const filename: PChar): integer;
function luaL_dostring(L: Plua_State; const str: PChar): integer;
procedure luaL_getmetatable(L: Plua_State; tname: PChar);
function luaL_loadbuffer(L: Plua_State; const buff: PChar; size: size_t; const Name: PChar): integer;

const
  LUA_COLIBNAME = 'coroutine';
  LUA_TABLIBNAME = 'table';
  LUA_IOLIBNAME = 'io';
  LUA_OSLIBNAME = 'os';
  LUA_STRLINAME = 'string';
  LUA_BITLIBNAME = 'bit32';
  LUA_MATHLIBNAME = 'math';
  LUA_DBLIBNAME = 'debug';
  LUA_LOADLIBNAME = 'package';

function luaopen_base(L: Plua_State): longbool; cdecl;
function luaopen_coroutine(L: Plua_State): longbool; cdecl;
function luaopen_table(L: Plua_State): longbool; cdecl;
function luaopen_io(L: Plua_State): longbool; cdecl;
function luaopen_os(L: Plua_State): longbool; cdecl;
function luaopen_string(L: Plua_State): longbool; cdecl;
function luaopen_bit32(L: Plua_State): longbool; cdecl;
function luaopen_math(L: Plua_State): longbool; cdecl;
function luaopen_debug(L: Plua_State): longbool; cdecl;
function luaopen_package(L: Plua_State): longbool; cdecl;

// open all previous libraries
procedure luaL_openlibs(L: Plua_State); cdecl;

{
//------------------------------------------
// LUA_COMPAT_MODULE (deprecated functions)
//------------------------------------------
procedure luaL_pushmodule(L: Plua_State; modname: PChar; sizehint: Integer); cdecl;
procedure luaL_openlib(L: Plua_State; const libname: PChar; lr: PluaL_Reg; nup: Integer); cdecl; overload;
procedure luaL_openlib(L: Plua_State; const libname: PChar; lr: array of luaL_Reg; nup: Integer); overload;
procedure luaL_register(L: Plua_State; const libname: PChar; lr: array of luaL_Reg); overload;
procedure luaL_register(L: Plua_State; const libname: PChar; lr: PluaL_Reg); overload;
//------------------------------------------
}

implementation

{
//------------------------------------------
// LUA_COMPAT_MODULE (deprecated functions)
//------------------------------------------
procedure luaL_pushmodule(L: Plua_State; modname: PChar; sizehint: Integer); cdecl; external LUA_LIB_NAME;
procedure luaL_openlib(L: Plua_State; const libname: PChar; lr: PluaL_Reg; nup: Integer); cdecl; external LUA_LIB_NAME;

procedure luaL_openlib(L: Plua_State; const libname: PChar; lr: array of luaL_Reg; nup: Integer);
begin
   luaL_openlib(L, libname, @lr, nup);
end;

procedure luaL_register(L: Plua_State; const libname: PChar; lr: array of luaL_Reg);
begin
   luaL_openlib(L, libname, @lr, 0);
end;

procedure luaL_register(L: Plua_State; const libname: PChar; lr: PluaL_Reg);
begin
   luaL_openlib(L, libname, lr, 0);
end;
//------------------------------------------
}

function lua_upvalueindex(I: integer): integer;
begin
  Result := LUA_REGISTRYINDEX - i;
end;

function lua_newstate(f: lua_Alloc; ud: Pointer): Plua_State; cdecl; external LUA_LIB_NAME;

procedure lua_close(L: Plua_State); cdecl; external LUA_LIB_NAME;

function lua_newthread(L: Plua_State): Plua_State; cdecl; external LUA_LIB_NAME;

function lua_atpanic(L: Plua_State; panicf: lua_CFunction): lua_CFunction; cdecl; external LUA_LIB_NAME;

function lua_version(L: Plua_State): Plua_Number; cdecl; external LUA_LIB_NAME;

function lua_absindex(L: Plua_State; idx: integer): integer; cdecl; external LUA_LIB_NAME;

function lua_gettop(L: Plua_State): integer; cdecl; external LUA_LIB_NAME;

procedure lua_settop(L: Plua_State; idx: integer); cdecl; external LUA_LIB_NAME;

procedure lua_pushvalue(L: Plua_State; Idx: integer); cdecl; external LUA_LIB_NAME;

procedure lua_remove(L: Plua_State; idx: integer); cdecl; external LUA_LIB_NAME;

procedure lua_insert(L: Plua_State; idx: integer); cdecl; external LUA_LIB_NAME;

procedure lua_replace(L: Plua_State; idx: integer); cdecl; external LUA_LIB_NAME;

procedure lua_copy(L: Plua_State; fromidx, toidx: integer); cdecl; external LUA_LIB_NAME;

function lua_checkstack(L: Plua_State; sz: integer): longbool; cdecl; external LUA_LIB_NAME;

procedure lua_xmove(from, to_: Plua_State; n: integer); cdecl; external LUA_LIB_NAME;

function lua_isnumber(L: Plua_State; idx: integer): longbool; cdecl; external LUA_LIB_NAME;

function lua_isstring(L: Plua_State; idx: integer): longbool; cdecl; external LUA_LIB_NAME;

function lua_iscfunction(L: Plua_State; idx: integer): longbool; cdecl; external LUA_LIB_NAME;

function lua_isuserdata(L: Plua_State; idx: integer): longbool; cdecl; external LUA_LIB_NAME;

function lua_type(L: Plua_State; idx: integer): integer; cdecl; external LUA_LIB_NAME;

function lua_typename(L: Plua_State; tp: integer): PChar; cdecl; external LUA_LIB_NAME;

function lua_tonumberx(L: Plua_State; idx: integer; isnum: PLongBool): lua_Number; cdecl; external LUA_LIB_NAME;

function lua_tointegerx(L: Plua_State; idx: integer; isnum: PLongBool): lua_Integer; cdecl; external LUA_LIB_NAME;

function lua_tounsignedx(L: Plua_State; idx: integer; isnum: PLongBool): lua_Unsigned; cdecl; external LUA_LIB_NAME;

procedure lua_arith(L: Plua_State; op: integer); cdecl; external LUA_LIB_NAME;

function lua_rawequal(L: Plua_State; idx1, idx2: integer): longbool; cdecl; external LUA_LIB_NAME;

function lua_compare(L: Plua_State; idx1, idx2, op: integer): longbool; cdecl; external LUA_LIB_NAME;

function lua_tonumber(L: Plua_State; idx: integer): lua_Number;
begin
  Result := lua_tonumberx(L, idx, nil);
end;

function lua_tointeger(L: Plua_State; idx: integer): lua_Integer;
begin
  Result := lua_tointegerx(L, idx, nil);
end;

function lua_tounsigned(L: Plua_State; idx: integer): lua_Unsigned;
begin
  Result := lua_tounsignedx(L, idx, nil);
end;

function lua_toboolean(L: Plua_State; idx: integer): longbool; cdecl; external LUA_LIB_NAME;

function lua_tolstring(L: Plua_State; idx: integer; len: Psize_t): PChar; cdecl; external LUA_LIB_NAME;

function lua_rawlen(L: Plua_State; idx: integer): size_t; cdecl; external LUA_LIB_NAME;

function lua_tocfunction(L: Plua_State; idx: integer): lua_CFunction; cdecl; external LUA_LIB_NAME;

function lua_touserdata(L: Plua_State; idx: integer): Pointer; cdecl; external LUA_LIB_NAME;

function lua_tothread(L: Plua_State; idx: integer): Plua_State; cdecl; external LUA_LIB_NAME;

function lua_topointer(L: Plua_State; idx: integer): Pointer; cdecl; external LUA_LIB_NAME;

procedure lua_pushnil(L: Plua_State); cdecl; external LUA_LIB_NAME;

procedure lua_pushnumber(L: Plua_State; n: lua_Number); cdecl; external LUA_LIB_NAME;

procedure lua_pushinteger(L: Plua_State; n: lua_Integer); cdecl; external LUA_LIB_NAME;

procedure lua_pushunsigned(L: Plua_State; n: lua_Unsigned); cdecl; external LUA_LIB_NAME;

procedure lua_pushlstring(L: Plua_State; const s: PChar; l_: size_t); cdecl; external LUA_LIB_NAME;

procedure lua_pushstring(L: Plua_State; const s: PChar); cdecl; external LUA_LIB_NAME;

procedure lua_pushstring(L: Plua_State; const s: string);
begin
  lua_pushlstring(L, PChar(s), Length(s));
end;

function lua_pushvfstring(L: Plua_State; const fmt: PChar; argp: Pointer): PChar; cdecl; external LUA_LIB_NAME;

function lua_pushfstring(L: Plua_State; const fmt: PChar): PChar; cdecl; varargs; external LUA_LIB_NAME;

procedure lua_pushcclosure(L: Plua_State; fn: lua_CFunction; n: integer); cdecl; external LUA_LIB_NAME;

procedure lua_pushboolean(L: Plua_State; b: longbool); cdecl; external LUA_LIB_NAME;

procedure lua_pushlightuserdata(L: Plua_State; p: Pointer); cdecl; external LUA_LIB_NAME;

procedure lua_pushthread(L: Plua_State); cdecl; external LUA_LIB_NAME;

procedure lua_getglobal(L: Plua_State; const var_: PChar); cdecl; external LUA_LIB_NAME;

procedure lua_gettable(L: Plua_State; idx: integer); cdecl; external LUA_LIB_NAME;

procedure lua_getfield(L: Plua_state; idx: integer; k: PChar); cdecl; external LUA_LIB_NAME;

procedure lua_rawget(L: Plua_State; idx: integer); cdecl; external LUA_LIB_NAME;

procedure lua_rawgeti(L: Plua_State; idx, n: integer); cdecl; external LUA_LIB_NAME;

procedure lua_rawgetp(L: Plua_State; idx: integer; p: Pointer); cdecl; external LUA_LIB_NAME;

procedure lua_createtable(L: Plua_State; narr, nrec: integer); cdecl; external LUA_LIB_NAME;

function lua_newuserdata(L: Plua_State; sz: size_t): Pointer; cdecl; external LUA_LIB_NAME;

function lua_getmetatable(L: Plua_State; objindex: integer): integer; cdecl; external LUA_LIB_NAME;

procedure lua_getuservalue(L: Plua_State; idx: integer); cdecl; external LUA_LIB_NAME;

procedure lua_setglobal(L: Plua_State; const var_: PChar); cdecl; external LUA_LIB_NAME;

procedure lua_settable(L: Plua_State; idx: integer); cdecl; external LUA_LIB_NAME;

procedure lua_setfield(L: Plua_State; idx: integer; k: PChar); cdecl; external LUA_LIB_NAME;

procedure lua_rawset(L: Plua_State; idx: integer); cdecl; external LUA_LIB_NAME;

procedure lua_rawseti(L: Plua_State; idx, n: integer); cdecl; external LUA_LIB_NAME;

procedure lua_rawsetp(L: Plua_State; idx: integer; p: Pointer); cdecl; external LUA_LIB_NAME;

function lua_setmetatable(L: Plua_State; objindex: integer): integer; cdecl; external LUA_LIB_NAME;

procedure lua_setuservalue(L: Plua_State; idx: integer); cdecl; external LUA_LIB_NAME;

procedure lua_callk(L: Plua_State; nargs, nresults, ctx: integer; k: lua_CFunction); cdecl; external LUA_LIB_NAME;

function lua_getctx(L: Plua_State; ctx: PInteger): integer; cdecl; external LUA_LIB_NAME;

function lua_pcallk(L: Plua_State; nargs, nresults, errfunc, ctx: integer; k: lua_CFunction): integer;
  cdecl; external LUA_LIB_NAME;

function lua_load(L: Plua_State; reader: lua_Reader; dt: Pointer; const chunkname, mode: PChar): integer;
  cdecl; external LUA_LIB_NAME;

function lua_dump(L: Plua_State; writer: lua_Writer; Data: Pointer): integer; cdecl; external LUA_LIB_NAME;

function lua_yieldk(L: Plua_State; nresults, ctx: integer; k: lua_CFunction): integer; cdecl; external LUA_LIB_NAME;

procedure lua_call(L: Plua_State; nargs, nresults: integer);
begin
  lua_callk(L, nargs, nresults, 0, nil);
end;

function lua_pcall(L: Plua_State; nargs, nresults, errf: integer): integer;
begin
  Result := lua_pcallk(L, nargs, nresults, errf, 0, nil);
end;

function lua_yield(L: Plua_State; nresults: integer): integer;
begin
  Result := lua_yieldk(L, nresults, 0, nil);
end;

function lua_resume(L, from: Plua_State; narg: integer): integer; cdecl; external LUA_LIB_NAME;

function lua_status(L: Plua_State): integer; cdecl; external LUA_LIB_NAME;

function lua_gc(L: Plua_State; what, Data: integer): integer; cdecl; external LUA_LIB_NAME;

function lua_error(L: Plua_State): integer; cdecl; external LUA_LIB_NAME;

function lua_next(L: Plua_State; idx: integer): integer; cdecl; external LUA_LIB_NAME;

procedure lua_concat(L: Plua_State; n: integer); cdecl; external LUA_LIB_NAME;

procedure lua_len(L: Plua_State; idx: integer); cdecl; external LUA_LIB_NAME;

function lua_getallocf(L: Plua_State; ud: PPointer): lua_Alloc; cdecl; external LUA_LIB_NAME;

procedure lua_setallocf(L: Plua_State; f: lua_Alloc; ud: Pointer); cdecl; external LUA_LIB_NAME;

procedure lua_pop(L: Plua_State; n: integer);
begin
  lua_settop(L, -n - 1);
end;

procedure lua_newtable(L: Plua_State);
begin
  lua_createtable(L, 0, 0);
end;

procedure lua_register(L: Plua_State; const n: PChar; f: lua_CFunction);
begin
  lua_pushcfunction(L, f);
  lua_setglobal(L, n);
end;

procedure lua_pushcfunction(L: Plua_State; f: lua_CFunction);
begin
  lua_pushcclosure(L, f, 0);
end;

function lua_isfunction(L: Plua_State; n: integer): boolean;
begin
  Result := lua_type(L, n) = LUA_TFUNCTION;
end;

function lua_istable(L: Plua_State; n: integer): boolean;
begin
  Result := lua_type(L, n) = LUA_TTABLE;
end;

function lua_islightuserdata(L: Plua_State; n: integer): boolean;
begin
  Result := lua_type(L, n) = LUA_TLIGHTUSERDATA;
end;

function lua_isnil(L: Plua_State; n: integer): boolean;
begin
  Result := lua_type(L, n) = LUA_TNIL;
end;

function lua_isboolean(L: Plua_State; n: integer): boolean;
begin
  Result := lua_type(L, n) = LUA_TBOOLEAN;
end;

function lua_isthread(L: Plua_State; n: integer): boolean;
begin
  Result := lua_type(L, n) = LUA_TTHREAD;
end;

function lua_isnone(L: Plua_State; n: integer): boolean;
begin
  Result := lua_type(L, n) = LUA_TNONE;
end;

function lua_isnoneornil(L: Plua_State; n: integer): boolean;
begin
  Result := lua_type(L, n) <= 0;
end;

procedure lua_pushliteral(L: Plua_State; s: PChar);
begin
  lua_pushlstring(L, s, Length(s));
end;

procedure lua_pushglobaltable(L: Plua_State);
begin
  lua_rawgeti(L, LUA_REGISTRYINDEX, LUA_RIDX_GLOBALS);
end;

function lua_tostring(L: Plua_State; i: integer): PChar;
begin
  Result := lua_tolstring(L, i, nil);
end;

function lua_getstack(L: Plua_State; level: integer; ar: Plua_Debug): integer; cdecl; external LUA_LIB_NAME;

function lua_getinfo(L: Plua_State; const what: PChar; ar: Plua_Debug): integer; cdecl; external LUA_LIB_NAME;

function lua_getlocal(L: Plua_State; const ar: Plua_Debug; n: integer): PChar; cdecl; external LUA_LIB_NAME;

function lua_setlocal(L: Plua_State; const ar: Plua_Debug; n: integer): PChar; cdecl; external LUA_LIB_NAME;

function lua_getupvalue(L: Plua_State; funcindex, n: integer): PChar; cdecl; external LUA_LIB_NAME;

function lua_setupvalue(L: Plua_State; funcindex, n: integer): PChar; cdecl; external LUA_LIB_NAME;

function lua_upvalueid(L: Plua_State; funcindex, n: integer): Pointer; cdecl; external LUA_LIB_NAME;

procedure lua_upvaluejoin(L: Plua_State; funcindex1, n1, funcindex2, n2: integer); cdecl; external LUA_LIB_NAME;

function lua_sethook(L: Plua_State; func: lua_Hook; mask: integer; Count: integer): integer;
  cdecl; external LUA_LIB_NAME;

function lua_gethook(L: Plua_State): lua_Hook; cdecl; external LUA_LIB_NAME;

function lua_gethookmask(L: Plua_State): integer; cdecl; external LUA_LIB_NAME;

function lua_gethookcount(L: Plua_State): integer; cdecl; external LUA_LIB_NAME;

procedure lua_unref(L: Plua_State; ref: integer);
begin
  luaL_unref(L, LUA_REGISTRYINDEX, ref);
end;

procedure lua_getref(L: Plua_State; ref: integer);
begin
  lua_rawgeti(L, LUA_REGISTRYINDEX, ref);
end;

procedure luaL_traceback(L, L1: Plua_State; msg: PChar; level: integer); cdecl; external LUA_LIB_NAME;

function luaL_argerror(L: Plua_State; numarg: integer; const extramsg: PChar): integer; cdecl; external LUA_LIB_NAME;

procedure luaL_where(L: Plua_State; lvl: integer); cdecl; external LUA_LIB_NAME;

function luaL_newmetatable(L: Plua_State; const tname: PChar): integer; cdecl; external LUA_LIB_NAME;

procedure luaL_setmetatable(L: Plua_State; const tname: PChar); cdecl; external LUA_LIB_NAME;

function luaL_testudata(L: Plua_State; ud: integer; const tname: PChar): Pointer; cdecl; external LUA_LIB_NAME;

function luaL_checkudata(L: Plua_State; ud: integer; const tname: PChar): Pointer; cdecl; external LUA_LIB_NAME;

function luaL_checkoption(L: Plua_State; narg: integer; def: PChar; lst: PPChar): integer;
  cdecl; external LUA_LIB_NAME;

procedure luaL_checkstack(L: Plua_State; sz: integer; const msg: PChar); cdecl; external LUA_LIB_NAME;

procedure luaL_checktype(L: Plua_State; narg, t: integer); cdecl; external LUA_LIB_NAME;

procedure luaL_checkany(L: Plua_State; narg: integer); cdecl; external LUA_LIB_NAME;

function luaL_checklstring(L: Plua_State; numArg: integer; l_: Psize_t): PChar; cdecl; external LUA_LIB_NAME;

function luaL_optlstring(L: Plua_State; numArg: integer; const def: PChar; l_: Psize_t): PChar;
  cdecl; external LUA_LIB_NAME;

function luaL_checknumber(L: Plua_State; numArg: integer): lua_Number; cdecl; external LUA_LIB_NAME;

function luaL_optnumber(L: Plua_State; nArg: integer; def: lua_Number): lua_Number; cdecl; external LUA_LIB_NAME;

function luaL_checkinteger(L: Plua_State; numArg: integer): lua_Integer; cdecl; external LUA_LIB_NAME;

function luaL_optinteger(L: Plua_State; nArg: integer; def: lua_Integer): lua_Integer; cdecl; external LUA_LIB_NAME;

function luaL_checkunsigned(L: Plua_State; numArg: integer): lua_Unsigned; cdecl; external LUA_LIB_NAME;

function luaL_optunsigned(L: Plua_State; numArg: integer; def: lua_Unsigned): lua_Unsigned;
  cdecl; external LUA_LIB_NAME;

procedure luaL_argcheck(L: Plua_State; cond: boolean; numarg: integer; extramsg: PChar);
begin
  if not cond then
    luaL_argerror(L, numarg, extramsg);
end;

function luaL_checkstring(L: Plua_State; n: integer): PChar;
begin
  Result := luaL_checklstring(L, n, nil);
end;

function luaL_optstring(L: Plua_State; n: integer; d: PChar): PChar;
begin
  Result := luaL_optlstring(L, n, d, nil);
end;

function luaL_checkint(L: Plua_State; n: integer): integer;
begin
  Result := luaL_checkinteger(L, n);
end;

function luaL_checklong(L: Plua_State; n: integer): longint;
begin
  Result := luaL_checkinteger(L, n);
end;

function luaL_optint(L: Plua_State; n, d: integer): integer;
begin
  Result := luaL_optinteger(L, n, d);
end;

function luaL_optlong(L: Plua_State; n: integer; d: longint): longint;
begin
  Result := luaL_optinteger(L, n, d);
end;

function luaL_typename(L: Plua_State; i: integer): PChar;
begin
  Result := lua_typename(L, lua_type(L, i));
end;

function luaL_dofile(L: Plua_State; const filename: PChar): integer;
begin
  Result := luaL_loadfile(L, filename);
  if Result = 0 then
    Result := lua_pcall(L, 0, LUA_MULTRET, 0);
end;

function luaL_dostring(L: Plua_State; const str: PChar): integer;
begin
  Result := luaL_loadstring(L, str);
  if Result = 0 then
    Result := lua_pcall(L, 0, LUA_MULTRET, 0);
end;

procedure luaL_getmetatable(L: Plua_State; tname: PChar);
begin
  lua_getfield(L, LUA_REGISTRYINDEX, tname);
end;

function luaL_fileresult(L: Plua_State; stat: integer; const fname: PChar): integer; cdecl; external LUA_LIB_NAME;

function luaL_execresult(L: Plua_State; stat: integer): integer; cdecl; external LUA_LIB_NAME;

function luaL_ref(L: Plua_State; t: integer): integer; cdecl; external LUA_LIB_NAME;

procedure luaL_unref(L: Plua_State; t, ref: integer); cdecl; external LUA_LIB_NAME;

function luaL_loadfilex(L: Plua_State; const filename, mode: PChar): integer; cdecl; external LUA_LIB_NAME;

function luaL_loadbufferx(L: Plua_State; const buff: PChar; sz: size_t; const Name, mode: PChar): integer;
  cdecl; external LUA_LIB_NAME;

function luaL_loadfile(L: Plua_State; const filename: PChar): integer;
begin
  Result := luaL_loadfilex(L, filename, nil);
end;

function luaL_loadbuffer(L: Plua_State; const buff: PChar; size: size_t; const Name: PChar): integer;
begin
  Result := luaL_loadbufferx(L, buff, size, Name, nil);
end;

function luaL_loadstring(L: Plua_State; const s: PChar): integer; cdecl; external LUA_LIB_NAME;

function luaL_getmetafield(L: Plua_State; obj: integer; const e: PChar): integer; cdecl; external LUA_LIB_NAME;

function luaL_callmeta(L: Plua_State; obj: integer; const e: PChar): integer; cdecl; external LUA_LIB_NAME;

function luaL_tolstring(L: Plua_State; idx: integer; len: Psize_t): PChar; cdecl; external LUA_LIB_NAME;

procedure luaL_requiref(L: Plua_State; const modname: PChar; openf: lua_CFunction; glb: longbool);
  cdecl; external LUA_LIB_NAME;

procedure luaL_setfuncs(L: Plua_State; lr: PluaL_Reg; nup: integer); cdecl; external LUA_LIB_NAME;

procedure luaL_setfuncs(L: Plua_State; lr: array of luaL_Reg; nup: integer);
begin
  luaL_setfuncs(L, @lr, nup);
end;

procedure luaL_newlibtable(L: Plua_State; lr: array of luaL_Reg);
begin
  lua_createtable(L, 0, High(lr));
end;

procedure luaL_newlibtable(L: Plua_State; lr: PluaL_Reg);
var
  n: integer;
begin
  n := 0;
  while lr^.Name <> nil do
  begin
    Inc(n);
    Inc(lr);
  end;
  lua_createtable(L, 0, n);
end;

procedure luaL_newlib(L: Plua_State; lr: array of luaL_Reg);
begin
  luaL_newlibtable(L, lr);
  luaL_setfuncs(L, @lr, 0);
end;

procedure luaL_newlib(L: Plua_State; lr: PluaL_Reg);
begin
  luaL_newlibtable(L, lr);
  luaL_setfuncs(L, lr, 0);
end;

function luaL_gsub(L: Plua_State; const s, p, r: PChar): PChar; cdecl; external LUA_LIB_NAME;

function luaL_getsubtable(L: Plua_State; idx: integer; const fname: PChar): integer; cdecl; external LUA_LIB_NAME;

function luaL_newstate: Plua_State; cdecl; external LUA_LIB_NAME;

function luaL_len(L: Plua_State; idx: integer): integer; cdecl; external LUA_LIB_NAME;

procedure luaL_checkversion_(L: Plua_State; ver: lua_Number); cdecl; external LUA_LIB_NAME;

procedure luaL_checkversion(L: Plua_State);
begin
  luaL_checkversion_(L, LUA_VERSION_NUM);
end;

function luaopen_base(L: Plua_State): longbool; cdecl; external LUA_LIB_NAME;

function luaopen_coroutine(L: Plua_State): longbool; cdecl; external LUA_LIB_NAME;

function luaopen_table(L: Plua_State): longbool; cdecl; external LUA_LIB_NAME;

function luaopen_io(L: Plua_State): longbool; cdecl; external LUA_LIB_NAME;

function luaopen_os(L: Plua_State): longbool; cdecl; external LUA_LIB_NAME;

function luaopen_string(L: Plua_State): longbool; cdecl; external LUA_LIB_NAME;

function luaopen_bit32(L: Plua_State): longbool; cdecl; external LUA_LIB_NAME;

function luaopen_math(L: Plua_State): longbool; cdecl; external LUA_LIB_NAME;

function luaopen_debug(L: Plua_State): longbool; cdecl; external LUA_LIB_NAME;

function luaopen_package(L: Plua_State): longbool; cdecl; external LUA_LIB_NAME;

procedure luaL_openlibs(L: Plua_State); cdecl; external LUA_LIB_NAME;

initialization
{$IFDEF MSWINDOWS}
  Set8087CW($133F); // disable all floating-point exceptions
{$ENDIF}

  (******************************************************************************
  * Copyright (C) 1994-2012 Lua.org, PUC-Rio.
  *
  * Permission is hereby granted, free of charge, to any person obtaining
  * a copy of this software and associated documentation files (the
  * "Software"), to deal in the Software without restriction, including
  * without limitation the rights to use, copy, modify, merge, publish,
  * distribute, sublicense, and/or sell copies of the Software, and to
  * permit persons to whom the Software is furnished to do so, subject to
  * the following conditions:
  *
  * The above copyright notice and this permission notice shall be
  * included in all copies or substantial portions of the Software.
  *
  * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
  * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
  * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
  * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
  * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
  * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  ******************************************************************************)

end.
