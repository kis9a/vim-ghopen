if exists('g:loaded_ghopen')
  finish
endif
let g:loaded_ghopen = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

" Default options
if !exists('g:ghopen_remote')
  let g:ghopen_remote = 'origin'
endif

" Commands with -range support
command! -range GhOpen call ghopen#command#open(<line1>, <line2>, {'type': 'blob', 'permalink': 0})
command! -range GhOpenPermalink call ghopen#command#open(<line1>, <line2>, {'type': 'blob', 'permalink': 1})
command! -range GhCopy call ghopen#command#copy(<line1>, <line2>, {'type': 'blob', 'permalink': 0})
command! -range GhCopyPermalink call ghopen#command#copy(<line1>, <line2>, {'type': 'blob', 'permalink': 1})
command! -range GhOpenBlame call ghopen#command#open(<line1>, <line2>, {'type': 'blame', 'permalink': 0})
command! GhOpenCompare call ghopen#command#open(0, 0, {'type': 'compare'})
command! GhOpenPR call ghopen#command#open(0, 0, {'type': 'compare'})

let &cpoptions = s:save_cpo
unlet s:save_cpo
