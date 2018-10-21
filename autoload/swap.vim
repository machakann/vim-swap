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
      \     'immutable': ['\%(^\_s\|\n\)\s*', '\s\+$'],
      \     'priority': -50
      \   },
      \
      \   {
      \     'description': 'Reorder the selected comma-delimited word in visual mode.',
      \     'mode': 'x',
      \     'delimiter': ['\s*,\s*'],
      \     'braket': [['(', ')'], ['[', ']'], ['{', '}']],
      \     'quotes': [['"', '"'], ["'", "'"]],
      \     'immutable': ['\%(^\_s\|\n\)\s*', '\s\+$'],
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
      \     'immutable': ['\%(^\_s\|\n\)\s*', '\s\+$']
      \   },
      \
      \   {
      \     'description': 'Reorder the comma-separated items in {}.',
      \     'mode': 'n',
      \     'surrounds': ['{', '}', 1],
      \     'delimiter': ['\s*,\s*'],
      \     'braket': [['(', ')'], ['[', ']'], ['{', '}']],
      \     'quotes': [['"', '"'], ["'", "'"]],
      \     'immutable': ['\%(^\_s\|\n\)\s*', '\s\+$']
      \   },
      \
      \   {
      \     'description': 'Reorder the comma-separated items in ().',
      \     'mode': 'n',
      \     'surrounds': ['(', ')', 1],
      \     'delimiter': ['\s*,\s*'],
      \     'braket': [['(', ')'], ['[', ']'], ['{', '}']],
      \     'quotes': [['"', '"'], ["'", "'"]],
      \     'immutable': ['\%(^\_s\|\n\)\s*', '\s\+$']
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
      \     'immutable': ['\%(^\_s\|\n\)\s*\\\s*', '\s\+$']
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
      \     'immutable': ['\%(^\_s\|\n\)\s*\\\s*', '\s\+$']
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
      \     'immutable': ['\%(^\_s\|\n\)\s*\\\s*', '\s\+$']
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


" This function sets 'operatorfunc' option. Use like this:
"   nnoremap <silent> gs :<C-u>call swap#prerequisite('n')g@l
"   xnoremap <silent> gs :<C-u>call swap#prerequisite('x')gvg@
function! swap#prerequisite(mode, ...) abort "{{{
  let g:swap = swap#swap#new(a:mode, get(a:000, 0, []))
  set operatorfunc=swap#operatorfunc
endfunction "}}}


" The operator function
function! swap#operatorfunc(motionwise) abort "{{{
  let options = s:displace_options()
  try
    call g:swap.execute(a:motionwise)
  finally
    call s:restore_options(options)
  endtry
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


" key layout in swap mode
" key layout - discreet "{{{
let g:swap#key_layout_discreet = [
      \   {'input': '0', 'output': ['0']},
      \   {'input': '1', 'output': ['1']},
      \   {'input': '2', 'output': ['2']},
      \   {'input': '3', 'output': ['3']},
      \   {'input': '4', 'output': ['4']},
      \   {'input': '5', 'output': ['5']},
      \   {'input': '6', 'output': ['6']},
      \   {'input': '7', 'output': ['7']},
      \   {'input': '8', 'output': ['8']},
      \   {'input': '9', 'output': ['9']},
      \   {'input': "\<CR>",  'output': ['CR']},
      \   {'input': "\<BS>",  'output': ['BS']},
      \   {'input': "\<C-h>", 'output': ['BS']},
      \   {'input': 'u',      'output': ['undo']},
      \   {'input': "\<C-r>", 'output': ['redo']},
      \   {'input': 'h', 'output': ['swap_prev']},
      \   {'input': 'l', 'output': ['swap_next']},
      \   {'input': 'k', 'output': ['move_prev']},
      \   {'input': 'j', 'output': ['move_next']},
      \   {'input': "\<Left>",  'output': ['swap_prev']},
      \   {'input': "\<Right>", 'output': ['swap_next']},
      \   {'input': "\<Up>",    'output': ['move_prev']},
      \   {'input': "\<Down>",  'output': ['move_next']},
      \   {'input': "\<Esc>", 'output': ['Esc']},
      \ ]
"}}}

" key layout - impatient  "{{{
let g:swap#key_layout_impatient = [
      \   {'input': '1', 'output': ['1', 'fix_nr']},
      \   {'input': '2', 'output': ['2', 'fix_nr']},
      \   {'input': '3', 'output': ['3', 'fix_nr']},
      \   {'input': '4', 'output': ['4', 'fix_nr']},
      \   {'input': '5', 'output': ['5', 'fix_nr']},
      \   {'input': '6', 'output': ['6', 'fix_nr']},
      \   {'input': '7', 'output': ['7', 'fix_nr']},
      \   {'input': '8', 'output': ['8', 'fix_nr']},
      \   {'input': '9', 'output': ['9', 'fix_nr']},
      \   {'input': "\<CR>",  'output': ['CR']},
      \   {'input': "\<BS>",  'output': ['BS']},
      \   {'input': "\<C-h>", 'output': ['BS']},
      \   {'input': 'u',      'output': ['undo']},
      \   {'input': "\<C-r>", 'output': ['redo']},
      \   {'input': 'h', 'output': ['swap_prev']},
      \   {'input': 'l', 'output': ['swap_next']},
      \   {'input': 'k', 'output': ['move_prev']},
      \   {'input': 'j', 'output': ['move_next']},
      \   {'input': "\<Left>",  'output': ['swap_prev']},
      \   {'input': "\<Right>", 'output': ['swap_next']},
      \   {'input': "\<Up>",    'output': ['move_prev']},
      \   {'input': "\<Down>",  'output': ['move_next']},
      \   {'input': "\<Esc>", 'output': ['Esc']},
      \ ]
"}}}

let g:swap#default_keymappings = g:swap#key_layout_impatient

" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" vim:set ts=2 sts=2 sw=2:
