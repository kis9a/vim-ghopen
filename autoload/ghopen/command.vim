scriptencoding utf-8

let s:save_cpo = &cpoptions
set cpoptions&vim

" Open URL in browser
" line1, line2: from -range command
" opts: dict with 'type', 'permalink' etc
function! ghopen#command#open(line1, line2, opts) abort
  let l:url_opts = s:build_url_opts(a:line1, a:line2, a:opts)
  let l:result = ghopen#core#generate_url(l:url_opts)
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

" Copy URL to clipboard
function! ghopen#command#copy(line1, line2, opts) abort
  let l:url_opts = s:build_url_opts(a:line1, a:line2, a:opts)
  let l:result = ghopen#core#generate_url(l:url_opts)
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

" Build URL opts from command arguments
" When no explicit range is given, Vim sets line1=line2=current line.
" We detect this to avoid attaching anchors for bare :GhOpen calls.
function! s:build_url_opts(line1, line2, opts) abort
  let l:url_opts = copy(a:opts)
  if a:line1 == a:line2 && a:line1 == line('.')
    let l:url_opts.line1 = 0
    let l:url_opts.line2 = 0
  else
    let l:url_opts.line1 = a:line1
    let l:url_opts.line2 = a:line2
  endif
  return l:url_opts
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
