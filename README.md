# vim-ghopen

Open GitHub URLs from Vim/Neovim. Generate blob, permalink, blame, and compare URLs with one keystroke.

## Installation

Using [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'kis9a/vim-ghopen'
```

Using [dein.vim](https://github.com/Shougo/dein.vim):

```vim
call dein#add('kis9a/vim-ghopen')
```

## Features

### Commands

| Command | Range | Description |
|---------|-------|-------------|
| `:GhOpen` | Yes | Open file on GitHub |
| `:GhOpenPermalink` | Yes | Open file with permalink (commit SHA) |
| `:GhCopy` | Yes | Copy GitHub URL to clipboard |
| `:GhCopyPermalink` | Yes | Copy permalink to clipboard |
| `:GhOpenBlame` | Yes | Open blame view on GitHub |
| `:GhOpenCompare` | No | Open compare page (default branch...current) |
| `:GhOpenPR` | No | Alias for `:GhOpenCompare` (compare page has PR creation button) |

### Functions

| Function | Description |
|----------|-------------|
| `ghopen#url(opts)` | Generate GitHub URL |
| `ghopen#open(opts)` | Open URL in browser |
| `ghopen#copy(opts)` | Copy URL to clipboard |

### Options

| Option | Default | Description |
|--------|---------|-------------|
| `g:ghopen_remote` | `'origin'` | Git remote name |
| `g:ghopen_default_branch` | `''` | Override default branch |
| `g:ghopen_browser` | auto | Browser command override |
| `g:ghopen_clipboard` | auto | Clipboard command override |
| `g:ghopen_debug` | `0` | Enable debug output |

## Configuration

### Key Mappings (Example)

```vim
nnoremap <Leader>go <Cmd>GhOpen<CR>
xnoremap <Leader>go :GhOpen<CR>
nnoremap <Leader>gO <Cmd>GhCopy<CR>
xnoremap <Leader>gO :GhCopy<CR>
nnoremap <Leader>gp <Cmd>GhOpenPermalink<CR>
xnoremap <Leader>gp :GhOpenPermalink<CR>
nnoremap <Leader>gP <Cmd>GhCopyPermalink<CR>
xnoremap <Leader>gP :GhCopyPermalink<CR>
nnoremap <Leader>gb <Cmd>GhOpenBlame<CR>
xnoremap <Leader>gb :GhOpenBlame<CR>
nnoremap <Leader>gC <Cmd>GhOpenCompare<CR>
```

## LICENSE

MIT
