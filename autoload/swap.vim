" swap.vim - Reorder delimited items.
" TODO: number displaying

let g:swap#timeoutlen  = get(g:, 'swap#timeoutlen', &timeoutlen)
let g:swap#stimeoutlen = get(g:, 'swap#stimeoutlen', 50)
let g:swap#highlight   = get(g:, 'swap#highlight', 1)
let g:swap#hl_itemnr   = get(g:, 'swap#hl_itemnr', 'Special')
let g:swap#hl_arrow    = get(g:, 'swap#hl_arrow', 'NONE')
let g:swap#arrow       = get(g:, 'swap#arrow', ' <=> ')
let g:swap#default_rules = [
      \   {'mode': 'x', 'delimiter': ['\s*,\s*'], 'braket': [['(', ')'], ['[', ']'], ['{', '}']], 'quotes': [['"', '"']], 'literal_quotes': [["'", "'"]], 'immutable': ['\%(^\s\|\n\)\s*']},
      \   {'mode': 'n', 'body': '\%(\h\w*,\s*\)\+\%(\h\w*\)\?', 'delimiter': ['\s*,\s*'], 'priority': -10},
      \   {'mode': 'n', 'surrounds': ['\[', '\]', 1], 'delimiter': ['\s*,\s*'], 'braket': [['(', ')'], ['[', ']'], ['{', '}']], 'quotes': [['"', '"']], 'literal_quotes': [["'", "'"]], 'immutable': ['\%(^\|\n\)\s\+']},
      \   {'mode': 'n', 'surrounds': ['{', '}', 1],   'delimiter': ['\s*,\s*'], 'braket': [['(', ')'], ['[', ']'], ['{', '}']], 'quotes': [['"', '"']], 'literal_quotes': [["'", "'"]], 'immutable': ['\%(^\|\n\)\s\+']},
      \   {'mode': 'n', 'surrounds': ['(', ')', 1],   'delimiter': ['\s*,\s*'], 'braket': [['(', ')'], ['[', ']'], ['{', '}']], 'quotes': [['"', '"']], 'literal_quotes': [["'", "'"]], 'immutable': ['\%(^\|\n\)\s\+']},
      \   {'mode': 'n', 'surrounds': ['\[', '\]', 1], 'delimiter': ['\s*,\s*'], 'filetype': ['vim'], 'braket': [['(', ')'], ['[', ']'], ['{', '}']], 'quotes': [['"', '"']], 'literal_quotes': [["'", "'"]], 'immutable': ['\%(^\|\n\)\s*\\\s*']},
      \   {'mode': 'n', 'surrounds': ['{', '}', 1],   'delimiter': ['\s*,\s*'], 'filetype': ['vim'], 'braket': [['(', ')'], ['[', ']'], ['{', '}']], 'quotes': [['"', '"']], 'literal_quotes': [["'", "'"]], 'immutable': ['\%(^\|\n\)\s*\\\s*']},
      \   {'mode': 'n', 'surrounds': ['(', ')', 1],   'delimiter': ['\s*,\s*'], 'filetype': ['vim'], 'braket': [['(', ')'], ['[', ']'], ['{', '}']], 'quotes': [['"', '"']], 'literal_quotes': [["'", "'"]], 'immutable': ['\%(^\|\n\)\s*\\\s*']},
      \   {'mode': 'n', 'surrounds': ['(', ')', 1],   'delimiter': ['\s*,\s*'], 'filetype': ['fortran'], 'braket': [['(', ')'], ['[', ']']], 'quotes': [['"', '"']], 'literal_quotes': [["'", "'"]], 'immutable': ['\s*&\s*\%(!.\{-}\)\?\n\s*\%(&\s*\)\?']},
      \   {'mode': 'n', 'surrounds': ['\[', '\]', 1], 'delimiter': ['\s*[,;]\?\s*'], 'filetype': ['matlab'], 'braket': [['(', ')'], ['[', ']'], ['{', '}']], 'literal_quotes': [["'", "'"]], 'immutable': ['\s*\.\{3}\s*\n\s*']},
      \   {'mode': 'n', 'surrounds': ['{', '}', 1],   'delimiter': ['\s*[,;]\?\s*'], 'filetype': ['matlab'], 'braket': [['(', ')'], ['[', ']'], ['{', '}']], 'literal_quotes': [["'", "'"]], 'immutable': ['\s*\.\{3}\s*\n\s*']},
      \   {'mode': 'n', 'surrounds': ['{', '}', 1],   'delimiter': ['\n'], 'filetype': ['c'], 'braket': [['(', ')'], ['[', ']'], ['{', '}'], ['/*', '*/']], 'quotes': [['"', '"'], ["'", "'"]], 'immutable': ['^\n', '\n\zs\s\+']},
      \   {'mode': 'n', 'surrounds': ['(', ')', 1],   'delimiter': ['\s*,\s*'],      'filetype': ['matlab'], 'braket': [['(', ')'], ['[', ']'], ['{', '}']], 'literal_quotes': [["'", "'"]], 'immutable': ['\s*\.\{3}\s*\n\s*']},
      \ ]

" features
let s:has_gui_running = has('gui_running')

function! swap#prerequisite(mode, ...) abort "{{{
  let g:swap = swap#swap#new()
  let g:swap.dotrepeat = 0
  let g:swap.mode = a:mode
  let g:swap.order_list = get(a:000, 0, [])
  set operatorfunc=swap#swap
endfunction
"}}}
function! swap#swap(motionwise) abort "{{{
  let view = winsaveview()
  let dotrepeat = g:swap.dotrepeat
  let err = g:swap.error
  let [whichwrap, virtualedit, selection, cursor, cursorline] = s:displace_options()
  try
    call g:swap.execute(a:motionwise)
  catch /^SwapModeErr/
  catch
    call err.catch(printf('vim-swap: Unanticipated error. [%s] %s', v:throwpoint, v:exception))
  finally
    call s:restore_options(virtualedit, whichwrap, selection, cursor, cursorline)

    if err.catched
      if !dotrepeat
        unlet! g:swap
      endif
      call winrestview(view)
      echoerr err.message
    endif
  endtry
endfunction
"}}}
function! swap#map(lhs, rhs) abort "{{{
  call s:keymap(0, a:lhs, a:rhs)
endfunction
"}}}
function! swap#noremap(lhs, rhs) abort "{{{
  call s:keymap(1, a:lhs, a:rhs)
endfunction
"}}}

function! s:displace_options() abort  "{{{
  let [ virtualedit,  whichwrap,  selection] = [&virtualedit, &whichwrap, &selection]
  let [&virtualedit, &whichwrap, &selection] = ['onemore', 'h,l', 'inclusive']
  if s:has_gui_running
    let cursor = &guicursor
    set guicursor+=n-o:block-NONE
  else
    let cursor = &t_ve
    set t_ve=
  endif
  let cursorline = &l:cursorline
  setlocal nocursorline
  return [virtualedit, whichwrap, selection, cursor, cursorline]
endfunction
"}}}
function! s:restore_options(virtualedit, whichwrap, selection, cursor, cursorline) abort "{{{
  let [&virtualedit, &whichwrap, &selection] = [a:virtualedit, a:whichwrap, a:selection]
  if s:has_gui_running
    set guicursor&
    let &guicursor = a:cursor
  else
    let &t_ve = a:cursor
  endif
  let &l:cursorline = a:cursorline
endfunction
"}}}
function! s:keymap(noremap, lhs, rhs) abort  "{{{
  let g:swap#keymappings = get(g:, 'swap#keymappings', g:swap#default_keymappings)
  let keymap = {'noremap': a:noremap, 'input': a:lhs, 'output': a:rhs}
  let g:swap#keymappings += [keymap]
endfunction
"}}}

" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" vim:set ts=2 sts=2 sw=2:
