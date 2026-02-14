scriptencoding utf-8

let s:save_cpo = &cpoptions
set cpoptions&vim

" Public API: generate URL
" opts: {'type': 'blob'|'blame'|'compare', 'permalink': 0|1, 'line1': int, 'line2': int}
function! ghopen#url(opts) abort
  return ghopen#core#generate_url(a:opts)
endfunction

" Public API: open URL in browser
" opts.line1/line2 are passed directly to generate_url (no range heuristic)
function! ghopen#open(opts) abort
  let l:result = ghopen#core#generate_url(a:opts)
  if !l:result.ok
    call ghopen#compat#notify(l:result.error, 'error')
    return
  endif

  let l:open_result = ghopen#compat#open_browser(l:result.url)
  if !l:open_result.ok
    call ghopen#compat#notify(l:open_result.error, 'error')
    return
  endif

  if get(g:, 'ghopen_debug', 0)
    call ghopen#compat#notify('ghopen: opened ' . l:result.url, 'info')
  endif
endfunction

" Public API: copy URL to clipboard
" opts.line1/line2 are passed directly to generate_url (no range heuristic)
function! ghopen#copy(opts) abort
  let l:result = ghopen#core#generate_url(a:opts)
  if !l:result.ok
    call ghopen#compat#notify(l:result.error, 'error')
    return
  endif

  let l:copy_result = ghopen#compat#copy_to_clipboard(l:result.url)
  if !l:copy_result.ok
    call ghopen#compat#notify(l:copy_result.error, 'error')
    return
  endif

  call ghopen#compat#notify('copied: ' . l:result.url, 'info')
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
