#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
pas2cpp_check.py  —  Pascal interface ↔ C++ header 签名比对检查工具

用于检查 Pascal 源码与 C++ 移植版之间的函数签名差异：
  - Pascal 有但 C++ 缺失的函数
  - C++ 多出的函数（可能是新增、或 Pascal 函数被改名/合并）
  - 参数数量不一致
  - 参数类型显著不匹配

用法:
  python pas2cpp_check.py                               # 检查 kys-pascal
  python pas2cpp_check.py --pig3 D:\\path\\to\\kys-pig3  # 同时检查 pig3
  python pas2cpp_check.py --pas kys_event.pas --cpp kys_event.h  # 单文件
"""

import re
import sys
import os
import argparse
from dataclasses import dataclass, field
from typing import List, Dict, Tuple, Optional
from collections import defaultdict

# ──────────────────────────────────────────────────────────────────────────────
# 类型归一化表
# ──────────────────────────────────────────────────────────────────────────────

# 规范族标签（用于"相容"判断）
_INT    = 'INT'
_STR    = 'STR'
_PCHAR  = 'PCHAR'
_PTR    = 'PTR'
_BOOL   = 'BOOL'
_FLOAT  = 'FLOAT'
_VOID   = 'VOID'
_LUA    = 'LUA'
_SDL    = 'SDL'
_VEC    = 'VEC'

# Pascal 类型小写 → (族, 可读名)
PAS_TYPE: Dict[str, Tuple[str, str]] = {
    'integer':      (_INT,   'int'),
    'longint':      (_INT,   'int'),
    'cardinal':     (_INT,   'uint32'),
    'uint32':       (_INT,   'uint32'),
    'smallint':     (_INT,   'int16'),
    'shortint':     (_INT,   'int8'),
    'word':         (_INT,   'uint16'),
    'byte':         (_INT,   'uint8'),
    'int64':        (_INT,   'int64'),
    'uint64':       (_INT,   'uint64'),
    'boolean':      (_BOOL,  'bool'),
    'bool':         (_BOOL,  'bool'),
    'single':       (_FLOAT, 'float'),
    'double':       (_FLOAT, 'double'),
    'real':         (_FLOAT, 'double'),
    'char':         (_STR,   'char'),
    'ansichar':     (_STR,   'char'),
    'widechar':     (_STR,   'wchar'),
    'string':       (_STR,   'string'),
    'utf8string':   (_STR,   'string'),
    'ansistring':   (_STR,   'string'),
    'shortstring':  (_STR,   'string'),
    'pansichar':    (_PCHAR, 'const char*'),
    'putf8char':    (_PCHAR, 'const char*'),
    'pchar':        (_PCHAR, 'const char*'),
    'pwidechar':    (_PCHAR, 'const wchar_t*'),
    'pointer':      (_PTR,   'void*'),
    'psdl_surface': (_SDL,   'SDL_Surface*'),
    'ppsdl_surface':(_SDL,   'SDL_Surface**'),
    'plua_state':   (_LUA,   'lua_State*'),
    'tsdl_color':   (_SDL,   'SDL_Color'),
    'tsdl_rect':    (_SDL,   'SDL_Rect'),
    'tsdl_timerid': (_SDL,   'SDL_TimerID'),
    'tposition':    (_SDL,   'TPosition'),
    'tpint1':       (_PTR,   'TPInt1'),
    'void':         (_VOID,  'void'),
}

# C++ 类型小写 → (族, 可读名)
CPP_TYPE: Dict[str, Tuple[str, str]] = {
    'int':          (_INT,   'int'),
    'unsigned':     (_INT,   'uint32'),
    'unsigned int': (_INT,   'uint32'),
    'long':         (_INT,   'int'),
    'long int':     (_INT,   'int'),
    'short':        (_INT,   'int16'),
    'unsigned short':(_INT,  'uint16'),
    'int8_t':       (_INT,   'int8'),
    'int16_t':      (_INT,   'int16'),
    'int32_t':      (_INT,   'int'),
    'uint8_t':      (_INT,   'uint8'),
    'uint16_t':     (_INT,   'uint16'),
    'uint32_t':     (_INT,   'uint32'),
    'int64_t':      (_INT,   'int64'),
    'uint64_t':     (_INT,   'uint64'),
    'size_t':       (_INT,   'uint64'),
    'long long':    (_INT,   'int64'),
    'unsigned long long': (_INT, 'uint64'),
    'bool':         (_BOOL,  'bool'),
    'float':        (_FLOAT, 'float'),
    'double':       (_FLOAT, 'double'),
    'char':         (_STR,   'char'),
    'wchar_t':      (_STR,   'wchar'),
    'string':       (_STR,   'string'),
    'std::string':  (_STR,   'string'),
    'char*':        (_PCHAR, 'const char*'),
    'const char*':  (_PCHAR, 'const char*'),
    'const wchar_t*': (_PCHAR,'const wchar_t*'),
    'void*':        (_PTR,   'void*'),
    'sdl_surface*': (_SDL,   'SDL_Surface*'),
    'sdl_surface**':(_SDL,   'SDL_Surface**'),
    'lua_state*':   (_LUA,   'lua_State*'),
    'sdl_color':    (_SDL,   'SDL_Color'),
    'sdl_rect':     (_SDL,   'SDL_Rect'),
    'sdl_timerid':  (_SDL,   'SDL_TimerID'),
    'tposition':    (_SDL,   'TPosition'),
    'void':         (_VOID,  'void'),
}

def _norm_type_str(s: str) -> str:
    """把类型字符串化简为可查表的小写规范形式（去 const/&/空格）."""
    s = s.strip()
    # remove const, volatile, &
    s = re.sub(r'\bconst\b', '', s)
    s = re.sub(r'\bvolatile\b', '', s)
    s = re.sub(r'&', '', s)
    s = re.sub(r'\s+', ' ', s).strip().lower()
    return s


def classify_type(raw: str, is_array: bool = False, is_var: bool = False,
                  source: str = 'pas') -> Tuple[str, str]:
    """
    返回 (族标签, 可读名).
    source: 'pas' or 'cpp'
    """
    if is_array:
        inner_cls, inner_name = classify_type(raw, False, False, source)
        return (_VEC, f'vector<{inner_name}>')

    norm = _norm_type_str(raw)

    lookup = PAS_TYPE if source == 'pas' else CPP_TYPE

    # 直接查
    if norm in lookup:
        return lookup[norm]

    # vector<T>
    vm = re.match(r'(?:std::)?vector<(.+)>', norm)
    if vm:
        inner_cls, inner_name = classify_type(vm.group(1), False, False, source)
        return (_VEC, f'vector<{inner_name}>')

    # T* or T[]  → pointer of some kind
    if norm.endswith('*') or norm.endswith('[]'):
        base = norm.rstrip('*[]').strip()
        base_cls, base_name = classify_type(base, False, False, source)
        return (_PTR, f'{base_name}*')

    return ('?', norm)


def types_compatible(fam1: str, fam2: str) -> bool:
    if fam1 == fam2:
        return True
    # INT family is loose
    if fam1 in (_INT, _BOOL) and fam2 in (_INT, _BOOL):
        return True
    # STR / PCHAR loose
    if fam1 in (_STR, _PCHAR) and fam2 in (_STR, _PCHAR):
        return True
    # VEC ↔ INT ok if array param (the param was `array of integer`)
    # handled at caller
    return False


# ──────────────────────────────────────────────────────────────────────────────
# 数据结构
# ──────────────────────────────────────────────────────────────────────────────

@dataclass
class Param:
    name: str        = ''
    raw_type: str    = ''    # original text
    fam: str         = '?'  # type family
    readable: str    = ''   # readable name for display
    is_var: bool     = False  # var/out → &
    is_const: bool   = False  # const
    is_array: bool   = False  # array of T → vector<T>
    has_default: bool= False


@dataclass
class FuncSig:
    name: str
    params: List[Param]  = field(default_factory=list)
    ret_fam: str         = _VOID
    ret_readable: str    = 'void'
    is_cdecl: bool       = False  # Lua binding
    raw: str             = ''
    source_file: str     = ''

    def param_count(self) -> int:
        return len(self.params)

    def required_count(self) -> int:
        return sum(1 for p in self.params if not p.has_default)

    def signature_str(self) -> str:
        parts = []
        for p in self.params:
            t = p.raw_type
            if p.is_array: t = f'array of {t}'
            if p.is_var:   t = f'var {t}'
            if p.has_default: t += '=?'
            parts.append(f'{p.name}:{t}' if p.name else t)
        return f'{self.ret_readable} {self.name}({", ".join(parts)})'


# ──────────────────────────────────────────────────────────────────────────────
# Pascal 解析
# ──────────────────────────────────────────────────────────────────────────────

def _strip_pas_comments(text: str) -> str:
    text = re.sub(r'\(\*.*?\*\)', ' ', text, flags=re.DOTALL)
    text = re.sub(r'\{[^}]*\}',   ' ', text, flags=re.DOTALL)
    text = re.sub(r'//[^\n]*',    ' ', text)
    return text


def _extract_interface(text: str) -> str:
    m = re.search(r'\binterface\b(.*?)\bimplementation\b', text,
                  re.DOTALL | re.IGNORECASE)
    return m.group(1) if m else text


def _split_semi(s: str) -> List[str]:
    """Split by ';' respecting parentheses depth."""
    parts, cur, depth = [], [], 0
    for c in s:
        if c == '(':   depth += 1; cur.append(c)
        elif c == ')': depth -= 1; cur.append(c)
        elif c == ';' and depth == 0:
            parts.append(''.join(cur).strip())
            cur = []
        else:
            cur.append(c)
    if cur:
        parts.append(''.join(cur).strip())
    return [p for p in parts if p]


def _parse_pas_params(s: str) -> List[Param]:
    params = []
    if not s.strip():
        return params

    for group in _split_semi(s):
        group = group.strip()
        if not group:
            continue

        is_var   = False
        is_const = False
        has_def  = False

        # default value
        m = re.search(r'\s*=\s*.+$', group)
        if m:
            group = group[:m.start()].strip()
            has_def = True

        # modifiers: var / const / constref / out
        mm = re.match(r'^(var|constref|const|out)\b\s*', group, re.IGNORECASE)
        if mm:
            mod = mm.group(1).lower()
            is_var   = mod in ('var', 'out')
            is_const = mod in ('const', 'constref')
            group = group[mm.end():]

        # name(s) : type
        colon = group.rfind(':')
        if colon < 0:
            continue

        names_str = group[:colon].strip()
        type_str  = group[colon+1:].strip()

        # array of T
        is_array = False
        arr_m = re.match(r'array\s+of\s+(.+)', type_str, re.IGNORECASE)
        if arr_m:
            is_array = True
            type_str = arr_m.group(1).strip()

        fam, readable = classify_type(type_str, is_array, is_var, 'pas')

        for name in [n.strip() for n in names_str.split(',')]:
            if name:
                params.append(Param(
                    name=name,
                    raw_type=type_str,
                    fam=fam, readable=readable,
                    is_var=is_var, is_const=is_const,
                    is_array=is_array, has_default=has_def,
                ))
    return params


def parse_pas_file(path: str) -> Dict[str, List[FuncSig]]:
    """返回 {函数名: [FuncSig, ...]} — 允许同名 overload."""
    try:
        with open(path, 'r', encoding='utf-8', errors='replace') as f:
            text = f.read()
    except Exception as e:
        print(f'  [ERROR] cannot read {path}: {e}')
        return {}

    text  = _strip_pas_comments(text)
    iface = _extract_interface(text)
    flat  = re.sub(r'\s+', ' ', iface)   # collapse whitespace for regex

    result: Dict[str, List[FuncSig]] = defaultdict(list)
    fname = os.path.basename(path)

    # Match:  (procedure|function) Name [(params)] [: RetType] [; qualifier]* ;
    # Qualifiers: overload cdecl stdcall inline virtual forward deprecated external ...
    QUAL = r'(?:\s*;\s*(?:overload|cdecl|stdcall|safecall|inline|virtual|abstract|forward|deprecated(?:\s+[^;]+)?|platform|external(?:\s+[^;]+)?))*'
    pat = re.compile(
        r'\b(procedure|function)\s+'
        r'([A-Za-z_][A-Za-z0-9_]*)'                              # name
        r'(?:\s*\(([^()]*(?:\([^()]*\)[^()]*)*)\))?'            # optional (params) 1-level nested
        r'(?:\s*:\s*([A-Za-z_][A-Za-z0-9_\s.<>*\[\]]*?))?'     # optional : RetType
        + QUAL +
        r'\s*;',
        re.IGNORECASE
    )

    for m in pat.finditer(flat):
        kw        = m.group(1).lower()
        name      = m.group(2)
        params_s  = m.group(3) or ''
        ret_raw   = (m.group(4) or '').strip()
        raw       = m.group(0)
        is_cdecl  = bool(re.search(r'\bcdecl\b', raw, re.IGNORECASE))

        if kw == 'function':
            ret_fam, ret_readable = classify_type(ret_raw, False, False, 'pas') if ret_raw else (_INT, 'int')
        else:
            ret_fam, ret_readable = _VOID, 'void'

        sig = FuncSig(
            name=name,
            params=_parse_pas_params(params_s),
            ret_fam=ret_fam, ret_readable=ret_readable,
            is_cdecl=is_cdecl,
            raw=raw[:120],
            source_file=fname,
        )
        result[name].append(sig)

    return dict(result)


# ──────────────────────────────────────────────────────────────────────────────
# C++ 解析
# ──────────────────────────────────────────────────────────────────────────────

def _strip_cpp_comments(text: str) -> str:
    text = re.sub(r'/\*.*?\*/', ' ', text, flags=re.DOTALL)
    text = re.sub(r'//[^\n]*',  '',  text)
    return text


def _split_comma(s: str) -> List[str]:
    """Split by ',' respecting <> and ()."""
    parts, cur = [], []
    dp = da = 0
    for c in s:
        if c == '(':   dp += 1; cur.append(c)
        elif c == ')': dp -= 1; cur.append(c)
        elif c == '<': da += 1; cur.append(c)
        elif c == '>': da -= 1; cur.append(c)
        elif c == ',' and dp == 0 and da == 0:
            parts.append(''.join(cur).strip())
            cur = []
        else:
            cur.append(c)
    if cur:
        parts.append(''.join(cur).strip())
    return [p for p in parts if p]


def _find_eq(s: str) -> int:
    """Find '=' for default value, skip inside <> ()."""
    dp = da = 0
    for i, c in enumerate(s):
        if c == '(':   dp += 1
        elif c == ')': dp -= 1
        elif c == '<': da += 1
        elif c == '>': da -= 1
        elif c == '=' and dp == 0 and da == 0:
            return i
    return -1


def _parse_cpp_param(s: str) -> Param:
    s = s.strip()
    has_def = False
    eq = _find_eq(s)
    if eq >= 0:
        s = s[:eq].strip()
        has_def = True

    is_var = '&' in s and 'const' not in s.lower()

    # Find last identifier as name; everything before is type
    m = re.search(r'\b([A-Za-z_][A-Za-z0-9_]*)\s*$', s)
    if m:
        candidate_name = m.group(1)
        type_before = s[:m.start()].strip()
        # If type_before has some type content, treat candidate as name
        if type_before and re.search(r'[A-Za-z_*&>]', type_before):
            name     = candidate_name
            type_str = type_before
        else:
            name     = ''
            type_str = s
    else:
        name     = ''
        type_str = s

    # Clean type: strip trailing * & from the norm lookup input
    raw_type = type_str.strip()
    fam, readable = classify_type(raw_type, False, is_var, 'cpp')

    # vector<T>  (already handled in classify_type)
    return Param(name=name, raw_type=raw_type, fam=fam, readable=readable,
                 is_var=is_var, has_default=has_def)


# Keywords that can appear as "return type" in macros/non-functions
_SKIP_NAMES = {
    'if','while','for','switch','do','return','struct','class','union','enum',
    'namespace','template','typedef','using','sizeof','alignof','static_assert',
    'decltype','operator',
}
_SKIP_RET_STARTS = (
    'typedef','using','#','struct','class','union','enum','namespace','template',
    'static_assert',
)

def parse_cpp_file(path: str) -> Dict[str, List[FuncSig]]:
    """返回 {函数名: [FuncSig, ...]}."""
    try:
        with open(path, 'r', encoding='utf-8-sig', errors='replace') as f:
            text = f.read()
    except Exception as e:
        print(f'  [ERROR] cannot read {path}: {e}')
        return {}

    text = _strip_cpp_comments(text)
    text = re.sub(r'\s+', ' ', text)

    result: Dict[str, List[FuncSig]] = defaultdict(list)
    fname = os.path.basename(path)

    # Match forward declarations: ret_type name(params) [const] ;
    # Must end with ';' (not '{' → definition)
    pat = re.compile(
        r'(?:(?:inline|static|extern(?:\s+"C")?|virtual|explicit|constexpr|__cdecl|__stdcall)\s+)*'
        r'((?:const\s+)?(?:unsigned\s+)?(?:std::)?[A-Za-z_][A-Za-z0-9_:<>* ,]*?)'  # return type
        r'\s+([A-Za-z_][A-Za-z0-9_]*)'                # function name
        r'\s*\(([^)]*(?:\([^)]*\)[^)]*)*)\)'          # ( params )
        r'(?:\s*const)?'
        r'\s*;',
        re.DOTALL,
    )

    for m in pat.finditer(text):
        ret_raw  = m.group(1).strip()
        name     = m.group(2).strip()
        params_s = m.group(3).strip()
        raw      = m.group(0)

        if name in _SKIP_NAMES:
            continue
        if any(ret_raw.lower().startswith(s) for s in _SKIP_RET_STARTS):
            continue
        # skip ALL_CAPS_WITH_UNDERSCORE (macros)
        if re.fullmatch(r'[A-Z][A-Z0-9_]+', name):
            continue

        ret_fam, ret_readable = classify_type(ret_raw, False, False, 'cpp')

        params: List[Param] = []
        if params_s and params_s.lower() != 'void':
            for part in _split_comma(params_s):
                params.append(_parse_cpp_param(part))

        sig = FuncSig(
            name=name,
            params=params,
            ret_fam=ret_fam, ret_readable=ret_readable,
            raw=raw[:120],
            source_file=fname,
        )
        result[name].append(sig)

    return dict(result)


# ──────────────────────────────────────────────────────────────────────────────
# 比对逻辑
# ──────────────────────────────────────────────────────────────────────────────

class Colors:
    RED    = '\033[91m'
    YELLOW = '\033[93m'
    GREEN  = '\033[92m'
    CYAN   = '\033[96m'
    RESET  = '\033[0m'
    BOLD   = '\033[1m'

def _color(s: str, c: str) -> str:
    try:
        if sys.stdout.isatty():
            return c + s + Colors.RESET
    except Exception:
        pass
    return s


def _best_cpp_match(p_sig: FuncSig, c_list: List[FuncSig]) -> FuncSig:
    """从 C++ overload 列表中选出参数数量最接近的一个."""
    return min(c_list, key=lambda c: abs(c.param_count() - p_sig.param_count()))


def compare_pair(pas_sigs: Dict[str, List[FuncSig]],
                 cpp_sigs: Dict[str, List[FuncSig]],
                 lua_prefix: str = 'Lua_') -> List[str]:
    """
    返回问题描述列表. pas_sigs / cpp_sigs 均为 {name: [FuncSig...]}.

    Lua 绑定约定: Pascal 里 `function Blank(L: Plua_state): integer; cdecl`
                  → C++ 里 `int Lua_Blank(lua_State* L)`
    因此检查时把 Pascal cdecl 函数对应到 C++ 的 lua_prefix+name.
    """
    issues: List[str] = []

    pas_names  = set(pas_sigs.keys())
    cpp_names  = set(cpp_sigs.keys())

    # ── Lua binding functions: separate them out ────────────────────────────
    pas_lua   = {n: v for n, v in pas_sigs.items() if all(s.is_cdecl for s in v)}
    pas_normal = {n: v for n, v in pas_sigs.items() if not all(s.is_cdecl for s in v)}

    # Build expected C++ Lua name → Pascal name mapping
    lua_name_map: Dict[str, str] = {}   # cpp_name → pas_name
    for pas_name in pas_lua:
        expected_cpp = lua_prefix + pas_name
        lua_name_map[expected_cpp] = pas_name

    # C++ Lua functions
    cpp_lua_names   = {n for n in cpp_names if n.startswith(lua_prefix)}
    cpp_normal_names = cpp_names - cpp_lua_names

    # ── 1. Pascal Lua functions missing from C++ ────────────────────────────
    for pas_name, sigs in sorted(pas_lua.items()):
        expected = lua_prefix + pas_name
        if expected not in cpp_lua_names:
            issues.append(
                _color(f'[MISSING LUA]    ', Colors.RED) +
                f'Pascal: {pas_name}(L) → expected C++: {expected}'
            )

    # ── 2. C++ Lua functions not in Pascal ──────────────────────────────────
    for cpp_name in sorted(cpp_lua_names):
        pas_name = cpp_name[len(lua_prefix):]
        if pas_name not in pas_lua:
            issues.append(
                _color(f'[EXTRA LUA]      ', Colors.CYAN) +
                f'C++ has {cpp_name} but Pascal has no {pas_name}(cdecl)'
            )

    # ── 3. Normal functions missing from C++ ───────────────────────────────
    for name in sorted(set(pas_normal.keys()) - cpp_normal_names):
        for sig in pas_normal[name]:
            issues.append(
                _color('[MISSING IN C++] ', Colors.RED) +
                sig.signature_str()
            )

    # ── 4. C++ normal functions not in Pascal ──────────────────────────────
    for name in sorted(cpp_normal_names - set(pas_normal.keys())):
        for sig in cpp_sigs[name]:
            issues.append(
                _color('[EXTRA IN C++]   ', Colors.CYAN) +
                sig.signature_str()
            )

    # ── 5. Matching names: compare overloads ───────────────────────────────
    for name in sorted(set(pas_normal.keys()) & cpp_normal_names):
        p_list = pas_normal[name]
        c_list = cpp_sigs[name]

        if len(p_list) != len(c_list):
            issues.append(
                _color('[OVERLOAD COUNT] ', Colors.YELLOW) +
                f'{name}: Pascal has {len(p_list)} overload(s), C++ has {len(c_list)}'
            )

        for p_sig in p_list:
            best = _best_cpp_match(p_sig, c_list)

            pc = p_sig.param_count()
            cc = best.param_count()

            if pc != cc:
                # Allow C++ to have more params when Pascal has default params
                req_p = p_sig.required_count()
                req_c = best.required_count()
                # heuristic: if ranges overlap, might be OK
                c_min = best.required_count()
                c_max = best.param_count()
                p_min = p_sig.required_count()
                p_max = p_sig.param_count()
                if not (max(c_min, p_min) <= min(c_max, p_max)):
                    issues.append(
                        _color('[PARAM COUNT]    ', Colors.YELLOW) +
                        f'{name}: Pascal {pc} param(s), C++ best match {cc} param(s)\n'
                        f'    Pascal: {p_sig.raw[:90]}\n'
                        f'    C++:    {best.raw[:90]}'
                    )
            else:
                # Same param count → check types
                bad_types = []
                for i, (pp, cp) in enumerate(zip(p_sig.params, best.params)):
                    pf = pp.fam if not pp.is_array else _VEC
                    cf = cp.fam

                    if types_compatible(pf, cf):
                        continue
                    # VEC (array of T) ↔ VEC ok
                    if pf == _VEC and cf == _VEC:
                        continue
                    # VEC ↔ PTR (const T[]) often intentional
                    if pf == _VEC and cf == _PTR:
                        continue
                    bad_types.append(
                        f'    param[{i}] {pp.name or "?"}: '
                        f'Pascal {pp.readable}({pp.raw_type}) ≠ '
                        f'C++ {cp.readable}({cp.raw_type})'
                    )
                if bad_types:
                    issues.append(
                        _color('[TYPE MISMATCH]  ', Colors.YELLOW) +
                        f'{name}:'
                    )
                    issues.extend(bad_types)

    return issues


# ──────────────────────────────────────────────────────────────────────────────
# 项目检查入口
# ──────────────────────────────────────────────────────────────────────────────

UNIT_PAIRS = [
    ('kys_type',   'kys_type'),
    ('kys_engine', 'kys_engine'),
    ('kys_event',  'kys_event'),
    ('kys_main',   'kys_main'),
    ('kys_battle', 'kys_battle'),
    ('kys_script', 'kys_script'),
    ('kys_draw',   'kys_draw'),
]


def check_project(pas_dir: str, cpp_dir: str, project_name: str):
    sep = '─' * 60
    print(f'\n{"═"*60}')
    print(f'项目: {_color(project_name, Colors.BOLD)}')
    print(f'  Pascal: {pas_dir}')
    print(f'  C++:    {cpp_dir}')
    print(f'{"═"*60}')

    total_issues = 0
    unit_stats: List[Tuple[str, int]] = []

    for pas_base, cpp_base in UNIT_PAIRS:
        pas_path = os.path.join(pas_dir, f'{pas_base}.pas')
        cpp_path = os.path.join(cpp_dir, f'{cpp_base}.h')

        if not os.path.exists(pas_path):
            print(f'\n{sep}')
            print(f'[SKIP] {pas_base}.pas 不存在')
            continue
        if not os.path.exists(cpp_path):
            print(f'\n{sep}')
            print(f'[SKIP] {cpp_base}.h 不存在')
            continue

        print(f'\n{sep}')
        print(f'{_color(pas_base, Colors.BOLD)}.pas  ↔  {cpp_base}.h')

        pas_sigs = parse_pas_file(pas_path)
        cpp_sigs = parse_cpp_file(cpp_path)

        # Count distinct function names
        pas_count = sum(len(v) for v in pas_sigs.values())
        cpp_count = sum(len(v) for v in cpp_sigs.values())
        print(f'  Pascal: {pas_count} 条  |  C++: {cpp_count} 条')

        issues = compare_pair(pas_sigs, cpp_sigs)

        if not issues:
            print(_color('  ✓ 无问题', Colors.GREEN))
        else:
            for issue in issues:
                # indent multi-line issues
                lines = issue.split('\n')
                print(f'  {lines[0]}')
                for l in lines[1:]:
                    print(f'  {l}')
            total_issues += len(issues)

        unit_stats.append((pas_base, len(issues)))

    print(f'\n{"─"*60}')
    print(f'汇总 — {project_name}:')
    for unit, cnt in unit_stats:
        mark = _color('✓', Colors.GREEN) if cnt == 0 else _color(f'{cnt} 问题', Colors.YELLOW)
        print(f'  {unit:<14} {mark}')
    print(f'  {"合计":<14} {_color(str(total_issues) + " 个问题", Colors.RED if total_issues else Colors.GREEN)}')


# ──────────────────────────────────────────────────────────────────────────────
# main
# ──────────────────────────────────────────────────────────────────────────────

def main():
    ap = argparse.ArgumentParser(
        description='Pascal interface ↔ C++ header 签名比对检查工具'
    )
    ap.add_argument('--kys-pascal', metavar='DIR',
                    default=r'D:\kys-all\_pascal\pascal\kys-pascal',
                    help='kys-pascal 项目根目录')
    ap.add_argument('--pig3', metavar='DIR',
                    help='pig3 项目根目录 (可选)')
    ap.add_argument('--pas', metavar='FILE',
                    help='直接指定单个 .pas 文件')
    ap.add_argument('--cpp', metavar='FILE',
                    help='直接指定单个 .h 文件（与 --pas 配对）')

    args = ap.parse_args()

    if args.pas and args.cpp:
        pas_sigs = parse_pas_file(args.pas)
        cpp_sigs = parse_cpp_file(args.cpp)
        issues = compare_pair(pas_sigs, cpp_sigs)
        for issue in issues:
            lines = issue.split('\n')
            print(lines[0])
            for l in lines[1:]:
                print(l)
        print(f'\n共 {len(issues)} 个问题')
        return

    projects_checked = 0

    if args.kys_pascal and os.path.isdir(args.kys_pascal):
        check_project(
            os.path.join(args.kys_pascal, 'bin-pas'),
            os.path.join(args.kys_pascal, 'bin-c'),
            'kys-pascal',
        )
        projects_checked += 1

    if args.pig3:
        pig3_root = args.pig3
        if not os.path.isdir(pig3_root):
            print(f'[ERROR] pig3 目录不存在: {pig3_root}')
        else:
            check_project(
                os.path.join(pig3_root, 'bin-pas'),
                os.path.join(pig3_root, 'bin-c'),
                'pig3',
            )
            projects_checked += 1

    if projects_checked == 0:
        ap.print_help()


if __name__ == '__main__':
    main()
