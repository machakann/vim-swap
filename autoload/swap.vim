" swap.vim - Reorder delimited items.
" TODO: number displaying

let g:swap#timeoutlen  = get(g:, 'swap#timeoutlen', &timeoutlen)
let g:swap#stimeoutlen = get(g:, 'swap#stimeoutlen', 50)
let g:swap#highlight   = get(g:, 'swap#highlight', 1)
let g:swap#hl_itemnr   = get(g:, 'swap#hl_itemnr', 'Special')
let g:swap#hl_arrow    = get(g:, 'swap#hl_arrow', 'NONE')
let g:swap#arrow       = get(g:, 'swap#arrow', ' <=> ')
let g:swap#default_rules = [
      \   {
      \     'descripsion': 'Reorder the selected space-delimited word in visual mode.',
      \     'mode': 'x',
      \     'delimiter': ['\s\+'],
      \     'braket': [['(', ')'], ['[', ']'], ['{', '}']],
      \     'quotes': [['"', '"'], ["'", "'"]],
      \     'immutable': ['\%(^\s\|\n\)\s*', '\s\+$'],
      \     'priority': -50
      \   },
      \
      \   {
      \     'description': 'Reorder the selected comma-delimited word in visual mode.',
      \     'mode': 'x',
      \     'delimiter': ['\s*,\s*'],
      \     'braket': [['(', ')'], ['[', ']'], ['{', '}']],
      \     'quotes': [['"', '"'], ["'", "'"]],
      \     'immutable': ['\%(^\s\|\n\)\s*', '\s\+$'],
      \   },
      \
      \   {
      \     'descripsion': 'Reorder the space-delimited word under the cursor in normal mode.',
      \     'mode': 'n',
      \     'body': '\%(\h\w*\s*\)\+\%(\h\w*\)\?',
      \     'delimiter': ['\s\+'],
      \     'priority': -50
      \   },
      \
      \   {
      \     'description': 'Reorder the comma-delimited word under the cursor in normal mode.',
      \     'mode': 'n',
      \     'body': '\%(\h\w*,\s*\)\+\%(\h\w*\)\?',
      \     'delimiter': ['\s*,\s*'],
      \     'priority': -10
      \   },
      \
      \   {
      \     'description': 'Reorder the comma-separated items in [].',
      \     'mode': 'n',
      \     'surrounds': ['\[', '\]', 1],
      \     'delimiter': ['\s*,\s*'],
      \     'braket': [['(', ')'], ['[', ']'], ['{', '}']],
      \     'quotes': [['"', '"'], ["'", "'"]],
      \     'immutable': ['\%(^\|\n\)\s\+', '\s\+$']
      \   },
      \
      \   {
      \     'description': 'Reorder the comma-separated items in {}.',
      \     'mode': 'n',
      \     'surrounds': ['{', '}', 1],
      \     'delimiter': ['\s*,\s*'],
      \     'braket': [['(', ')'], ['[', ']'], ['{', '}']],
      \     'quotes': [['"', '"'], ["'", "'"]],
      \     'immutable': ['\%(^\|\n\)\s\+', '\s\+$']
      \   },
      \
      \   {
      \     'description': 'Reorder the comma-separated items in ().',
      \     'mode': 'n',
      \     'surrounds': ['(', ')', 1],
      \     'delimiter': ['\s*,\s*'],
      \     'braket': [['(', ')'], ['[', ']'], ['{', '}']],
      \     'quotes': [['"', '"'], ["'", "'"]],
      \     'immutable': ['\%(^\|\n\)\s\+', '\s\+$']
      \   },
      \
      \   {
      \     'description': 'Reorder the comma-separated items in [] for Vim script, with taking into account line continuations by backslashes.',
      \     'filetype': ['vim'],
      \     'mode': 'n',
      \     'surrounds': ['\[', '\]', 1],
      \     'delimiter': ['\s*,\s*'],
      \     'braket': [['(', ')'], ['[', ']'], ['{', '}']],
      \     'quotes': [['"', '"']],
      \     'literal_quotes': [["'", "'"]],
      \     'immutable': ['\%(^\|\n\)\s*\\\s*', '\s\+$']
      \   },
      \
      \   {
      \     'description': 'Reorder the comma-separated items in {} for Vim script, with taking into account line continuations by backslashes.',
      \     'filetype': ['vim'],
      \     'mode': 'n',
      \     'surrounds': ['{', '}', 1],
      \     'delimiter': ['\s*,\s*'],
      \     'braket': [['(', ')'], ['[', ']'], ['{', '}']],
      \     'quotes': [['"', '"']],
      \     'literal_quotes': [["'", "'"]],
      \     'immutable': ['\%(^\|\n\)\s*\\\s*', '\s\+$']
      \   },
      \
      \   {
      \     'description': 'Reorder the comma-separated items in () for Vim script, with taking into account line continuations by backslash.',
      \     'filetype': ['vim'],
      \     'mode': 'n',
      \     'surrounds': ['(', ')', 1],
      \     'delimiter': ['\s*,\s*'],
      \     'braket': [['(', ')'], ['[', ']'], ['{', '}']],
      \     'quotes': [['"', '"']],
      \     'literal_quotes': [["'", "'"]],
      \     'immutable': ['\%(^\|\n\)\s*\\\s*', '\s\+$']
      \   },
      \
      \   {
      \     'description': 'Reorder the comma-separated items in () for fortran, with taking into account line continuations by ampersand.',
      \     'filetype': ['fortran'],
      \     'mode': 'n',
      \     'surrounds': ['(', ')', 1],
      \     'delimiter': ['\s*,\s*'],
      \     'braket': [['(', ')'], ['[', ']']],
      \     'quotes': [['"', '"']],
      \     'literal_quotes': [["'", "'"]],
      \     'immutable': ['\s*&\s*\%(!.\{-}\)\?\n\s*\%(&\s*\)\?', '\s\+$']
      \   },
      \
      \   {
      \     'description': 'Reorder the comma-separated items in [] for matlab, with taking into account line continuations by dots.',
      \     'filetype': ['matlab'],
      \     'mode': 'n',
      \     'surrounds': ['\[', '\]', 1],
      \     'delimiter': ['\s*[,;[:space:]]\s*'],
      \     'braket': [['(', ')'], ['[', ']'], ['{', '}']],
      \     'immutable': ['\s*\.\{3}\s*\n\s*',
      \     '\s\+$']
      \   },
      \
      \   {
      \     'description': 'Reorder the comma-separated items in {} for matlab, with taking into account line continuations by dots.',
      \     'filetype': ['matlab'],
      \     'mode': 'n',
      \     'surrounds': ['{', '}', 1],
      \     'delimiter': ['\s*[,;[:space:]]\s*'],
      \     'braket': [['(', ')'], ['[', ']'], ['{', '}']],
      \     'immutable': ['\s*\.\{3}\s*\n\s*', '\s\+$']
      \   },
      \
      \   {
      \     'description': 'Reorder the comma-separated items in () for matlab, with taking into account line continuations by dots.',
      \     'filetype': ['matlab'],
      \     'mode': 'n',
      \     'surrounds': ['(', ')', 1],
      \     'delimiter': ['\s*,\s*'],
      \     'braket': [['(', ')'], ['[', ']'], ['{', '}']],
      \     'immutable': ['\s*\.\{3}\s*\n\s*', '\s\+$']
      \   },
      \
      \   {
      \     'description': 'Reorder the line items in {} for c language.',
      \     'filetype': ['c'],
      \     'mode': 'n',
      \     'surrounds': ['{', '}', 1],
      \     'delimiter': ['\n'],
      \     'braket': [['(', ')'], ['[', ']'], ['{', '}'], ['/*', '*/']],
      \     'quotes': [['"', '"'], ["'", "'"]],
      \     'immutable': ['^\n', '\n\zs\s\+', '\s\+$']
      \   },
      \ ]

" features
let s:has_gui_running = has('gui_running')

function! swap#prerequisite(mode, ...) abort "{{{
  let g:swap = swap#swap#new(a:mode, get(a:000, 0, []))
  set operatorfunc=swap#swap
endfunction "}}}
function! swap#swap(motionwise) abort "{{{
  let view = winsaveview()
  let dotrepeat = g:swap.dotrepeat
  let err = g:swap.error
  let options = s:displace_options()
  try
    call g:swap.execute(a:motionwise)
  catch /^SwapModeErr/
  catch
    call err.catch(printf('vim-swap: Unanticipated error. [%s] %s', v:throwpoint, v:exception))
  finally
    call s:restore_options(options)

    if err.catched
      if !dotrepeat
        unlet! g:swap
      endif
      call winrestview(view)
      echoerr err.message
    endif
  endtry
endfunction "}}}
function! swap#map(lhs, rhs) abort "{{{
  call s:keymap(0, a:lhs, a:rhs)
endfunction "}}}
function! swap#noremap(lhs, rhs) abort "{{{
  call s:keymap(1, a:lhs, a:rhs)
endfunction "}}}

function! s:displace_options() abort  "{{{
  let options = {}
  let options.virtualedit = &virtualedit
  let options.whichwrap = &whichwrap
  let options.selection = &selection
  let [&virtualedit, &whichwrap, &selection] = ['onemore', 'h,l', 'inclusive']
  if s:has_gui_running
    let options.cursor = &guicursor
    set guicursor+=n-o:block-NONE
  else
    let options.cursor = &t_ve
    set t_ve=
  endif
  let options.cursorline = &l:cursorline
  setlocal nocursorline
  return options
endfunction "}}}
function! s:restore_options(options) abort "{{{
  let &virtualedit = a:options.virtualedit
  let &whichwrap = a:options.whichwrap
  let &selection = a:options.selection
  if s:has_gui_running
    set guicursor&
    let &guicursor = a:options.cursor
  else
    let &t_ve = a:options.cursor
  endif
  let &l:cursorline = a:options.cursorline
endfunction "}}}
function! s:keymap(noremap, lhs, rhs) abort  "{{{
  let g:swap#keymappings = get(g:, 'swap#keymappings', g:swap#default_keymappings)
  let keymap = {'noremap': a:noremap, 'input': a:lhs, 'output': a:rhs}
  let g:swap#keymappings += [keymap]
endfunction "}}}

" key layout in swap mode
" swap mode mappings{{{
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
"}}}
" key layout - discreet "{{{
let g:swap#key_layout_discreet = [
      \   {'input': '0', 'output': "\<Plug>(swap-mode-0)"},
      \   {'input': '1', 'output': "\<Plug>(swap-mode-1)"},
      \   {'input': '2', 'output': "\<Plug>(swap-mode-2)"},
      \   {'input': '3', 'output': "\<Plug>(swap-mode-3)"},
      \   {'input': '4', 'output': "\<Plug>(swap-mode-4)"},
      \   {'input': '5', 'output': "\<Plug>(swap-mode-5)"},
      \   {'input': '6', 'output': "\<Plug>(swap-mode-6)"},
      \   {'input': '7', 'output': "\<Plug>(swap-mode-7)"},
      \   {'input': '8', 'output': "\<Plug>(swap-mode-8)"},
      \   {'input': '9', 'output': "\<Plug>(swap-mode-9)"},
      \   {'input': "\<CR>",  'output': "\<Plug>(swap-mode-CR)"},
      \   {'input': "\<BS>",  'output': "\<Plug>(swap-mode-BS)"},
      \   {'input': "\<C-h>", 'output': "\<Plug>(swap-mode-BS)"},
      \   {'input': 'u',      'output': "\<Plug>(swap-mode-undo)"},
      \   {'input': "\<C-r>", 'output': "\<Plug>(swap-mode-redo)"},
      \   {'input': 'h', 'output': "\<Plug>(swap-mode-swap-prev)"},
      \   {'input': 'l', 'output': "\<Plug>(swap-mode-swap-next)"},
      \   {'input': 'k', 'output': "\<Plug>(swap-mode-move-prev)"},
      \   {'input': 'j', 'output': "\<Plug>(swap-mode-move-next)"},
      \   {'input': "\<Left>",  'output': "\<Plug>(swap-mode-swap-prev)"},
      \   {'input': "\<Right>", 'output': "\<Plug>(swap-mode-swap-next)"},
      \   {'input': "\<Up>",    'output': "\<Plug>(swap-mode-move-prev)"},
      \   {'input': "\<Down>",  'output': "\<Plug>(swap-mode-move-next)"},
      \   {'input': "\<Esc>", 'output': "\<Plug>(swap-mode-Esc)"},
      \ ]
"}}}
" key layout - impatient  "{{{
let g:swap#key_layout_impatient = [
      \   {'input': '1', 'output': "\<Plug>(swap-mode-1)\<Plug>(swap-mode-fix-nr)"},
      \   {'input': '2', 'output': "\<Plug>(swap-mode-2)\<Plug>(swap-mode-fix-nr)"},
      \   {'input': '3', 'output': "\<Plug>(swap-mode-3)\<Plug>(swap-mode-fix-nr)"},
      \   {'input': '4', 'output': "\<Plug>(swap-mode-4)\<Plug>(swap-mode-fix-nr)"},
      \   {'input': '5', 'output': "\<Plug>(swap-mode-5)\<Plug>(swap-mode-fix-nr)"},
      \   {'input': '6', 'output': "\<Plug>(swap-mode-6)\<Plug>(swap-mode-fix-nr)"},
      \   {'input': '7', 'output': "\<Plug>(swap-mode-7)\<Plug>(swap-mode-fix-nr)"},
      \   {'input': '8', 'output': "\<Plug>(swap-mode-8)\<Plug>(swap-mode-fix-nr)"},
      \   {'input': '9', 'output': "\<Plug>(swap-mode-9)\<Plug>(swap-mode-fix-nr)"},
      \   {'input': "\<CR>",  'output': "\<Plug>(swap-mode-CR)"},
      \   {'input': "\<BS>",  'output': "\<Plug>(swap-mode-BS)"},
      \   {'input': "\<C-h>", 'output': "\<Plug>(swap-mode-BS)"},
      \   {'input': 'u',      'output': "\<Plug>(swap-mode-undo)"},
      \   {'input': "\<C-r>", 'output': "\<Plug>(swap-mode-redo)"},
      \   {'input': 'h', 'output': "\<Plug>(swap-mode-swap-prev)"},
      \   {'input': 'l', 'output': "\<Plug>(swap-mode-swap-next)"},
      \   {'input': 'k', 'output': "\<Plug>(swap-mode-move-prev)"},
      \   {'input': 'j', 'output': "\<Plug>(swap-mode-move-next)"},
      \   {'input': "\<Left>",  'output': "\<Plug>(swap-mode-swap-prev)"},
      \   {'input': "\<Right>", 'output': "\<Plug>(swap-mode-swap-next)"},
      \   {'input': "\<Up>",    'output': "\<Plug>(swap-mode-move-prev)"},
      \   {'input': "\<Down>",  'output': "\<Plug>(swap-mode-move-next)"},
      \   {'input': "\<Esc>", 'output': "\<Plug>(swap-mode-Esc)"},
      \ ]
"}}}
let g:swap#default_keymappings = g:swap#key_layout_impatient

" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" vim:set ts=2 sts=2 sw=2:
