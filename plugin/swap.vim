" The vim plugin to reorder delimited items.
" Last Change: 19-Nov-2017.
" Maintainer : Masaaki Nakamura <mckn@outlook.jp>

" License    : NYSL
"              Japanese <http://www.kmonos.net/nysl/>
"              English (Unofficial) <http://www.kmonos.net/nysl/index.en.html>

if &compatible || exists("g:loaded_swap")
  finish
endif
let g:loaded_swap = 1

" keymappings
nnoremap <silent> <Plug>(swap-interactive) :<C-u>call swap#prerequisite('n')<CR>g@l
xnoremap <silent> <Plug>(swap-interactive) :<C-u>call swap#prerequisite('x')<CR>gvg@
nnoremap <silent> <Plug>(swap-prev) :<C-u>call swap#prerequisite('n', [['#', '#-1']])<CR>g@l
nnoremap <silent> <Plug>(swap-next) :<C-u>call swap#prerequisite('n', [['#', '#+1']])<CR>g@l
noremap <silent> <Plug>(swap-textobject-i) :<C-u>call swap#textobj#select('i')<CR>
noremap <silent> <Plug>(swap-textobject-a) :<C-u>call swap#textobj#select('a')<CR>

" highlight group
function! s:default_highlight() abort
  highlight default link SwapItem Underlined
  highlight default link SwapCurrentItem IncSearch
  highlight default link SwapSelectedItem Visual
endfunction
call s:default_highlight()

augroup swapdotvim-highlight
  autocmd!
  autocmd ColorScheme * call s:default_highlight()
augroup END

""" default keymappings
" If g:swap_no_default_key_mappings has been defined, then quit immediately.
if exists('g:swap_no_default_key_mappings') | finish | endif

nmap gs <Plug>(swap-interactive)
xmap gs <Plug>(swap-interactive)
nmap g< <Plug>(swap-prev)
nmap g> <Plug>(swap-next)
