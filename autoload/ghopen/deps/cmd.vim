scriptencoding utf-8

let s:save_cpo = &cpoptions
set cpoptions&vim

" Execute external command safely
" argv: list of strings e.g. ['git', 'rev-parse', '--show-toplevel']
" opts: dict with optional keys: 'input' (string for stdin), 'timeout_ms' (int)
" Returns: dict {'ok': bool, 'code': int, 'stdout': list, 'stderr': list}
function! ghopen#deps#cmd#run(argv, opts) abort
  if type(a:argv) != type([]) || empty(a:argv)
    return {'ok': v:false, 'code': -1, 'stdout': [], 'stderr': ['invalid argv']}
  endif
  if !executable(a:argv[0])
    return {'ok': v:false, 'code': -1, 'stdout': [], 'stderr': ['not executable: ' . a:argv[0]]}
  endif

  " Test stub injection point (accepts Funcref or string function name)
  if exists('g:ghopen_cmd_runner')
    if type(g:ghopen_cmd_runner) == type(function('tr'))
      return call(g:ghopen_cmd_runner, [a:argv, a:opts])
    elseif type(g:ghopen_cmd_runner) == type('')
      return call(function(g:ghopen_cmd_runner), [a:argv, a:opts])
    endif
  endif

  " Build shell command string from argv list (safe via shellescape)
  let l:cmd = join(map(copy(a:argv), 'shellescape(v:val)'), ' ')
  " Merge stderr into stdout so failure diagnostics are visible
  if get(a:opts, 'capture_stderr', 1)
    let l:cmd .= ' 2>&1'
  endif
  let l:input = get(a:opts, 'input', '')
  if !empty(l:input)
    let l:out = systemlist(l:cmd, l:input)
  else
    let l:out = systemlist(l:cmd)
  endif
  let l:code = v:shell_error
  return {'ok': l:code == 0, 'code': l:code, 'stdout': l:out, 'stderr': []}
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
