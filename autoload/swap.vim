" swap.vim - Reorder delimited items.
" TODO: number displaying

let s:Logging = swap#logging#import()

let s:TRUE = 1
let s:FALSE = 0

let s:logger = s:Logging.Logger(expand('<sfile>'))

let g:swap#timeoutlen  = get(g:, 'swap#timeoutlen', &timeoutlen)
let g:swap#stimeoutlen = get(g:, 'swap#stimeoutlen', 50)
let g:swap#highlight   = get(g:, 'swap#highlight', s:TRUE)
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
\     'mode': 'x',
\     'delimiter': ['\s*,\s*'],
\     'braket': [['(', ')'], ['[', ']'], ['{', '}']],
\     'quotes': [['"', '"']],
\     'literal_quotes': [["'", "'"]],
\     'immutable': ['\%(^\_s\|\n\)\s*\\\s*', '\s\+$']
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
\     'description': 'Reorder the comma-separated items in () for fortran, with taking into account line continuations by ampersand.',
\     'filetype': ['fortran'],
\     'mode': 'x',
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
\     'mode': 'x',
\     'delimiter': ['\s*[,;[:space:]]\s*'],
\     'braket': [['(', ')'], ['[', ']'], ['{', '}']],
\     'immutable': ['\s*\.\{3}\s*\n\s*',
\     '\s\+$']
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
\
\   {
\     'description': 'Reorder the comma-separated items in () for julia.',
\     'filetype': ['julia'],
\     'mode': 'n',
\     'surrounds': ['(', ')', 1],
\     'delimiter': ['\s*[,;]\s*'],
\     'braket': [['(', ')'], ['[', ']'], ['{', '}']],
\     'quotes': [['"', '"'], ["'", "'"]],
\     'immutable': ['\%(^\_s\|\n\)\s*', '\s\+$']
\   },
\ ]


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


" Swap items in the specific region on the current buffer
" NOTE: Just a one-shot action, not repeated by dot command
function! swap#region(start, end, type, input_list, ...) abort "{{{
  call s:logger.debug('Call swap#region(%s, %s, %s, %s, %s)',
  \                   a:start, a:end, a:type, a:input_list, a:000)
  let rules = get(a:000, 0, get(g:, 'swap#rules', g:swap#default_rules))
  if empty(a:input_list)
    return
  endif
  let swap = swap#swap#new('x', a:input_list, rules)
  call swap.region(a:start, a:end, a:type)
  call s:logger.debug('Finish swap#region()')
endfunction "}}}


" Search swappable items around a position and swap them
" NOTE: Just a one-shot action, not repeated by dot command
function! swap#around_pos(pos, input_list, ...) abort "{{{
  call s:logger.debug('swap#around_pos(%s, %s, %s)', a:pos, a:input_list, a:000)
  let rules = get(a:000, 0, get(g:, 'swap#rules', g:swap#default_rules))
  if empty(a:input_list)
    return
  endif
  let swap = swap#swap#new('n', a:input_list, rules)
  call swap.around(a:pos)
  call s:logger.debug('Finish swap#around_pos()')
endfunction "}}}


" Swap items in the specific region on the current buffer in swap mode
" NOTE: Just a one-shot action, not repeated by dot command
function! swap#region_interactively(start, end, type, ...) abort "{{{
  call s:logger.debug('swap#region_interactively(%s, %s, %s, %s, %s)',
  \                   a:start, a:end, a:type, a:000)
  let rules = get(a:000, 0, get(g:, 'swap#rules', g:swap#default_rules))
  let swap = swap#swap#new('x', [], rules)
  call swap.region(a:start, a:end, a:type)
  call s:logger.debug('Finish swap#region_interactively()')
endfunction "}}}


" Search swappable items around a position and swap them in swap mode
" NOTE: Just a one-shot action, not repeated by dot command
function! swap#around_pos_interactively(pos, ...) abort "{{{
  call s:logger.debug('swap#around_pos_interactively(%s, %s)', a:pos, a:000)
  let rules = get(a:000, 0, get(g:, 'swap#rules', g:swap#default_rules))
  let swap = swap#swap#new('n', [], rules)
  call swap.around(a:pos)
  call s:logger.debug('Finish swap#around_pos_interactively()')
endfunction "}}}


" This function sets 'operatorfunc' option. Use like this:
"   nnoremap <silent> gs :<C-u>call swap#prerequisite('n')g@l
"   xnoremap <silent> gs :<C-u>call swap#prerequisite('x')gvg@
function! swap#prerequisite(mode, ...) abort "{{{
  call s:logger.debug('swap#prerequisite(%s, %s)', a:mode, a:000)
  let input_list = get(a:000, 0, [])
  let rules = get(a:000, 1, get(g:, 'swap#rules', g:swap#default_rules))
  let g:swap = swap#swap#new(a:mode, input_list, rules)
  set operatorfunc=swap#operatorfunc
endfunction "}}}


" The operator function
function! swap#operatorfunc(motionwise) abort "{{{
  call s:logger.debug('swap#operatorfunc(%s)', a:motionwise)
  if !exists('g:swap')
    return
  endif
  call g:swap.operatorfunc(a:motionwise)
  call s:logger.debug('Finish swap#operatorfunc()')
endfunction "}}}


" key layout in swap mode
" key layout - discreet "{{{
let g:swap#key_layout_discreet = {
\   '0': ['0'],
\   '1': ['1'],
\   '2': ['2'],
\   '3': ['3'],
\   '4': ['4'],
\   '5': ['5'],
\   '6': ['6'],
\   '7': ['7'],
\   '8': ['8'],
\   '9': ['9'],
\   "\<CR>": ['CR'],
\   "\<BS>": ['BS'],
\   "\<C-h>": ['BS'],
\   'u': ['undo'],
\   "\<C-r>": ['redo'],
\   'h': ['swap_prev'],
\   'l': ['swap_next'],
\   'k': ['move_prev'],
\   'j': ['move_next'],
\   's': ['sort'],
\   'S': ['SORT'],
\   'g': ['group'],
\   'G': ['ungroup'],
\   'r': ['reverse'],
\   "\<Left>": ['swap_prev'],
\   "\<Right>": ['swap_next'],
\   "\<Up>": ['move_prev'],
\   "\<Down>": ['move_next'],
\   "\<Esc>": ['Esc'],
\ }
"}}}

" key layout - impatient  "{{{
let g:swap#key_layout_impatient = {
\   '1': ['1', 'fix_nr'],
\   '2': ['2', 'fix_nr'],
\   '3': ['3', 'fix_nr'],
\   '4': ['4', 'fix_nr'],
\   '5': ['5', 'fix_nr'],
\   '6': ['6', 'fix_nr'],
\   '7': ['7', 'fix_nr'],
\   '8': ['8', 'fix_nr'],
\   '9': ['9', 'fix_nr'],
\   "\<CR>": ['CR'],
\   "\<BS>": ['BS'],
\   "\<C-h>": ['BS'],
\   'u': ['undo'],
\   "\<C-r>": ['redo'],
\   'h': ['swap_prev'],
\   'l': ['swap_next'],
\   'k': ['move_prev'],
\   'j': ['move_next'],
\   's': ['sort'],
\   'S': ['SORT'],
\   'g': ['group'],
\   'G': ['ungroup'],
\   'r': ['reverse'],
\   "\<Left>": ['swap_prev'],
\   "\<Right>": ['swap_next'],
\   "\<Up>": ['move_prev'],
\   "\<Down>": ['move_next'],
\   "\<Esc>": ['Esc'],
\ }
"}}}

let g:swap#default_keymappings = g:swap#key_layout_impatient

" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" vim:set ts=2 sts=2 sw=2:
