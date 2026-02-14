scriptencoding utf-8

let s:save_cpo = &cpoptions
set cpoptions&vim

function! ghopen#compat#has_nvim() abort
  return has('nvim')
endfunction

" Notify user with a message
" level: 'info' | 'warn' | 'error'
function! ghopen#compat#notify(msg, level) abort
  if a:level ==# 'error'
    echohl ErrorMsg | echomsg a:msg | echohl None
  elseif a:level ==# 'warn'
    echohl WarningMsg | echomsg a:msg | echohl None
  else
    echomsg a:msg
  endif
endfunction

" Open URL in browser
" Returns: dict {'ok': bool, 'error': string}
function! ghopen#compat#open_browser(url) abort
  let l:cmd = s:detect_browser_cmd()
  if empty(l:cmd)
    return {'ok': v:false, 'error': 'ghopen: no browser command available'}
  endif
  let l:argv = l:cmd + [a:url]
  let l:result = ghopen#deps#cmd#run(l:argv, {})
  if !l:result.ok
    return {'ok': v:false, 'error': 'ghopen: failed to open browser'}
  endif
  return {'ok': v:true, 'error': ''}
endfunction

" Copy text to clipboard
" Returns: dict {'ok': bool, 'error': string}
function! ghopen#compat#copy_to_clipboard(text) abort
  let l:cmd = s:detect_clipboard_cmd()
  if empty(l:cmd)
    return {'ok': v:false, 'error': 'ghopen: no clipboard command available'}
  endif
  let l:argv = l:cmd
  let l:result = ghopen#deps#cmd#run(l:argv, {'input': a:text})
  if !l:result.ok
    return {'ok': v:false, 'error': 'ghopen: failed to copy to clipboard'}
  endif
  return {'ok': v:true, 'error': ''}
endfunction

function! s:detect_browser_cmd() abort
  " User override
  if exists('g:ghopen_browser') && !empty(g:ghopen_browser)
    if type(g:ghopen_browser) == type([])
      return g:ghopen_browser
    endif
    return [g:ghopen_browser]
  endif
  " OS detection
  if has('mac') || has('macunix')
    return ['open']
  elseif executable('wslview')
    return ['wslview']
  elseif executable('xdg-open')
    return ['xdg-open']
  elseif has('win32') || has('win64')
    return ['cmd', '/c', 'start', '']
  endif
  return []
endfunction

function! s:detect_clipboard_cmd() abort
  " User override
  if exists('g:ghopen_clipboard') && !empty(g:ghopen_clipboard)
    if type(g:ghopen_clipboard) == type([])
      return g:ghopen_clipboard
    endif
    return [g:ghopen_clipboard]
  endif
  " OS detection
  if has('mac') || has('macunix')
    return ['pbcopy']
  elseif executable('wl-copy')
    return ['wl-copy']
  elseif executable('xclip')
    return ['xclip', '-selection', 'clipboard']
  elseif executable('clip.exe')
    return ['clip.exe']
  endif
  return []
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
