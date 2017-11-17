" The vim plugin to reorder delimited items.
" Last Change: 17-Nov-2017.
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

" swap mode mappings
nnoremap <silent> <Plug>(swap-mode-0) :<C-u>call swap#interface#swapmode_key_nr('0')<CR>
nnoremap <silent> <Plug>(swap-mode-1) :<C-u>call swap#interface#swapmode_key_nr('1')<CR>
nnoremap <silent> <Plug>(swap-mode-2) :<C-u>call swap#interface#swapmode_key_nr('2')<CR>
nnoremap <silent> <Plug>(swap-mode-3) :<C-u>call swap#interface#swapmode_key_nr('3')<CR>
nnoremap <silent> <Plug>(swap-mode-4) :<C-u>call swap#interface#swapmode_key_nr('4')<CR>
nnoremap <silent> <Plug>(swap-mode-5) :<C-u>call swap#interface#swapmode_key_nr('5')<CR>
nnoremap <silent> <Plug>(swap-mode-6) :<C-u>call swap#interface#swapmode_key_nr('6')<CR>
nnoremap <silent> <Plug>(swap-mode-7) :<C-u>call swap#interface#swapmode_key_nr('7')<CR>
nnoremap <silent> <Plug>(swap-mode-8) :<C-u>call swap#interface#swapmode_key_nr('8')<CR>
nnoremap <silent> <Plug>(swap-mode-9) :<C-u>call swap#interface#swapmode_key_nr('9')<CR>
nnoremap <silent> <Plug>(swap-mode-CR) :<C-u>call swap#interface#swapmode_key_CR()<CR>
nnoremap <silent> <Plug>(swap-mode-BS) :<C-u>call swap#interface#swapmode_key_BS()<CR>
nnoremap <silent> <Plug>(swap-mode-undo) :<C-u>call swap#interface#swapmode_key_undo()<CR>
nnoremap <silent> <Plug>(swap-mode-redo) :<C-u>call swap#interface#swapmode_key_redo()<CR>
nnoremap <silent> <Plug>(swap-mode-current) :<C-u>call swap#interface#swapmode_key_current()<CR>
nnoremap <silent> <Plug>(swap-mode-fix-nr) :<C-u>call swap#interface#swapmode_key_fix_nr()<CR>
nnoremap <silent> <Plug>(swap-mode-move-prev) :<C-u>call swap#interface#swapmode_key_move_prev()<CR>
nnoremap <silent> <Plug>(swap-mode-move-next) :<C-u>call swap#interface#swapmode_key_move_next()<CR>
nnoremap <silent> <Plug>(swap-mode-swap-prev) :<C-u>call swap#interface#swapmode_key_swap_prev()<CR>
nnoremap <silent> <Plug>(swap-mode-swap-next) :<C-u>call swap#interface#swapmode_key_swap_next()<CR>
nnoremap <silent> <Plug>(swap-mode-echo) :<C-u>call swap#interface#swapmode_key_echo()<CR>
nnoremap <silent> <Plug>(swap-mode-Esc) :<C-u>call swap#interface#swapmode_key_ESC()<CR>

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
