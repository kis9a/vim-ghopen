scriptencoding utf-8

let s:save_cpo = &cpoptions
set cpoptions&vim

" ============================================================
" Internal helper
" ============================================================

" Run a git command, optionally with -C root
function! s:git_run(root, args) abort
  let l:argv = empty(a:root) ? ['git'] + a:args : ['git', '-C', a:root] + a:args
  return ghopen#deps#cmd#run(l:argv, {})
endfunction

" ============================================================
" Buffer helpers
" ============================================================

" Get current buffer's absolute path
" Override with g:ghopen_buffer_path for testing
function! ghopen#core#buffer_path() abort
  if exists('g:ghopen_buffer_path')
    return g:ghopen_buffer_path
  endif
  return expand('%:p')
endfunction

" ============================================================
" Git helpers (all call through deps layer)
" ============================================================

" Get git repo root directory
" Uses buffer directory for -C when available
" Returns: string (path) or empty string on failure
function! ghopen#core#repo_root() abort
  let l:bufpath = ghopen#core#buffer_path()
  let l:dir = empty(l:bufpath) ? '' : fnamemodify(l:bufpath, ':h')
  let l:result = s:git_run(l:dir, ['rev-parse', '--show-toplevel'])
  if !l:result.ok || empty(l:result.stdout)
    return ''
  endif
  return l:result.stdout[0]
endfunction

" Get tracked file path relative to repo root
" abs_path: absolute path of the file
" Optional second argument: repo root (avoids redundant repo_root() call)
" Returns: string (relative path) or empty string if not tracked
function! ghopen#core#tracked_path(abs_path, ...) abort
  let l:root = a:0 > 0 ? a:1 : ghopen#core#repo_root()
  if empty(l:root)
    return ''
  endif

  " Compute relative path from repo root
  " Normalize path separators for Windows
  let l:rootp = substitute(fnamemodify(l:root, ':p'), '\\', '/', 'g')
  if l:rootp !~# '/$'
    let l:rootp .= '/'
  endif
  let l:absp = substitute(fnamemodify(a:abs_path, ':p'), '\\', '/', 'g')
  " On Windows, normalize drive letter case for prefix comparison
  if (has('win32') || has('win64'))
    let l:rootp = substitute(l:rootp, '^[A-Z]:', '\=tolower(submatch(0))', '')
    let l:absp  = substitute(l:absp, '^[A-Z]:', '\=tolower(submatch(0))', '')
  endif
  if l:absp[:len(l:rootp)-1] !=# l:rootp
    return ''
  endif
  let l:rel = l:absp[len(l:rootp):]

  let l:result = s:git_run(l:root, ['ls-files', '--full-name', '--', l:rel])
  if !l:result.ok || empty(l:result.stdout)
    return ''
  endif
  return l:result.stdout[0]
endfunction

" Get remote URL for the given remote name
" Optional second argument: repo root for -C
" Returns: string or empty
function! ghopen#core#remote_url(remote, ...) abort
  let l:root = a:0 > 0 ? a:1 : ''
  let l:result = s:git_run(l:root, ['remote', 'get-url', a:remote])
  if !l:result.ok || empty(l:result.stdout)
    return ''
  endif
  return l:result.stdout[0]
endfunction

" Get current branch name or empty if detached HEAD
" Optional argument: repo root for -C
function! ghopen#core#current_branch(...) abort
  let l:root = a:0 > 0 ? a:1 : ''
  let l:result = s:git_run(l:root, ['symbolic-ref', '--short', '-q', 'HEAD'])
  if !l:result.ok || empty(l:result.stdout)
    return ''
  endif
  return l:result.stdout[0]
endfunction

" Get HEAD commit SHA
" Optional argument: repo root for -C
function! ghopen#core#head_sha(...) abort
  let l:root = a:0 > 0 ? a:1 : ''
  let l:result = s:git_run(l:root, ['rev-parse', 'HEAD'])
  if !l:result.ok || empty(l:result.stdout)
    return ''
  endif
  return l:result.stdout[0]
endfunction

" ============================================================
" Remote URL normalization (GitHub-specific)
" ============================================================

" Normalize a git remote URL to GitHub HTTPS format
" Input examples:
"   https://github.com/owner/repo.git
"   git@github.com:owner/repo.git
"   ssh://git@github.com/owner/repo.git
" Returns: 'https://host/owner/repo' or empty string on failure
function! ghopen#core#normalize_remote(raw_url) abort
  let l:url = substitute(a:raw_url, '\n\+$', '', '')
  " Remove trailing .git
  let l:url = substitute(l:url, '\.git$', '', '')

  " Pattern 1: HTTPS - https://host/owner/repo
  let l:m = matchlist(l:url, '^https\?://\([^/]\+\)/\([^/]\+\)/\([^/]\+\)$')
  if !empty(l:m)
    return 'https://' . l:m[1] . '/' . l:m[2] . '/' . l:m[3]
  endif

  " Pattern 2: SSH scp-style - git@host:owner/repo
  let l:m = matchlist(l:url, '^[^@]\+@\([^:]\+\):\([^/]\+\)/\([^/]\+\)$')
  if !empty(l:m)
    return 'https://' . l:m[1] . '/' . l:m[2] . '/' . l:m[3]
  endif

  " Pattern 3: SSH URL with user - ssh://git@host[:port]/owner/repo
  let l:m = matchlist(l:url, '^ssh://[^@]\+@\([^:/]\+\)\%(:[0-9]\+\)\?/\([^/]\+\)/\([^/]\+\)$')
  if !empty(l:m)
    return 'https://' . l:m[1] . '/' . l:m[2] . '/' . l:m[3]
  endif

  " Pattern 4: SSH URL without user - ssh://host[:port]/owner/repo
  let l:m = matchlist(l:url, '^ssh://\([^:/]\+\)\%(:[0-9]\+\)\?/\([^/]\+\)/\([^/]\+\)$')
  if !empty(l:m)
    return 'https://' . l:m[1] . '/' . l:m[2] . '/' . l:m[3]
  endif

  return ''
endfunction

" ============================================================
" Anchor generation
" ============================================================

" Build line anchor for GitHub URL
" line1, line2: 0 means no line specified
" Returns: string like '' or '#L10' or '#L10-L20'
function! ghopen#core#build_anchor(line1, line2) abort
  if a:line1 <= 0 && a:line2 <= 0
    return ''
  endif
  let l:l1 = a:line1
  let l:l2 = a:line2
  if l:l1 > l:l2
    let l:tmp = l:l1
    let l:l1 = l:l2
    let l:l2 = l:tmp
  endif
  if l:l1 <= 0
    let l:l1 = l:l2
  endif
  if l:l1 == l:l2
    return '#L' . l:l1
  endif
  return '#L' . l:l1 . '-L' . l:l2
endfunction

" ============================================================
" Ref resolution
" ============================================================

" Resolve ref for URL generation
" permalink: if 1, always use commit SHA
" Optional second argument: repo root for -C
" Returns: string (branch name or commit SHA)
function! ghopen#core#resolve_ref(permalink, ...) abort
  let l:root = a:0 > 0 ? a:1 : ''
  if a:permalink
    return ghopen#core#head_sha(l:root)
  endif
  let l:branch = ghopen#core#current_branch(l:root)
  if !empty(l:branch)
    return l:branch
  endif
  return ghopen#core#head_sha(l:root)
endfunction

" ============================================================
" Default branch resolution (for compare)
" ============================================================

" Resolve the default branch of the remote
" Optional argument: repo root for -C
" Returns: string (branch name) or empty on failure
function! ghopen#core#resolve_default_branch(...) abort
  let l:root = a:0 > 0 ? a:1 : ''
  let l:remote = get(g:, 'ghopen_remote', 'origin')

  " 1. Try symbolic-ref of remote HEAD
  let l:result = s:git_run(l:root,
        \ ['symbolic-ref', '--short', 'refs/remotes/' . l:remote . '/HEAD'])
  if l:result.ok && !empty(l:result.stdout)
    " Output is like 'origin/main' -> extract 'main'
    let l:val = l:result.stdout[0]
    let l:idx = stridx(l:val, '/')
    if l:idx >= 0
      return l:val[l:idx + 1 :]
    endif
    return l:val
  endif

  " 2. User setting
  if exists('g:ghopen_default_branch') && !empty(g:ghopen_default_branch)
    return g:ghopen_default_branch
  endif

  " 3. Try 'main'
  let l:result = s:git_run(l:root,
        \ ['show-ref', '--verify', '--quiet', 'refs/heads/main'])
  if l:result.ok
    return 'main'
  endif

  " 4. Try 'master'
  let l:result = s:git_run(l:root,
        \ ['show-ref', '--verify', '--quiet', 'refs/heads/master'])
  if l:result.ok
    return 'master'
  endif

  " 5. Try remote tracking 'main'
  let l:result = s:git_run(l:root,
        \ ['show-ref', '--verify', '--quiet', 'refs/remotes/' . l:remote . '/main'])
  if l:result.ok
    return 'main'
  endif

  " 6. Try remote tracking 'master'
  let l:result = s:git_run(l:root,
        \ ['show-ref', '--verify', '--quiet', 'refs/remotes/' . l:remote . '/master'])
  if l:result.ok
    return 'master'
  endif

  " 7. Not found
  return ''
endfunction

" ============================================================
" URL builders
" ============================================================

" Percent-encode characters in path that break GitHub URLs
function! ghopen#core#encode_path(path) abort
  let l:s = a:path
  let l:s = substitute(l:s, '%', '%25', 'g')
  let l:s = substitute(l:s, '#', '%23', 'g')
  let l:s = substitute(l:s, '?', '%3F', 'g')
  let l:s = substitute(l:s, ' ', '%20', 'g')
  return l:s
endfunction

" Build blob URL
function! ghopen#core#build_blob_url(opts) abort
  return a:opts.repo_base . '/blob/' . a:opts.ref . '/' . ghopen#core#encode_path(a:opts.path) . a:opts.anchor
endfunction

" Build blame URL
function! ghopen#core#build_blame_url(opts) abort
  return a:opts.repo_base . '/blame/' . a:opts.ref . '/' . ghopen#core#encode_path(a:opts.path) . a:opts.anchor
endfunction

" Build compare URL
function! ghopen#core#build_compare_url(opts) abort
  return a:opts.repo_base . '/compare/' . a:opts.base . '...' . a:opts.head
endfunction

" ============================================================
" High-level: gather all info and build URL
" ============================================================

" Gather repository info and build URL
" opts: dict with keys:
"   'type': 'blob' | 'blame' | 'compare'
"   'permalink': 0 or 1
"   'line1': int (0 = no line)
"   'line2': int (0 = no line)
" Returns: dict {'ok': bool, 'url': string, 'error': string}
function! ghopen#core#generate_url(opts) abort
  " Check git is available
  if !executable('git')
    return {'ok': v:false, 'url': '', 'error': 'ghopen: git is not executable'}
  endif

  let l:type = get(a:opts, 'type', 'blob')
  let l:remote = get(g:, 'ghopen_remote', 'origin')

  " Compare doesn't need file info but still needs repo context
  if l:type ==# 'compare'
    let l:root = ghopen#core#repo_root()
    if empty(l:root)
      return {'ok': v:false, 'url': '', 'error': 'ghopen: not a git repository'}
    endif

    let l:raw_url = ghopen#core#remote_url(l:remote, l:root)
    if empty(l:raw_url)
      return {'ok': v:false, 'url': '', 'error': 'ghopen: remote "' . l:remote . '" not found'}
    endif
    let l:repo_base = ghopen#core#normalize_remote(l:raw_url)
    if empty(l:repo_base)
      return {'ok': v:false, 'url': '', 'error': 'ghopen: remote URL is not GitHub or unsupported format'}
    endif

    let l:head = ghopen#core#resolve_ref(0, l:root)
    if empty(l:head)
      return {'ok': v:false, 'url': '', 'error': 'ghopen: cannot determine current ref'}
    endif
    let l:base = ghopen#core#resolve_default_branch(l:root)
    if empty(l:base)
      return {'ok': v:false, 'url': '', 'error': 'ghopen: default branch not detected; set g:ghopen_default_branch'}
    endif

    let l:url = ghopen#core#build_compare_url({
          \ 'repo_base': l:repo_base,
          \ 'base': l:base,
          \ 'head': l:head,
          \ })
    return {'ok': v:true, 'url': l:url, 'error': ''}
  endif

  " For blob/blame: need file info
  let l:abs_path = ghopen#core#buffer_path()
  if empty(l:abs_path)
    return {'ok': v:false, 'url': '', 'error': 'ghopen: no file in current buffer'}
  endif

  " Check repo
  let l:root = ghopen#core#repo_root()
  if empty(l:root)
    return {'ok': v:false, 'url': '', 'error': 'ghopen: not a git repository'}
  endif

  " Check tracked (pass root to avoid redundant repo_root() call)
  let l:path = ghopen#core#tracked_path(l:abs_path, l:root)
  if empty(l:path)
    return {'ok': v:false, 'url': '', 'error': 'ghopen: file is not tracked by git'}
  endif

  " Get remote URL
  let l:raw_url = ghopen#core#remote_url(l:remote, l:root)
  if empty(l:raw_url)
    return {'ok': v:false, 'url': '', 'error': 'ghopen: remote "' . l:remote . '" not found'}
  endif
  let l:repo_base = ghopen#core#normalize_remote(l:raw_url)
  if empty(l:repo_base)
    return {'ok': v:false, 'url': '', 'error': 'ghopen: remote URL is not GitHub or unsupported format'}
  endif

  " Resolve ref
  let l:permalink = get(a:opts, 'permalink', 0)
  let l:ref = ghopen#core#resolve_ref(l:permalink, l:root)
  if empty(l:ref)
    return {'ok': v:false, 'url': '', 'error': 'ghopen: cannot determine current ref'}
  endif

  " Build anchor
  let l:line1 = get(a:opts, 'line1', 0)
  let l:line2 = get(a:opts, 'line2', 0)
  let l:anchor = ghopen#core#build_anchor(l:line1, l:line2)

  " Build URL
  let l:url_opts = {
        \ 'repo_base': l:repo_base,
        \ 'ref': l:ref,
        \ 'path': l:path,
        \ 'anchor': l:anchor,
        \ }

  if l:type ==# 'blame'
    let l:url = ghopen#core#build_blame_url(l:url_opts)
  else
    let l:url = ghopen#core#build_blob_url(l:url_opts)
  endif

  return {'ok': v:true, 'url': l:url, 'error': ''}
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
