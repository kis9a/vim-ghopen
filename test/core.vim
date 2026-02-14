scriptencoding utf-8

let s:suite = themis#suite('core')
let s:assert = themis#helper('assert')

" ============================================================
" Stub helper for g:ghopen_cmd_runner
" ============================================================

" Global dict: key = join(argv, "\x01"), value = result dict
let g:ghopen_test_stubs = {}

" Global stub runner function (Vim requires global funcs for string-based call())
function! GhopenTestStubRunner(argv, opts) abort
  let l:_ = a:opts
  let l:key = join(a:argv, "\x01")
  if has_key(g:ghopen_test_stubs, l:key)
    return g:ghopen_test_stubs[l:key]
  endif
  return {'ok': v:false, 'code': 1, 'stdout': [], 'stderr': ['stub: no match']}
endfunction

function! s:set_stub(argv, result) abort
  let l:key = join(a:argv, "\x01")
  let g:ghopen_test_stubs[l:key] = a:result
endfunction

function! s:ok(stdout) abort
  return {'ok': v:true, 'code': 0, 'stdout': a:stdout, 'stderr': []}
endfunction

function! s:fail() abort
  return {'ok': v:false, 'code': 1, 'stdout': [], 'stderr': []}
endfunction

function! s:enable_stub() abort
  let g:ghopen_cmd_runner = 'GhopenTestStubRunner'
endfunction

function! s:suite.before_each() abort
  let g:ghopen_test_stubs = {}
  if exists('g:ghopen_cmd_runner')
    unlet g:ghopen_cmd_runner
  endif
  if exists('g:ghopen_default_branch')
    unlet g:ghopen_default_branch
  endif
  if exists('g:ghopen_buffer_path')
    unlet g:ghopen_buffer_path
  endif
  let g:ghopen_remote = 'origin'
endfunction

function! s:suite.after_each() abort
  if exists('g:ghopen_cmd_runner')
    unlet g:ghopen_cmd_runner
  endif
  if exists('g:ghopen_default_branch')
    unlet g:ghopen_default_branch
  endif
  if exists('g:ghopen_buffer_path')
    unlet g:ghopen_buffer_path
  endif
  let g:ghopen_test_stubs = {}
endfunction

" ============================================================
" Remote URL normalization
" ============================================================

function! s:suite.normalize_remote_https() abort
  call s:assert.equals(
        \ ghopen#core#normalize_remote('https://github.com/owner/repo.git'),
        \ 'https://github.com/owner/repo')
endfunction

function! s:suite.normalize_remote_https_no_git() abort
  call s:assert.equals(
        \ ghopen#core#normalize_remote('https://github.com/owner/repo'),
        \ 'https://github.com/owner/repo')
endfunction

function! s:suite.normalize_remote_ssh_scp() abort
  call s:assert.equals(
        \ ghopen#core#normalize_remote('git@github.com:owner/repo.git'),
        \ 'https://github.com/owner/repo')
endfunction

function! s:suite.normalize_remote_ssh_scp_no_git() abort
  call s:assert.equals(
        \ ghopen#core#normalize_remote('git@github.com:owner/repo'),
        \ 'https://github.com/owner/repo')
endfunction

function! s:suite.normalize_remote_ssh_url() abort
  call s:assert.equals(
        \ ghopen#core#normalize_remote('ssh://git@github.com/owner/repo.git'),
        \ 'https://github.com/owner/repo')
endfunction

function! s:suite.normalize_remote_ssh_url_no_git() abort
  call s:assert.equals(
        \ ghopen#core#normalize_remote('ssh://git@github.com/owner/repo'),
        \ 'https://github.com/owner/repo')
endfunction

function! s:suite.normalize_remote_ssh_url_no_user() abort
  call s:assert.equals(
        \ ghopen#core#normalize_remote('ssh://github.com/owner/repo.git'),
        \ 'https://github.com/owner/repo')
endfunction

function! s:suite.normalize_remote_ssh_url_no_user_no_git() abort
  call s:assert.equals(
        \ ghopen#core#normalize_remote('ssh://github.com/owner/repo'),
        \ 'https://github.com/owner/repo')
endfunction

function! s:suite.normalize_remote_invalid() abort
  call s:assert.equals(
        \ ghopen#core#normalize_remote('not-a-url'),
        \ '')
endfunction

function! s:suite.normalize_remote_empty() abort
  call s:assert.equals(
        \ ghopen#core#normalize_remote(''),
        \ '')
endfunction

function! s:suite.normalize_remote_enterprise() abort
  call s:assert.equals(
        \ ghopen#core#normalize_remote('git@github.mycorp.com:owner/repo.git'),
        \ 'https://github.mycorp.com/owner/repo')
endfunction

function! s:suite.normalize_remote_enterprise_https() abort
  call s:assert.equals(
        \ ghopen#core#normalize_remote('https://github.mycorp.com/owner/repo.git'),
        \ 'https://github.mycorp.com/owner/repo')
endfunction

function! s:suite.normalize_remote_http() abort
  call s:assert.equals(
        \ ghopen#core#normalize_remote('http://github.com/owner/repo.git'),
        \ 'https://github.com/owner/repo')
endfunction

" ============================================================
" Anchor generation
" ============================================================

function! s:suite.anchor_none() abort
  call s:assert.equals(ghopen#core#build_anchor(0, 0), '')
endfunction

function! s:suite.anchor_single_line() abort
  call s:assert.equals(ghopen#core#build_anchor(10, 10), '#L10')
endfunction

function! s:suite.anchor_range() abort
  call s:assert.equals(ghopen#core#build_anchor(10, 20), '#L10-L20')
endfunction

function! s:suite.anchor_reverse_range() abort
  call s:assert.equals(ghopen#core#build_anchor(20, 10), '#L10-L20')
endfunction

function! s:suite.anchor_line1_only() abort
  call s:assert.equals(ghopen#core#build_anchor(5, 0), '#L5')
endfunction

" ============================================================
" URL builders
" ============================================================

function! s:suite.build_blob_url() abort
  let l:url = ghopen#core#build_blob_url({
        \ 'repo_base': 'https://github.com/owner/repo',
        \ 'ref': 'main',
        \ 'path': 'src/file.vim',
        \ 'anchor': '#L10-L20',
        \ })
  call s:assert.equals(l:url, 'https://github.com/owner/repo/blob/main/src/file.vim#L10-L20')
endfunction

function! s:suite.build_blob_url_no_anchor() abort
  let l:url = ghopen#core#build_blob_url({
        \ 'repo_base': 'https://github.com/owner/repo',
        \ 'ref': 'develop',
        \ 'path': 'README.md',
        \ 'anchor': '',
        \ })
  call s:assert.equals(l:url, 'https://github.com/owner/repo/blob/develop/README.md')
endfunction

function! s:suite.build_blame_url() abort
  let l:url = ghopen#core#build_blame_url({
        \ 'repo_base': 'https://github.com/owner/repo',
        \ 'ref': 'main',
        \ 'path': 'src/file.vim',
        \ 'anchor': '#L5',
        \ })
  call s:assert.equals(l:url, 'https://github.com/owner/repo/blame/main/src/file.vim#L5')
endfunction

function! s:suite.build_compare_url() abort
  let l:url = ghopen#core#build_compare_url({
        \ 'repo_base': 'https://github.com/owner/repo',
        \ 'base': 'main',
        \ 'head': 'feature-branch',
        \ })
  call s:assert.equals(l:url, 'https://github.com/owner/repo/compare/main...feature-branch')
endfunction

function! s:suite.build_compare_url_with_sha() abort
  let l:url = ghopen#core#build_compare_url({
        \ 'repo_base': 'https://github.com/owner/repo',
        \ 'base': 'main',
        \ 'head': 'abc1234',
        \ })
  call s:assert.equals(l:url, 'https://github.com/owner/repo/compare/main...abc1234')
endfunction

" ============================================================
" resolve_default_branch (stub-based, called directly without root)
" ============================================================

function! s:suite.default_branch_from_remote_head() abort
  call s:enable_stub()
  call s:set_stub(
        \ ['git', 'symbolic-ref', '--short', 'refs/remotes/origin/HEAD'],
        \ s:ok(['origin/main']))
  call s:assert.equals(ghopen#core#resolve_default_branch(), 'main')
endfunction

function! s:suite.default_branch_from_user_setting() abort
  call s:enable_stub()
  call s:set_stub(
        \ ['git', 'symbolic-ref', '--short', 'refs/remotes/origin/HEAD'],
        \ s:fail())
  let g:ghopen_default_branch = 'develop'
  call s:assert.equals(ghopen#core#resolve_default_branch(), 'develop')
endfunction

function! s:suite.default_branch_fallback_main() abort
  call s:enable_stub()
  call s:set_stub(
        \ ['git', 'symbolic-ref', '--short', 'refs/remotes/origin/HEAD'],
        \ s:fail())
  call s:set_stub(
        \ ['git', 'show-ref', '--verify', '--quiet', 'refs/heads/main'],
        \ s:ok([]))
  call s:assert.equals(ghopen#core#resolve_default_branch(), 'main')
endfunction

function! s:suite.default_branch_fallback_master() abort
  call s:enable_stub()
  call s:set_stub(
        \ ['git', 'symbolic-ref', '--short', 'refs/remotes/origin/HEAD'],
        \ s:fail())
  call s:set_stub(
        \ ['git', 'show-ref', '--verify', '--quiet', 'refs/heads/main'],
        \ s:fail())
  call s:set_stub(
        \ ['git', 'show-ref', '--verify', '--quiet', 'refs/heads/master'],
        \ s:ok([]))
  call s:assert.equals(ghopen#core#resolve_default_branch(), 'master')
endfunction

function! s:suite.default_branch_remote_tracking_main() abort
  call s:enable_stub()
  call s:set_stub(
        \ ['git', 'symbolic-ref', '--short', 'refs/remotes/origin/HEAD'],
        \ s:fail())
  call s:set_stub(
        \ ['git', 'show-ref', '--verify', '--quiet', 'refs/heads/main'],
        \ s:fail())
  call s:set_stub(
        \ ['git', 'show-ref', '--verify', '--quiet', 'refs/heads/master'],
        \ s:fail())
  call s:set_stub(
        \ ['git', 'show-ref', '--verify', '--quiet', 'refs/remotes/origin/main'],
        \ s:ok([]))
  call s:assert.equals(ghopen#core#resolve_default_branch(), 'main')
endfunction

function! s:suite.default_branch_not_found() abort
  call s:enable_stub()
  call s:set_stub(
        \ ['git', 'symbolic-ref', '--short', 'refs/remotes/origin/HEAD'],
        \ s:fail())
  call s:set_stub(
        \ ['git', 'show-ref', '--verify', '--quiet', 'refs/heads/main'],
        \ s:fail())
  call s:set_stub(
        \ ['git', 'show-ref', '--verify', '--quiet', 'refs/heads/master'],
        \ s:fail())
  call s:set_stub(
        \ ['git', 'show-ref', '--verify', '--quiet', 'refs/remotes/origin/main'],
        \ s:fail())
  call s:set_stub(
        \ ['git', 'show-ref', '--verify', '--quiet', 'refs/remotes/origin/master'],
        \ s:fail())
  call s:assert.equals(ghopen#core#resolve_default_branch(), '')
endfunction

" ============================================================
" resolve_ref (stub-based, called directly without root)
" ============================================================

function! s:suite.resolve_ref_branch() abort
  call s:enable_stub()
  call s:set_stub(['git', 'symbolic-ref', '--short', '-q', 'HEAD'],
        \ s:ok(['main']))
  call s:assert.equals(ghopen#core#resolve_ref(0), 'main')
endfunction

function! s:suite.resolve_ref_detached() abort
  call s:enable_stub()
  call s:set_stub(['git', 'symbolic-ref', '--short', '-q', 'HEAD'], s:fail())
  call s:set_stub(['git', 'rev-parse', 'HEAD'],
        \ s:ok(['deadbeef12345678']))
  call s:assert.equals(ghopen#core#resolve_ref(0), 'deadbeef12345678')
endfunction

function! s:suite.resolve_ref_permalink() abort
  call s:enable_stub()
  call s:set_stub(['git', 'rev-parse', 'HEAD'],
        \ s:ok(['abc123def456']))
  call s:assert.equals(ghopen#core#resolve_ref(1), 'abc123def456')
endfunction

" ============================================================
" generate_url blob (full flow with buffer_path override)
" ============================================================

function! s:suite.generate_url_blob() abort
  call s:enable_stub()
  let g:ghopen_buffer_path = '/home/user/repo/src/file.vim'
  call s:set_stub(
        \ ['git', '-C', '/home/user/repo/src', 'rev-parse', '--show-toplevel'],
        \ s:ok(['/home/user/repo']))
  call s:set_stub(
        \ ['git', '-C', '/home/user/repo', 'ls-files', '--full-name', '--', 'src/file.vim'],
        \ s:ok(['src/file.vim']))
  call s:set_stub(
        \ ['git', '-C', '/home/user/repo', 'remote', 'get-url', 'origin'],
        \ s:ok(['git@github.com:owner/repo.git']))
  call s:set_stub(
        \ ['git', '-C', '/home/user/repo', 'symbolic-ref', '--short', '-q', 'HEAD'],
        \ s:ok(['feature-x']))
  let l:result = ghopen#core#generate_url({
        \ 'type': 'blob', 'permalink': 0, 'line1': 10, 'line2': 20})
  call s:assert.equals(l:result.ok, v:true)
  call s:assert.equals(l:result.url,
        \ 'https://github.com/owner/repo/blob/feature-x/src/file.vim#L10-L20')
endfunction

function! s:suite.generate_url_blame() abort
  call s:enable_stub()
  let g:ghopen_buffer_path = '/home/user/repo/lib/util.vim'
  call s:set_stub(
        \ ['git', '-C', '/home/user/repo/lib', 'rev-parse', '--show-toplevel'],
        \ s:ok(['/home/user/repo']))
  call s:set_stub(
        \ ['git', '-C', '/home/user/repo', 'ls-files', '--full-name', '--', 'lib/util.vim'],
        \ s:ok(['lib/util.vim']))
  call s:set_stub(
        \ ['git', '-C', '/home/user/repo', 'remote', 'get-url', 'origin'],
        \ s:ok(['https://github.com/owner/repo.git']))
  call s:set_stub(
        \ ['git', '-C', '/home/user/repo', 'symbolic-ref', '--short', '-q', 'HEAD'],
        \ s:ok(['main']))
  let l:result = ghopen#core#generate_url({
        \ 'type': 'blame', 'permalink': 0, 'line1': 5, 'line2': 5})
  call s:assert.equals(l:result.ok, v:true)
  call s:assert.equals(l:result.url,
        \ 'https://github.com/owner/repo/blame/main/lib/util.vim#L5')
endfunction

function! s:suite.generate_url_permalink() abort
  call s:enable_stub()
  let g:ghopen_buffer_path = '/home/user/repo/README.md'
  call s:set_stub(
        \ ['git', '-C', '/home/user/repo', 'rev-parse', '--show-toplevel'],
        \ s:ok(['/home/user/repo']))
  call s:set_stub(
        \ ['git', '-C', '/home/user/repo', 'ls-files', '--full-name', '--', 'README.md'],
        \ s:ok(['README.md']))
  call s:set_stub(
        \ ['git', '-C', '/home/user/repo', 'remote', 'get-url', 'origin'],
        \ s:ok(['git@github.com:owner/repo.git']))
  call s:set_stub(
        \ ['git', '-C', '/home/user/repo', 'rev-parse', 'HEAD'],
        \ s:ok(['abc123def456']))
  let l:result = ghopen#core#generate_url({
        \ 'type': 'blob', 'permalink': 1, 'line1': 0, 'line2': 0})
  call s:assert.equals(l:result.ok, v:true)
  call s:assert.equals(l:result.url,
        \ 'https://github.com/owner/repo/blob/abc123def456/README.md')
endfunction

function! s:suite.generate_url_no_buffer() abort
  call s:enable_stub()
  " buffer_path not set → empty → 'no file in current buffer'
  let l:result = ghopen#core#generate_url({
        \ 'type': 'blob', 'permalink': 0, 'line1': 0, 'line2': 0})
  call s:assert.equals(l:result.ok, v:false)
  call s:assert.equals(l:result.error, 'ghopen: no file in current buffer')
endfunction

" ============================================================
" generate_url compare (full flow with -C root stubs)
" ============================================================

function! s:suite.generate_url_compare() abort
  call s:enable_stub()
  " repo_root (buffer_path empty → no -C)
  call s:set_stub(
        \ ['git', 'rev-parse', '--show-toplevel'],
        \ s:ok(['/home/user/repo']))
  call s:set_stub(
        \ ['git', '-C', '/home/user/repo', 'remote', 'get-url', 'origin'],
        \ s:ok(['https://github.com/owner/repo.git']))
  call s:set_stub(
        \ ['git', '-C', '/home/user/repo', 'symbolic-ref', '--short', '-q', 'HEAD'],
        \ s:ok(['feature-branch']))
  call s:set_stub(
        \ ['git', '-C', '/home/user/repo', 'symbolic-ref', '--short', 'refs/remotes/origin/HEAD'],
        \ s:ok(['origin/main']))
  let l:result = ghopen#core#generate_url({
        \ 'type': 'compare', 'permalink': 0, 'line1': 0, 'line2': 0})
  call s:assert.equals(l:result.ok, v:true)
  call s:assert.equals(l:result.url,
        \ 'https://github.com/owner/repo/compare/main...feature-branch')
endfunction

function! s:suite.generate_url_compare_no_repo() abort
  call s:enable_stub()
  " repo_root fails
  let l:result = ghopen#core#generate_url({
        \ 'type': 'compare', 'permalink': 0, 'line1': 0, 'line2': 0})
  call s:assert.equals(l:result.ok, v:false)
  call s:assert.equals(l:result.error, 'ghopen: not a git repository')
endfunction

function! s:suite.generate_url_compare_no_remote() abort
  call s:enable_stub()
  call s:set_stub(
        \ ['git', 'rev-parse', '--show-toplevel'],
        \ s:ok(['/home/user/repo']))
  call s:set_stub(
        \ ['git', '-C', '/home/user/repo', 'remote', 'get-url', 'origin'],
        \ s:fail())
  let l:result = ghopen#core#generate_url({
        \ 'type': 'compare', 'permalink': 0, 'line1': 0, 'line2': 0})
  call s:assert.equals(l:result.ok, v:false)
  call s:assert.equals(l:result.error, 'ghopen: remote "origin" not found')
endfunction

function! s:suite.generate_url_compare_no_default_branch() abort
  call s:enable_stub()
  call s:set_stub(
        \ ['git', 'rev-parse', '--show-toplevel'],
        \ s:ok(['/home/user/repo']))
  call s:set_stub(
        \ ['git', '-C', '/home/user/repo', 'remote', 'get-url', 'origin'],
        \ s:ok(['https://github.com/owner/repo.git']))
  call s:set_stub(
        \ ['git', '-C', '/home/user/repo', 'symbolic-ref', '--short', '-q', 'HEAD'],
        \ s:ok(['my-branch']))
  " All default branch resolution fails (with -C root)
  call s:set_stub(
        \ ['git', '-C', '/home/user/repo', 'symbolic-ref', '--short', 'refs/remotes/origin/HEAD'],
        \ s:fail())
  call s:set_stub(
        \ ['git', '-C', '/home/user/repo', 'show-ref', '--verify', '--quiet', 'refs/heads/main'],
        \ s:fail())
  call s:set_stub(
        \ ['git', '-C', '/home/user/repo', 'show-ref', '--verify', '--quiet', 'refs/heads/master'],
        \ s:fail())
  call s:set_stub(
        \ ['git', '-C', '/home/user/repo', 'show-ref', '--verify', '--quiet', 'refs/remotes/origin/main'],
        \ s:fail())
  call s:set_stub(
        \ ['git', '-C', '/home/user/repo', 'show-ref', '--verify', '--quiet', 'refs/remotes/origin/master'],
        \ s:fail())
  let l:result = ghopen#core#generate_url({
        \ 'type': 'compare', 'permalink': 0, 'line1': 0, 'line2': 0})
  call s:assert.equals(l:result.ok, v:false)
  call s:assert.equals(l:result.error,
        \ 'ghopen: default branch not detected; set g:ghopen_default_branch')
endfunction

" ============================================================
" SSH URL with port
" ============================================================

function! s:suite.normalize_remote_ssh_url_with_port() abort
  call s:assert.equals(
        \ ghopen#core#normalize_remote('ssh://git@github.com:22/owner/repo.git'),
        \ 'https://github.com/owner/repo')
endfunction

function! s:suite.normalize_remote_ssh_url_no_user_with_port() abort
  call s:assert.equals(
        \ ghopen#core#normalize_remote('ssh://github.com:443/owner/repo'),
        \ 'https://github.com/owner/repo')
endfunction

" ============================================================
" URL path encoding
" ============================================================

function! s:suite.encode_path_special_chars() abort
  call s:assert.equals(
        \ ghopen#core#encode_path('dir/file with spaces.vim'),
        \ 'dir/file%20with%20spaces.vim')
  call s:assert.equals(
        \ ghopen#core#encode_path('dir/file#name.vim'),
        \ 'dir/file%23name.vim')
  call s:assert.equals(
        \ ghopen#core#encode_path('dir/file?query.vim'),
        \ 'dir/file%3Fquery.vim')
  call s:assert.equals(
        \ ghopen#core#encode_path('dir/100%.vim'),
        \ 'dir/100%25.vim')
endfunction

function! s:suite.encode_path_noop() abort
  call s:assert.equals(
        \ ghopen#core#encode_path('src/file.vim'),
        \ 'src/file.vim')
endfunction

function! s:suite.build_blob_url_encoded_path() abort
  let l:url = ghopen#core#build_blob_url({
        \ 'repo_base': 'https://github.com/owner/repo',
        \ 'ref': 'main',
        \ 'path': 'docs/my file#1.md',
        \ 'anchor': '',
        \ })
  call s:assert.equals(l:url,
        \ 'https://github.com/owner/repo/blob/main/docs/my%20file%231.md')
endfunction

function! s:suite.build_blame_url_encoded_path() abort
  let l:url = ghopen#core#build_blame_url({
        \ 'repo_base': 'https://github.com/owner/repo',
        \ 'ref': 'main',
        \ 'path': 'src/test file.vim',
        \ 'anchor': '#L5',
        \ })
  call s:assert.equals(l:url,
        \ 'https://github.com/owner/repo/blame/main/src/test%20file.vim#L5')
endfunction
