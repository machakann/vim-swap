" swap.vim - Reorder delimited items.
" TODO: number displaying

" NOTE: s:swap.state == 1 means functions (swap#textobject(), swap#operator())
"       were called by key bindings while s:swap.state == 0 means functions
"       were called by dot command.

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
      \   {'mode': 'n', 'surrounds': ['(', ')', 1],   'delimiter': ['\s*,\s*'],      'filetype': ['matlab'], 'braket': [['(', ')'], ['[', ']'], ['{', '}']], 'literal_quotes': [["'", "'"]], 'immutable': ['\s*\.\{3}\s*\n\s*']},
      \   {'mode': 'n', 'surrounds': ['{', '}', 1],   'delimiter': ['\n'], 'filetype': ['c'], 'braket': [['(', ')'], ['[', ']'], ['{', '}'], ['/*', '*/']], 'quotes': [['"', '"'], ["'", "'"]], 'immutable': ['^\n', '\n\zs\s\+']},
      \ ]

let s:type_str    = type('')
let s:type_num    = type(0)
let s:type_list   = type([])
let s:null_coord  = [0, 0]
let s:null_pos    = [0, 0, 0, 0]
let s:null_region = {'head': copy(s:null_pos), 'tail': copy(s:null_pos), 'len': -1}

" patches
if v:version > 704 || (v:version == 704 && has('patch237'))
  let s:has_patch_7_4_311 = has('patch-7.4.311')
  let s:has_patch_7_4_358 = has('patch-7.4.358')
  let s:has_patch_7_4_362 = has('patch-7.4.362')
else
  let s:has_patch_7_4_311 = v:version == 704 && has('patch311')
  let s:has_patch_7_4_358 = v:version == 704 && has('patch358')
  let s:has_patch_7_4_362 = v:version == 704 && has('patch362')
endif

" features
let s:has_reltime_and_float = has('reltime') && has('float')
let s:has_gui_running = has('gui_running')

function! swap#prerequisite(mode, ...) abort "{{{
  let s:swap = deepcopy(s:swap_obj_prototype)
  let s:swap.mode = a:mode
  let s:swap.motionwise = a:mode ==# 'x' ? visualmode() : 'v'
  let s:swap.state = 1
  let s:swap.order = get(a:000, 0, [])
  if a:mode ==# 'x'
    let s:swap.curpos = getpos('.')
  endif
  set operatorfunc=swap#operator
endfunction
"}}}
function! swap#textobject() abort "{{{
  if !exists('s:swap')
    return
  endif

  if !s:swap.state
    let s:swap.region = deepcopy(s:null_region)
  endif

  let view = winsaveview()
  let s:swap.curpos = getpos('.')
  let s:swap.view = view
  let mode = s:swap.mode
  let rules = s:get_rules(mode)
  let objects = map(rules, 's:swap_objectize(v:val)')

  let [virtualedit, whichwrap, selection] = s:displace_options()
  let errormsg = ''
  try
    let swap_obj = s:get_swap_obj(objects, mode)
  catch
    let errormsg = printf('vim-swap: Unanticipated error. [%s] %s', v:throwpoint, v:exception)
  finally
    call s:restore_options(virtualedit, whichwrap, selection)

    if errormsg !=# ''
      echoerr errormsg
      unlet! s:swap
    endif
  endtry

  call winrestview(view)
  if swap_obj != s:swap_obj_prototype
    let s:swap = swap_obj
  else
    unlet! s:swap
  endif

  " for test
  return swap_obj.region
endfunction
"}}}
function! swap#operator(motionwise) abort "{{{
  " NOTE: If s:swap.mode == 'n', a:motionwise is always 'v'.
  "       Thus, do not use a:motionwise.
  if !exists('s:swap')
    return
  endif

  if s:swap.mode ==# 'x'
    let s:swap.region = s:get_assigned_region(s:swap.motionwise)
    if s:swap.region == s:null_region
      let s:swap.state = 0
      return
    endif

    let mode = s:swap.mode
    let rules = s:get_rules(mode)
    let objects  = map(rules, 's:swap_objectize(v:val)')
    let swap_obj = s:get_swap_obj(objects, mode)
    if swap_obj != s:swap_obj_prototype
      let s:swap = swap_obj
    else
      let s:swap.state = 0
      return
    endif
  endif

  let errormsg = ''
  let [virtualedit, whichwrap, selection, cursor, cursorline] = s:displace_options(1)
  try
    call s:swap.execute()
  catch /^Vim:Interrupt$/
  catch /^Vim\%((\a\+)\)\=:E21/
    let errormsg = 'vim-swap: Cannot make changes to read-only buffer.'
  catch
    let errormsg = printf('vim-swap: Unanticipated error. [%s] %s', v:throwpoint, v:exception)
  finally
    call s:swap.buffer.clear_highlight()
    call s:restore_options(virtualedit, whichwrap, selection, cursor, cursorline)

    let s:swap.state = 0
    if errormsg !=# ''
      echoerr errormsg
      unlet! s:swap
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



function! s:filter_filetype(rule) abort  "{{{
  if !has_key(a:rule, 'filetype')
    return 1
  else
    let filetypes = split(&filetype, '\.')
    if filetypes == []
      let filter = 'v:val ==# ""'
    else
      let filter = 'v:val !=# "" && match(filetypes, v:val) > -1'
    endif
    return filter(copy(a:rule['filetype']), filter) != []
  endif
endfunction
"}}}
function! s:filter_mode(rule, mode) abort  "{{{
  if !has_key(a:rule, 'mode')
    return 1
  else
    return stridx(a:rule.mode, a:mode) > -1
  endif
endfunction
"}}}
function! s:remove_duplicate_rules(rules) abort "{{{
  let i = 0
  while i < len(a:rules)
    let representative = a:rules[i]
    let j = i + 1
    while j < len(a:rules)
      let target = a:rules[j]
      let duplicate_body = 0
      let duplicate_surrounds = 0
      if (has_key(representative, 'body') && has_key(target, 'body') && representative.body == target.body)
            \ || (!has_key(representative, 'body') && !has_key(target, 'body'))
        let duplicate_body = 1
      endif
      if (has_key(representative, 'surrounds') && has_key(target, 'surrounds') && representative.surrounds[0:1] == target.surrounds[0:1] && get(representative, 2, 1) == get(target, 2, 1))
            \ || (!has_key(representative, 'surrounds') && !has_key(target, 'surrounds'))
        let duplicate_surrounds = 1
      endif
      if duplicate_body && duplicate_surrounds
        call remove(a:rules, j)
      else
        let j += 1
      endif
    endwhile
    let i += 1
  endwhile
endfunction
"}}}
function! s:swap_objectize(rule) abort "{{{
  return extend(deepcopy(s:swap), {'rule': a:rule}, 'force')
endfunction
"}}}
function! s:get_rules(mode) abort "{{{
  let rules = deepcopy(get(g:, 'swap#rules', g:swap#default_rules))
  call map(rules, 'extend(v:val, {"priority": 0}, "keep")')
  call s:sort(reverse(rules), 's:compare_rules')
  call filter(rules, 's:filter_filetype(v:val) && s:filter_mode(v:val, a:mode)')
  if a:mode !=# 'x'
    call s:remove_duplicate_rules(rules)
  endif
  return rules
endfunction
"}}}
function! s:get_swap_obj(objects, mode, ...) abort  "{{{
  let timeout = g:swap#stimeoutlen
  if a:mode ==# 'n'
    while a:objects != []
      " make priority group
      let priority_group = s:get_priority_group(a:objects)

      while priority_group != []
        " search phase
        for swap_obj in priority_group
          call swap_obj.search(timeout)
        endfor
        call filter(priority_group, 'v:val.region.len > 0')

        " verify phase
        call s:sort(priority_group, 's:compare_len')
        for swap_obj in priority_group
          if swap_obj.verify()
            return swap_obj
          endif
        endfor
      endwhile
    endwhile
  elseif a:mode ==# 'x'
    while a:objects != []
      " make priority group
      let priority_group = s:get_priority_group(a:objects)

      " verify phase
      call s:sort(priority_group, 's:compare_len')
      for swap_obj in priority_group
        if swap_obj.verify()
          return swap_obj
        endif
      endfor
    endwhile
  endif
  return deepcopy(s:swap_obj_prototype)
endfunction
"}}}
function! s:get_priority_group(objects) abort "{{{
  " NOTE: This function move items in a:objects to priority_group.
  "       Thus it makes changes to a:objects also.
  let priority = get(a:objects[0].rule, 'priority', 0)
  let priority_group = []
  while a:objects != []
    let swap_obj = a:objects[0]
    if swap_obj.rule.priority != priority
      break
    endif
    call add(priority_group, remove(a:objects, 0))
  endwhile
  return priority_group
endfunction
"}}}
function! s:get_outer_pos(surrounds, region) abort  "{{{
  let n_line = count(split(a:surrounds[0]), "\n")
  let stopline = max([line('.') - n_line, 1])
  call setpos('.', a:region.head)
  let head = s:c2p(searchpos(a:surrounds[0], 'b', stopline))
  if head != s:null_pos
    let head = s:get_left_pos(head)
  endif

  let n_line = count(split(a:surrounds[1]), "\n")
  let stopline = min([line('.') + n_line, line('$')])
  call setpos('.', a:region.tail)
  let tail = s:c2p(searchpos(a:surrounds[1], 'e', stopline))
  if tail != s:null_pos
    let tail = s:get_right_pos(tail)
  endif
  return [head, tail]
endfunction
"}}}
function! s:search_body(body, pos, timeout) abort "{{{
  call setpos('.', a:pos)
  let tail = searchpos(a:body, 'ce', 0, a:timeout)
  if tail == s:null_coord | return deepcopy(s:null_region) | endif
  let tail = s:c2p(tail)
  let head = searchpos(a:body, 'b',  0, a:timeout)
  if head == s:null_coord | return deepcopy(s:null_region) | endif
  let head = s:c2p(head)
  return s:is_ahead(tail, head) && s:is_in_between(a:pos, head, tail)
        \ ? extend(deepcopy(s:null_region), {'head': head, 'tail': tail}, 'force')
        \ : deepcopy(s:null_region)
endfunction
"}}}
function! s:search_surrounds(surrounds, pos, nest, timeout, ...) abort "{{{
  if a:pos[0] == s:null_pos || a:pos[1] == s:null_pos
    return deepcopy(s:null_region)
  endif

  let is_skip = get(a:000, 0, 0)
  let skip_expr = is_skip ? 's:skip(1)' : 's:skip(0)'

  call setpos('.', a:pos[1])
  let tail = s:searchpos(a:nest, a:surrounds, 0, skip_expr, a:timeout)
  if tail == s:null_coord | return deepcopy(s:null_region) | endif
  let is_tail_skipping_syntax = is_skip ? 0 : s:is_skipping_syntax(tail)

  if !a:nest
    call setpos('.', a:pos[0])
  endif

  let head = s:searchpos(a:nest, a:surrounds, 1, skip_expr, a:timeout)
  if head == s:null_coord | return deepcopy(s:null_region) | endif
  let is_head_skipping_syntax = is_skip ? 0 : s:is_skipping_syntax(head)

  if is_head_skipping_syntax && is_tail_skipping_syntax && !s:is_successive_syntax(head, tail)
    " If the syntax region is not successive, search again with skipping specific sytaxes.
    return s:search_surrounds(a:surrounds, a:pos, a:nest, a:timeout, 1)
  elseif is_head_skipping_syntax && !is_tail_skipping_syntax
    " search head which is not in specific syntaxes
    let head = s:searchpos(a:nest, a:surrounds, 1, 's:skip(1)', a:timeout)
    if head == s:null_coord | return deepcopy(s:null_region) | endif
  elseif !is_head_skipping_syntax && is_tail_skipping_syntax
    " search tail which is not in specific syntaxes
    let tail = s:searchpos(a:nest, a:surrounds, 0, 's:skip(1)', a:timeout)
    if tail == s:null_coord | return deepcopy(s:null_region) | endif
  endif

  let tail = s:get_left_pos(s:c2p(tail))
  let head = s:get_right_pos(s:c2p(head))
  return extend(deepcopy(s:null_region), {'head': head, 'tail': tail}, 'force')
endfunction
"}}}
function! s:check_pattern(region, rule) abort "{{{
  let is_matched = 1
  let timeout = g:swap#stimeoutlen
  if has_key(a:rule, 'body')
    let is_matched = s:check_body(a:rule.body, a:region, timeout)
  endif
  if is_matched && has_key(a:rule, 'surrounds')
    let is_matched = s:check_surrounds(a:rule.surrounds, a:region, timeout)
  endif
  return is_matched
endfunction
"}}}
function! s:check_body(body, region, timeout) abort "{{{
  let is_matched = 1
  let cur_pos = getpos('.')
  call setpos('.', a:region.head)
  if getpos('.')[1:2] != searchpos(a:body, 'cn', 0, a:timeout)
    let is_matched = 0
  endif
  if searchpos(a:body, 'en', 0, a:timeout) != a:region.tail[1:2]
    let is_matched = 0
  endif
  call setpos('.', cur_pos)
  return is_matched
endfunction
"}}}
function! s:check_surrounds(surrounds, region, timeout) abort "{{{
  " NOTE: s:match_surrounds does not check nesting.
  "       Maybe it is reasonable considering use cases.
  let is_matched = 1
  let cur_pos = getpos('.')
  if s:get_left_pos(a:region.head)[1:2] != searchpos(a:surrounds[0], 'cen', 0, a:timeout)
    let is_matched = 0
  endif
  if is_matched && s:get_right_pos(a:region.tail)[1:2] != searchpos(a:surrounds[1], 'bcn', 0, a:timeout)
    let is_matched = 0
  endif
  call setpos('.', cur_pos)
  return is_matched
endfunction
"}}}
function! s:searchpos(nest, pattern, is_head, skip_expr, timeout) abort  "{{{
  if a:nest
    if !a:is_head && searchpos(a:pattern[0], 'cn', line('.')) == getpos('.')[1:2]
      normal! l
    endif
    let flag = a:is_head ? 'bW' : 'cW'
    let coord = searchpairpos(a:pattern[0], '', a:pattern[1], flag, a:skip_expr, 0, a:timeout)
    if coord != s:null_coord && a:is_head
      let coord = searchpos(a:pattern[0], 'ceW', 0, a:timeout)
    endif
  else
    let coord = copy(s:null_coord)
    let flag = a:is_head ? 'beW' : 'cW'
    let pattern = a:is_head ? a:pattern[0] : a:pattern[1]
    let coord = searchpos(pattern, flag, 0, a:timeout)
    let flag = a:is_head ? 'beW' : 'W'
    while coord != s:null_coord && eval(a:skip_expr)
      let coord = searchpos(pattern, flag, 0, a:timeout)
    endwhile
  endif
  return coord
endfunction
"}}}
function! s:skip(is_skip) abort "{{{
  return a:is_skip ? s:is_skipping_syntax(getpos('.')[1:2]) : 0
endfunction
"}}}
function! s:get_left_pos(pos, ...) abort  "{{{
  call setpos('.', a:pos)
  execute printf('normal! %dh', get(a:000, 0, 1))
  return getpos('.')
endfunction
"}}}
function! s:get_right_pos(pos, ...) abort  "{{{
  call setpos('.', a:pos)
  execute printf('normal! %dl', get(a:000, 0, 1))
  return getpos('.')
endfunction
"}}}
function! s:is_skipping_syntax(coord) abort "{{{
  let syntax = s:get_displaysyntax(a:coord)
  return syntax ==# 'Constant' || syntax ==# 'String' || syntax ==# 'Comment'
endfunction
"}}}
function! s:is_successive_syntax(head, tail) abort  "{{{
  call cursor(a:head)
  let tail = s:c2p(a:tail)
  let syntax = s:get_displaysyntax(a:head)
  let is_successive = 1
  let [&virtualedit, &whichwrap] = ['', 'h,l']
  while 1
    normal! l
    let pos = getpos('.')

    if s:is_ahead(pos, tail)
      break
    endif

    if s:get_displaysyntax(pos[1:2]) !=# syntax
      let is_successive = 0
      break
    endif
  endwhile
  let [&virtualedit, &whichwrap] = ['onemore', 'h,l']
  return is_successive
endfunction
"}}}
function! s:get_displaysyntax(coord) abort  "{{{
  return synIDattr(synIDtrans(synID(a:coord[0], a:coord[1], 1)), 'name')
endfunction
"}}}
function! s:get_buf_length(region) abort  "{{{
  return s:buf_byte_len(a:region.head, a:region.tail) + 1
endfunction
"}}}
function! s:buf_byte_len(start, end) abort "{{{
  let buf_byte_len = 0
  if a:end[1] == a:start[1]
    let buf_byte_len += a:end[2] - a:start[2]
  else
    let lines = getline(a:start[1], a:end[1])
    let buf_byte_len += strlen(lines[0]) - a:start[2] + 2
    let buf_byte_len += a:end[2] - 1
    if a:end[1] - a:start[1] >= 2
      let buf_byte_len += eval(join(map(lines[1:-2], 'strlen(v:val)+1'), '+'))
    endif
  endif
  return buf_byte_len
endfunction
"}}}
function! s:c2p(coord) abort  "{{{
  return [0] + a:coord + [0]
endfunction
"}}}
" function! s:sort(list, func, ...) abort  "{{{
if s:has_patch_7_4_358
  function! s:sort(list, func, ...) abort
    return sort(a:list, a:func)
  endfunction
else
  function! s:sort(list, func, ...) abort
    " NOTE: len(a:list) is always larger than n or same.
    " FIXME: The number of item in a:list would not be large, but if there was
    "        any efficient argorithm, I would rewrite here.
    let len = len(a:list)
    let n = min([get(a:000, 0, len), len])
    for i in range(n)
      if len - 2 >= i
        let min = len - 1
        for j in range(len - 2, i, -1)
          if call(a:func, [a:list[min], a:list[j]]) >= 1
            let min = j
          endif
        endfor

        if min > i
          call insert(a:list, remove(a:list, min), i)
        endif
      endif
    endfor
    return a:list
  endfunction
endif
"}}}
function! s:compare_len(s1, s2) abort "{{{
  return a:s1.region.len - a:s2.region.len
endfunction
"}}}
function! s:compare_rules(r1, r2) abort "{{{
  let priority_r1 = get(a:r1, 'priority', 0)
  let priority_r2 = get(a:r2, 'priority', 0)
  if priority_r1 > priority_r2
    return -1
  elseif priority_r1 < priority_r2
    return 1
  else
    return 0
  endif
endfunction
"}}}
function! s:compare_idx(i1, i2) abort "{{{
  return a:i1[0] - a:i2[0]
endfunction
"}}}
function! s:get_buf_text(region, type) abort  "{{{
  " NOTE: Do *not* use operator+textobject in another textobject!
  "       For example, getting a text with the command is not appropriate.
  "         execute printf('normal! %s:call setpos(".", %s)%s""y', a:type, string(a:region.tail), "\<CR>")
  "       Because it causes confusions for the unit of dot-repeating.
  "       Use visual selection+operator as following.
  let text = ''
  let visual = [getpos("'<"), getpos("'>")]
  let reg = ['"', getreg('"'), getregtype('"')]
  try
    call setpos('.', a:region.head)
    execute 'normal! ' . a:type
    call setpos('.', a:region.tail)
    silent normal! ""y
    let text = @@
  finally
    call call('setreg', reg)
    call setpos("'<", visual[0])
    call setpos("'>", visual[1])
    return text
  endtry
endfunction
"}}}
function! s:get_assigned_region(motionwise) abort "{{{
  let region = deepcopy(s:null_region)
  let region.head = getpos("'[")
  let region.tail = getpos("']")

  if !s:is_valid_region(region, a:motionwise)
    return deepcopy(s:null_region)
  endif

  let endcol = col([region.tail[1], '$'])
  if a:motionwise ==# 'V'
    let region.head[2] = 1
    let region.tail[2] = endcol
  else
    if region.tail[2] >= endcol
      let region.tail[2] = endcol
    endif
  endif

  if !s:is_valid_region(region)
    return deepcopy(s:null_region)
  endif

  let region.len = s:get_buf_length(s:swap.region)
  return region
endfunction
"}}}
function! s:is_valid_region(region, ...) abort "{{{
  return a:region.head != s:null_pos && a:region.tail != s:null_pos
        \ && ((a:0 > 0 && a:1 ==# 'V') || s:is_ahead(a:region.tail, a:region.head))
endfunction
"}}}
function! s:is_ahead(pos1, pos2) abort  "{{{
  return a:pos1[1] > a:pos2[1] || (a:pos1[1] == a:pos2[1] && a:pos1[2] > a:pos2[2])
endfunction
"}}}
function! s:is_in_between(pos, head, tail) abort  "{{{
  return (a:pos != s:null_pos) && (a:head != s:null_pos) && (a:tail != s:null_pos)
    \  && ((a:pos[1] > a:head[1]) || ((a:pos[1] == a:head[1]) && (a:pos[2] >= a:head[2])))
    \  && ((a:pos[1] < a:tail[1]) || ((a:pos[1] == a:tail[1]) && (a:pos[2] <= a:tail[2])))
endfunction
"}}}
function! s:parse_charwise(text, rule) abort  "{{{
  let idx = 0
  let end = strlen(a:text)
  let head = 0
  let last_delimiter_tail = -1/0
  let buffer = []

  let targets = {}
  let targets.delimiter = map(copy(get(a:rule, 'delimiter', [])), '[-1, v:val, 0, "delimiter"]')
  let targets.immutable = map(copy(get(a:rule, 'immutable', [])), '[-1, v:val, 0, "immutable"]')
  let targets.braket    = map(copy(get(a:rule, 'braket', [])), '[-1, v:val, 0, "braket"]')
  let targets.quotes    = map(copy(get(a:rule, 'quotes', [])), '[-1, v:val, 0, "quotes"]')
  let targets.literal_quotes = map(copy(get(a:rule, 'literal_quotes', [])), '[-1, v:val, 0, "literal_quotes"]')
  let targets.all = targets.delimiter + targets.immutable + targets.braket + targets.quotes + targets.literal_quotes

  while idx < end
    unlet! pattern  " ugly...
    let [idx, pattern, occurence, kind] = s:shift_to_something_start(a:text, targets.all, idx)
    if idx < 0
      call s:add_buffer_text(buffer, 'item', a:text, head, idx)
      break
    else
      if kind ==# 'delimiter'
        " a delimiter is found
        " NOTE: I would like to treat zero-width delimiter as possible.
        let last_elem = get(buffer, -1, {'attr': ''})
        if idx == last_delimiter_tail && last_elem.attr ==# 'delimiter' && last_elem.string ==# ''
          " zero-width delimiter is found
          let idx += 1
          continue
        endif

        if !(head == idx && last_elem.attr ==# 'immutable')
          call s:add_buffer_text(buffer, 'item', a:text, head, idx)
        endif
        if idx == last_delimiter_tail
          " successive delimiters
          let [head, idx] = [idx, s:shift_to_delimiter_end(a:text, pattern, idx, 0)]
        else
          let [head, idx] = [idx, s:shift_to_delimiter_end(a:text, pattern, idx, 1)]
        endif
        call s:add_buffer_text(buffer, 'delimiter', a:text, head, idx)
        if idx < 0 || idx >= end
          break
        else
          let head = idx
          let last_delimiter_tail = idx
        endif
      elseif kind ==# 'braket'
        " a bra is found
        let idx = s:shift_to_braket_end(a:text, pattern, targets.quotes, idx)
        if idx < 0 || idx >= end
          call s:add_buffer_text(buffer, 'item', a:text, head, idx)
          break
        endif
      elseif kind ==# 'quotes'
        " a quote is found
        let idx = s:shift_to_quote_end(a:text, pattern, idx)
        if idx < 0 || idx >= end
          call s:add_buffer_text(buffer, 'item', a:text, head, idx)
          break
        endif
      elseif kind ==# 'literal_quotes'
        " an solid quote (non-escaped quote) is found
        let idx = s:shift_to_solidquote_end(a:text, pattern, idx)
        if idx < 0 || idx >= end
          call s:add_buffer_text(buffer, 'item', a:text, head, idx)
          break
        endif
      else
        " an immutable string is found
        if idx != head
          call s:add_buffer_text(buffer, 'item', a:text, head, idx)
        endif
        let [head, idx] = [idx, s:shift_to_immutable_end(a:text, pattern, idx)]
        call s:add_buffer_text(buffer, 'immutable', a:text, head, idx)
        if idx < 0 || idx >= end
          break
        else
          let head = idx
        endif
      endif
    endif
  endwhile

  if buffer != [] && buffer[-1]['attr'] ==# 'delimiter'
    " If the last item is a delimiter, put empty item at the end.
    call s:add_buffer_text(buffer, 'item', a:text, idx, idx)
  endif

  return buffer
endfunction
"}}}
function! s:parse_linewise(text, rule) abort  "{{{
  let buffer = []
  let items  = map(split(a:text, "\n", 1), '{"attr": "item", "string": v:val}')
  call remove(items, -1)
  for item in items
    let buffer += [item, {'attr': 'delimiter', 'string': "\n"}]
  endfor
  return buffer
endfunction
"}}}
function! s:parse_blockwise(text, rule) abort  "{{{
  let buffer = []
  let items  = map(split(a:text, "\n", 1), '{"attr": "item", "string": v:val}')
  for item in items
    let buffer += [item, {'attr': 'delimiter', 'string': "\n"}]
  endfor
  call remove(buffer, -1)
  return buffer
endfunction
"}}}
function! s:scan(text, target, idx) abort  "{{{
  let idx = a:target[0]
  if idx < a:idx
    let kind = a:target[3]
    if kind ==# 'delimiter' || kind ==# 'immutable'
      " delimiter or immutable
      let a:target[0:2] = s:match(a:text, a:target[0:2], a:idx, 1)
    else
      " braket or quotes
      let pair = a:target[1]
      let a:target[0] = stridx(a:text, pair[0], a:idx)
    endif
  endif
  return a:target
endfunction
"}}}
function! s:shift_to_something_start(text, targets, idx) abort  "{{{
  let result = [-1, '', 0, '']
  call map(a:targets, 's:scan(a:text, v:val, a:idx)')
  call filter(a:targets, 'v:val[0] > -1')
  if a:targets != []
    call s:sort(a:targets, 's:compare_idx', 1)
    let result = a:targets[0]
  endif
  return result
endfunction
"}}}
function! s:shift_to_delimiter_end(text, delimiter, idx, current_match) abort  "{{{
  return s:matchend(a:text, [0, a:delimiter, 0], a:idx, a:current_match)[0]
endfunction
"}}}
function! s:shift_to_braket_end(text, pair, quotes, idx) abort  "{{{
  let end = strlen(a:text)
  let idx = s:stridxend(a:text, a:pair[0], a:idx)

  let depth = 0
  while 1
    let lastidx = idx
    let ket = s:stridxend(a:text, a:pair[1], idx)
    " do not take into account 'zero width' braket
    if ket == lastidx
      let idx += 1
      continue
    endif

    if ket < 0
      let idx = -1
    elseif ket >= end
      let idx = end
    else
      let bra = s:stridxend(a:text, a:pair[0], idx)
      if bra == lastidx
        let bra = s:stridxend(a:text, a:pair[0], idx+1)
      endif

      call filter(a:quotes, 'v:val[0] > -1')
      if a:quotes != []
        let quote = s:shift_to_something_start(a:text, a:quotes, idx)
      else
        let quote = [-1]
      endif

      let list_idx = filter([ket, bra, quote[0]], 'v:val > -1')
      if list_idx == []
        let idx = -1
      else
        let idx = min(list_idx)
        if idx == ket
          let depth -= 1
        elseif idx == bra
          let depth += 1
        else
          let idx = s:shift_to_quote_end(a:text, quote[1], quote[0])
          if idx > end
            let idx = -1
          endif
        endif
      endif
    endif

    if idx < 0 || idx >= end || depth < 0
      break
    endif
  endwhile
  return idx
endfunction
"}}}
function! s:shift_to_quote_end(text, pair, idx) abort  "{{{
  let idx = s:stridxend(a:text, a:pair[0], a:idx)
  let end = strlen(a:text)
  let quote = 0

  while 1
    let quote = s:stridxend(a:text, a:pair[1], idx)
    " do not take into account 'zero width' quote
    if quote == idx
      let idx += 1
      continue
    endif

    if quote < 0
      let idx = -1
    else
      let idx = quote
      if idx > 1 && idx <= end && stridx(&quoteescape, a:text[idx-2]) > -1
        let n = strchars(matchstr(a:text[: idx-2], printf('%s\+$', s:escape(a:text[idx-2]))))
        if n%2 == 1
          continue
        endif
      endif
    endif
    break
  endwhile
  return idx
endfunction
"}}}
function! s:shift_to_solidquote_end(text, pair, idx) abort  "{{{
  let idx = s:stridxend(a:text, a:pair[0], a:idx)
  let literal_quote = s:stridxend(a:text, a:pair[1], idx)
  if literal_quote == idx
    let literal_quote = s:stridxend(a:text, a:pair[1], idx+1)
  endif
  return literal_quote
endfunction
"}}}
function! s:shift_to_immutable_end(text, immutable, idx) abort  "{{{
  " NOTE: Zero-width immutable would not be considered.
  return s:matchend(a:text, [0, a:immutable, 0], a:idx, 0)[0]
endfunction
"}}}
function! s:add_buffer_text(buffer, attr, text, head, next_head) abort  "{{{
  " NOTE: Zero-width 'item', 'delimiter' and 'immutable' should be possible.
  "       If it is not favolable, I should control outside of this function.
  if a:head >= 0
    if a:next_head < 0
      let string = a:text[a:head :]
    elseif a:next_head <= a:head
      let string = ''
    else
      let string = a:text[a:head : a:next_head-1]
    endif
    call add(a:buffer, {'attr': a:attr, 'string': string})
  endif
endfunction
"}}}
function! s:match(string, target, idx, ...) abort "{{{
  " NOTE: current_match is like 'c' flag in search()
  let current_match = get(a:000, 0, 1)

  " NOTE: Because s:match_by_occurence() is heavy, it is used only when
  "       a pattern includes '\zs', '\@<=' and '\@<!'.
  if match(a:target[1], '[^\\]\%(\\\\\)*\\zs') > -1 || match(a:target[1], '[^\\]\%(\\\\\)*\\@\d*<[!=]') > -1
    return s:match_by_occurence(a:string, a:target, a:idx, current_match)
  else
    return s:match_by_idx(a:string, a:target, a:idx, current_match)
  endif
endfunction
"}}}
function! s:match_by_idx(string, target, idx, current_match) abort  "{{{
  let [idx, pattern, occurrence] = a:target
  let idx = match(a:string, pattern, a:idx)
  if !a:current_match && idx == a:idx
    let idx = match(a:string, pattern, a:idx, 2)
  endif
  return [idx, pattern, occurrence]
endfunction
"}}}
function! s:match_by_occurence(string, target, idx, current_match) abort  "{{{
  let [idx, pattern, occurrence] = a:target
  if a:idx < idx
    let occurrence = 0
  endif
  while 1
    let idx = match(a:string, pattern, 0, occurrence + 1)
    if idx >= 0
      let occurrence += 1
      if (a:current_match && idx < a:idx) || (!a:current_match && idx <= a:idx)
        continue
      endif
    endif
    break
  endwhile
  return [idx, pattern, occurrence]
endfunction
"}}}
function! s:matchend(string, target, idx, ...) abort "{{{
  " NOTE: current_match is like 'c' flag in search()
  let current_match = get(a:000, 0, 1)

  " NOTE: Because s:match_by_occurence() is heavy, it is used only when
  "       a pattern includes '\zs', '\@<=' and '\@<!'.
  if match(a:target[1], '[^\\]\%(\\\\\)*\\zs') > -1 || match(a:target[1], '[^\\]\%(\\\\\)*\\@\d*<[!=]') > -1
    return s:matchend_by_occurence(a:string, a:target, a:idx, current_match)
  else
    return s:matchend_by_idx(a:string, a:target, a:idx, current_match)
  endif
endfunction
"}}}
function! s:matchend_by_occurence(string, target, idx, current_match) abort "{{{
  let [idx, pattern, occurrence] = a:target
  if a:idx < idx
    let occurrence = 0
  endif
  while 1
    let idx = matchend(a:string, pattern, 0, occurrence + 1)
    if idx >= 0
      let occurrence += 1
      if (a:current_match && idx < a:idx) || (!a:current_match && idx <= a:idx)
        continue
      endif
    endif
    break
  endwhile
  return [idx, pattern, occurrence]
endfunction
"}}}
function! s:matchend_by_idx(string, target, idx, current_match) abort "{{{
  let [idx, pattern, occurrence] = a:target
  let idx = matchend(a:string, pattern, a:idx)
  if !a:current_match && idx == a:idx
    let idx = matchend(a:string, pattern, a:idx, 2)
  endif
  return [idx, pattern, occurrence]
endfunction
"}}}
function! s:stridxend(heystack, needle, ...) abort  "{{{
  let start = get(a:000, 0, 0)
  let idx = stridx(a:heystack, a:needle, start)
  return idx >= 0 ? idx + strlen(a:needle) : idx
endfunction
"}}}
function! s:escape(string) abort  "{{{
  return escape(a:string, '~"\.^$[]*')
endfunction
"}}}
function! s:sharp(curpos, buffer) abort  "{{{
  let sharp = 0
  if a:buffer.all != []
    if s:is_ahead(a:buffer.all[0].region.head, a:curpos)
      let sharp = 1
    else
      for text in a:buffer.items
        let sharp += 1
        if s:is_ahead(text.region.tail, a:curpos)
          break
        endif
      endfor
      if sharp > len(a:buffer.items)
        let sharp = len(a:buffer.items)
      endif
    endif
  endif
  return sharp
endfunction
"}}}
function! s:hat(buffer) abort "{{{
  let hat = 0
  for text in a:buffer.items
    let hat += 1
    if text.string !=# ''
      break
    endif
  endfor
  return hat
endfunction
"}}}
function! s:dollar(buffer) abort  "{{{
  return len(a:buffer.items)
endfunction
"}}}
function! s:substitute_symbol(order, symbol, symbol_idx) abort "{{{
  let symbol = s:escape(a:symbol)
  return map(a:order, 'type(v:val) == s:type_str ? substitute(v:val, symbol, a:symbol_idx, "") : v:val')
endfunction
"}}}
function! s:extractall(dict) abort "{{{
  " remove all keys and values of dictionary
  " return the copy of original dict
  let copy_dict = copy(a:dict)
  call filter(a:dict, 1)
  return copy_dict
endfunction
"}}}
function! s:address_charwise(buffer, start) abort  "{{{
  let pos = copy(a:start)
  for text in a:buffer
    if stridx(text.string, "\n") < 0
      let len = strlen(text.string)
      let text.region.len  = len
      let text.region.head = copy(pos)
      let pos[2] += len
      let text.region.tail = copy(pos)
    else
      let lines = split(text.string, '\n\zs', 1)
      let text.region.len  = strlen(text.string)
      let text.region.head = copy(pos)
      let pos[1] += len(lines) - 1
      let pos[2] = strlen(lines[-1]) + 1
      let text.region.tail = copy(pos)
    endif
  endfor
  return a:buffer
endfunction
"}}}
function! s:address_linewise(buffer, start) abort  "{{{
  let lnum = a:start[1]
  for text in a:buffer
    if text.attr ==# 'item'
      let len = strlen(text.string)
      let text.region.len  = len
      let text.region.head = [0, lnum, 1, 0]
      let text.region.tail = [0, lnum, len+1, 0]
    elseif text.attr ==# 'delimiter'
      let text.region.len = 1
      let text.region.head = [0, lnum, col([lnum, '$']), 0]
      let text.region.tail = [0, lnum+1, 1, 0]
      let lnum += 1
    endif
  endfor
  return a:buffer
endfunction
"}}}
function! s:address_blockwise(buffer, start) abort  "{{{
  let view = winsaveview()
  let lnum = a:start[1]
  let virtcol = a:start[2]
  for text in a:buffer
    if text.attr ==# 'item'
      let col = s:virtcol2col(lnum, virtcol)
      let len = strlen(text.string)
      let text.region.len  = len
      let text.region.head = [0, lnum, col, 0]
      let text.region.tail = [0, lnum, col+len, 0]
    elseif text.attr ==# 'delimiter'
      let text.region.len = 0
      let text.region.head = [0, lnum, col+len, 0]
      let text.region.tail = [0, lnum, col+len, 0]
      let lnum += 1
    endif
  endfor
  call winrestview(view)
  return a:buffer
endfunction
"}}}
function! s:virtcol2col(lnum, virtcol) abort  "{{{
  call cursor(a:lnum, 1)
  execute printf('normal! %d|', a:virtcol)
  return col('.')
endfunction
"}}}
" function! s:matchaddpos(group, pos) abort "{{{
if s:has_patch_7_4_362
  function! s:matchaddpos(group, pos) abort
    return [matchaddpos(a:group, a:pos)]
  endfunction
else
  function! s:matchaddpos(group, pos) abort
    let id_list = []
    for pos in a:pos
      if len(pos) == 1
        let id_list += [matchadd(a:group, printf('\%%%dl', pos[0]))]
      else
        let id_list += [matchadd(a:group, printf('\%%%dl\%%>%dc.*\%%<%dc', pos[0], pos[1]-1, pos[1]+pos[2]))]
      endif
    endfor
    return id_list
  endfunction
endif
"}}}
function! s:matchdelete(id) abort "{{{
  if matchdelete(a:id) == -1
    return a:id
  endif
  return 0
endfunction
"}}}
function! s:clear_highlight_all(buffer) abort "{{{
  " NOTE: This function itself does not redraw.
  if !g:swap#highlight
    return
  endif

  for text in a:buffer
    if text.highlightid != []
      call text.clear_highlight()
    endif
  endfor
endfunction
"}}}
function! s:displace_options(...) abort  "{{{
  let [ virtualedit,  whichwrap,  selection] = [&virtualedit, &whichwrap, &selection]
  let [&virtualedit, &whichwrap, &selection] = ['onemore', 'h,l', 'inclusive']
  if a:0 > 0
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
  else
    return [virtualedit, whichwrap, selection]
  endif
endfunction
"}}}
function! s:restore_options(virtualedit, whichwrap, selection, ...) abort "{{{
  let [&virtualedit, &whichwrap, &selection] = [a:virtualedit, a:whichwrap, a:selection]
  if a:0 > 1
    let cursor     = a:1
    let cursorline = a:2
    if s:has_gui_running
      set guicursor&
      let &guicursor = cursor
    else
      let &t_ve = cursor
    endif
    let &l:cursorline = cursorline
  endif
endfunction
"}}}
function! s:keymap(noremap, lhs, rhs) abort  "{{{
  let g:swap#keymappings = get(g:, 'swap#keymappings', g:swap#default_keymappings)
  let keymap = {'noremap': a:noremap, 'input': a:lhs, 'output': a:rhs}
  let g:swap#keymappings += [keymap]
endfunction
"}}}

" clock object  "{{{
function! s:clock_start() dict abort  "{{{
  if self.started
    if self.paused
      let self.losstime += str2float(reltimestr(reltime(self.pause_at)))
      let self.paused = 0
    endif
  else
    if s:has_reltime_and_float
      let self.zerotime = reltime()
      let self.started  = 1
    endif
  endif
endfunction
"}}}
function! s:clock_pause() dict abort "{{{
  let self.pause_at = reltime()
  let self.paused   = 1
endfunction
"}}}
function! s:clock_elapsed() dict abort "{{{
  if self.started
    let total = str2float(reltimestr(reltime(self.zerotime)))
    return floor((total - self.losstime)*1000)
  else
    return 0
  endif
endfunction
"}}}
function! s:clock_stop() dict abort  "{{{
  let self.started  = 0
  let self.paused   = 0
  let self.losstime = 0
endfunction
"}}}
let s:clock = {
      \   'started' : 0,
      \   'paused'  : 0,
      \   'losstime': 0,
      \   'zerotime': reltime(),
      \   'pause_at': reltime(),
      \   'start'   : function('s:clock_start'),
      \   'pause'   : function('s:clock_pause'),
      \   'elapsed' : function('s:clock_elapsed'),
      \   'stop'    : function('s:clock_stop'),
      \ }
"}}}

" interface object  "{{{
function! s:interface_start() dict abort "{{{
  let self.phase = 0
  let self.order = ['', '']
  let self.idx.current = -1
  let self.idx.last_current = -1
  let self.idx.selected = -1
  let self.idx.end = len(self.buffer.items) - 1

  let idx = self.buffer.symbols['#'] - 1
  if self.buffer.items[idx].string ==# ''
    let idx = s:move_next_skipping_blank(self.buffer.items, idx)
  endif

  call self.set_current(idx)
  call self.highlight()
  call self.echo()
  redraw
  while self.phase < 2
    let self.escaped = 0
    let key_map = deepcopy(get(g:, 'swap#keymappings', g:swap#default_keymappings))
    let key = s:query(key_map)
    if has_key(key, 'output')
      call self.normal(key)
      call self.revise_cursor_pos()
      redraw
    endif
    if self.escaped
      let self.order = []
      break
    endif
  endwhile
  call self.clear_highlight()
  return self.order
endfunction
"}}}
function! s:interface_echo() dict abort "{{{
  if self.phase == 0 || self.phase == 1
    let max_len = &columns - 25
    let message = []

    for order in self.history[: -1*(self.undolevel+1)]
      let message += [[order[0], g:swap#hl_itemnr]]
      let message += [[g:swap#arrow, g:swap#hl_arrow]]
      let message += [[order[1], g:swap#hl_itemnr]]
      let message += [[', ', 'NONE']]
    endfor
    if self.phase == 0
      if self.order[0] !=# ''
        let message += [[self.order[0], self.idx.is_valid(self.order[0]) ? g:swap#hl_itemnr : 'ErrorMsg']]
      else
        if message != []
          call remove(message, -1)
        endif
      endif
    elseif self.phase == 1
      if self.order[1] !=# ''
        let message += [[self.order[0], g:swap#hl_itemnr]]
        let message += [[g:swap#arrow, g:swap#hl_arrow]]
        let message += [[self.order[1], self.idx.is_valid(self.order[1]) ? g:swap#hl_itemnr : 'ErrorMsg']]
      else
        let message += [[self.order[0], g:swap#hl_itemnr]]
        let message += [[g:swap#arrow, g:swap#hl_arrow]]
      endif
    endif

    if message != []
      let len = eval(join(map(copy(message), 'strwidth(v:val[0])'), '+'))
      if len > max_len
        while len > max_len-1
          let mes  = remove(message, 0)
          let len -= strwidth(mes[0])
        endwhile
        if len < 0
          let mes = [mes[0][len :], mes[1]]
          call insert(message, mes)
        endif
        let precedes = matchstr(&listchars, 'precedes:\zs.\ze')
        let precedes = precedes ==# '' ? '<' : precedes
        call insert(message, [precedes, 'SpecialKey'])
      endif
    endif

    echohl ModeMsg
    echo 'Swap mode: '
    echohl NONE
    for mes in message
      call self.echon(mes[0], mes[1])
    endfor
  endif
endfunction
"}}}
function! s:interface_echon(str, ...) dict abort "{{{
  let hl = get(a:000, 0, 'NONE')
  execute 'echohl ' . hl
  echon a:str
  echohl NONE
endfunction
"}}}
function! s:interface_normal(key) dict abort "{{{
  if has_key(a:key, 'noremap') && a:key.noremap
    execute 'normal! ' . a:key.output
  else
    execute 'normal ' . a:key.output
  endif
endfunction
"}}}
function! s:interface_revise_cursor_pos() dict abort  "{{{
  let curpos = getpos('.')
  if self.idx.is_valid(self.idx.current)
    let item = self.buffer.items[self.idx.current]
    if s:is_in_between(curpos, item.region.head, item.region.tail) && curpos != item.region.tail
      " no problem!
      return
    endif
  endif

  let head = self.buffer.items[0].region.head
  let tail = self.buffer.items[self.idx.end].region.tail
  let self.idx.last_current = self.idx.current
  if s:is_ahead(head, curpos)
    let self.idx.current = -1
  elseif curpos == tail || s:is_ahead(curpos, tail)
    let self.idx.current = self.idx.end + 1
  else
    let self.idx.current = s:sharp(curpos, self.buffer) - 1
  endif
  call self.update_highlight()
endfunction
"}}}
function! s:interface_add_history() dict abort  "{{{
  call self.truncate_history()
  call add(self.history, self.order)
  return self.history
endfunction
"}}}
function! s:interface_truncate_history() dict abort  "{{{
  if self.undolevel
    let endidx = -1*self.undolevel
    call remove(self.history, endidx, -1)
    let self.undolevel = 0
  endif
  return self.history
endfunction
"}}}
function! s:interface_set_current(idx) dict abort "{{{
  call self.buffer.items[a:idx].cursor()

  " update side-scrolling
  " FIXME: Any standard way?
  if s:has_patch_7_4_311
    call winrestview({})
  endif

  let self.idx.last_current = self.idx.current
  let self.idx.current = a:idx
endfunction
"}}}
function! s:interface_highlight() dict abort "{{{
  if !g:swap#highlight
    return
  endif

  let idx = 0
  for item in self.buffer.items
    if idx == self.idx.current
      call item.highlight('SwapCurrentItem')
    else
      call item.highlight('SwapItem')
    endif
    let idx += 1
  endfor
endfunction
"}}}
function! s:interface_clear_highlight() dict abort  "{{{
  call s:clear_highlight_all(self.buffer.items)
endfunction
"}}}
function! s:interface_update_highlight() dict abort  "{{{
  if !g:swap#highlight
    return
  endif

  let items = self.buffer.items
  if self.idx.is_valid(self.idx.last_current)
    call items[self.idx.last_current].clear_highlight()
    call items[self.idx.last_current].highlight('SwapItem')
  endif
  if self.idx.is_valid(self.idx.selected)
    call items[self.idx.selected].clear_highlight()
    call items[self.idx.selected].highlight('SwapSelectedItem')
  endif
  if self.idx.is_valid(self.idx.current)
    call items[self.idx.current].clear_highlight()
    call items[self.idx.current].highlight('SwapCurrentItem')
  endif
endfunction
"}}}
function! s:interface_goto_phase(phase) dict abort "{{{
  " NOTE: If a negative value n is given, this func proceed phase to abs(n)
  "       without operating side-processes.
  let self.phase = abs(a:phase)
  if a:phase == 1
    let self.idx.selected = str2nr(self.order[0]) - 1
    call self.echo()
  elseif a:phase == 2
    call self.add_history()
  endif
endfunction
"}}}
function! s:interface_exit() dict abort  "{{{
  call self.goto_phase(-2)
endfunction
"}}}
function! s:interface_undo_order() dict abort  "{{{
  let prev_order = self.history[-1*(self.undolevel+1)]
  return [prev_order[1], prev_order[0]]
endfunction
"}}}
function! s:interface_redo_order() dict abort  "{{{
  return copy(self.history[-1*self.undolevel])
endfunction
"}}}
function! s:interface_idx_is_valid(idx) dict abort  "{{{
  if type(a:idx) == s:type_num
    return a:idx >= 0 && a:idx <= self.end
  elseif type(a:idx) == s:type_str
    return str2nr(a:idx) >= 0 && str2nr(a:idx) <= self.end
  else
    return 0
  endif
endfunction
"}}}
function! s:query(key_map) abort "{{{
  let key_map = insert(a:key_map, {'input': "\<Esc>", 'output': "\<Plug>(swap-mode-Esc)"})   " for safety
  let clock   = deepcopy(s:clock)
  let timeoutlen = g:swap#timeoutlen

  let input = ''
  let last_compl_match = ['', []]
  while key_map != []
    let c = getchar(0)
    if empty(c)
      if clock.started && timeoutlen > 0 && clock.elapsed() > timeoutlen
        let [input, key_map] = last_compl_match
        break
      else
        sleep 20m
        continue
      endif
    endif

    let c = type(c) == s:type_num ? nr2char(c) : c
    let input .= c

    " check forward match
    let n_fwd = len(filter(key_map, 's:is_input_matched(v:val, input, 0)'))

    " check complete match
    let n_comp = len(filter(copy(key_map), 's:is_input_matched(v:val, input, 1)'))
    if n_comp
      if len(key_map) == n_comp
        break
      else
        call clock.stop()
        call clock.start()
        let last_compl_match = [input, copy(key_map)]
      endif
    else
      if clock.started && !n_fwd
        let [input, key_map] = last_compl_match
        break
      endif
    endif
  endwhile
  call clock.stop()

  if filter(key_map, 's:is_input_matched(v:val, input, 1)') != []
    let key_seq = key_map[-1]
  else
    let key_seq = {}
  endif
  return key_seq
endfunction
"}}}
function! s:is_input_matched(candidate, input, flag) abort "{{{
  if !has_key(a:candidate, 'output') || !has_key(a:candidate, 'input')
    return 0
  elseif !a:flag && a:input ==# ''
    return 1
  endif

  let candidate = deepcopy(a:candidate)

  " If a:flag == 0, check forward match. Otherwise, check complete match.
  if a:flag
    return a:input ==# a:candidate.input
  else
    let idx = strlen(a:input) - 1
    return a:input ==# a:candidate.input[: idx]
  endif
endfunction
"}}}
function! s:move_prev_skipping_blank(items, current) abort  "{{{
  " skip empty items
  let idx = a:current - 1
  while idx >= 0
    if a:items[idx].string !=# ''
      break
    endif
    let idx -= 1
  endwhile
  return idx < 0 ? a:current : idx
endfunction
"}}}
function! s:move_next_skipping_blank(items, current) abort  "{{{
  " skip empty items
  let idx = a:current + 1
  let end = len(a:items) - 1
  while idx <= end
    if a:items[idx].string !=# ''
      break
    endif
    let idx += 1
  endwhile
  return idx > end ? a:current : idx
endfunction
"}}}

" NOTE: Function list
"    {0~9} : Input {0~9} to specify an item.
"    CR    : Fix the input number. If nothing has been input, fix to the item under the cursor.
"    BS    : Erase the previous input.
"    undo  : Undo the current order.
"    redo  : Redo the previous order.
"    current : Fix to the item under the cursor.
"    move_prev : Move to the previous item.
"    move_next : Move to the next item.
"    swap_prev : Swap the current item with the previous item.
"    swap_next : Swap the current item with the next item.
function! s:interface_key_nr(nr) dict abort  "{{{
  if self.phase == 0 || self.phase == 1
    let self.order[self.phase] .= a:nr
    call self.echo()
  endif
endfunction
"}}}
function! s:interface_key_CR() dict abort  "{{{
  if get(self.order, self.phase, '') ==# ''
    call self.key_current()
  else
    call self.key_fix_nr()
  endif
endfunction
"}}}
function! s:interface_key_BS() dict abort  "{{{
  if self.phase == 0
    if self.order[0] !=# ''
      let self.order[0] = self.order[0][0:-2]
      call self.echo()
    endif
  elseif self.phase == 1
    if self.order[1] !=# ''
      let self.order[1] = self.order[1][0:-2]
    else
      let self.order[0] = self.order[0][0:-2]
      call self.goto_phase(0)
      let self.idx.selected = -1
      call self.update_highlight()
    endif
    call self.echo()
  endif
endfunction
"}}}
function! s:interface_key_undo() dict abort "{{{
  if self.phase == 0 || self.phase == 1
    if len(self.history) > self.undolevel
      let self.order = self.undo_order()
      let self.undolevel += 1
      call self.exit()
    endif
  endif
endfunction
"}}}
function! s:interface_key_redo() dict abort "{{{
  if self.phase == 0 || self.phase == 1
    if self.undolevel
      let self.order = self.redo_order()
      let self.undolevel -= 1
      call self.exit()
    endif
  endif
endfunction
"}}}
function! s:interface_key_current() dict abort "{{{
  if self.phase == 0
    let self.order[0] = string(self.idx.current) + 1
    call self.goto_phase(1)
  elseif self.phase == 1
    let self.order[1] = string(self.idx.current) + 1
    call self.goto_phase(2)
  endif
endfunction
"}}}
function! s:interface_key_fix_nr() dict abort "{{{
  if self.phase == 0
    let idx = str2nr(self.order[self.phase]) - 1
    if self.idx.is_valid(idx)
      call self.set_current(idx)
      call self.goto_phase(1)
      call self.update_highlight()
    endif
  elseif self.phase == 1
    let idx = str2nr(self.order[self.phase]) - 1
    if self.idx.is_valid(idx)
      call self.goto_phase(2)
    else
      call self.echo()
    endif
  endif
endfunction
"}}}
function! s:interface_key_move_prev() dict abort  "{{{
  if self.phase == 0 || self.phase == 1
    if self.idx.current > 0
      let idx = s:move_prev_skipping_blank(self.buffer.items, min([self.idx.current, self.idx.end+1]))
      call self.set_current(idx)
      call self.update_highlight()
    endif
  endif
endfunction
"}}}
function! s:interface_key_move_next() dict abort  "{{{
  if self.phase == 0 || self.phase == 1
    if self.idx.current < self.idx.end
      let idx = s:move_next_skipping_blank(self.buffer.items, max([-1, self.idx.current]))
      call self.set_current(idx)
      call self.update_highlight()
    endif
  endif
endfunction
"}}}
function! s:interface_key_swap_prev() dict abort  "{{{
  if self.phase == 0 || self.phase == 1
    if self.idx.current > 0 && self.idx.current <= self.idx.end
      let self.order = [self.idx.current+1, self.idx.current]
      call self.goto_phase(2)
    endif
  endif
endfunction
"}}}
function! s:interface_key_swap_next() dict abort  "{{{
  if self.phase == 0 || self.phase == 1
    if self.idx.current >= 0 && self.idx.current < self.idx.end
      let self.order = [self.idx.current+1, self.idx.current+2]
      call self.goto_phase(2)
    endif
  endif
endfunction
"}}}

function! swap#swapmode_key_nr(nr) abort  "{{{
  if exists('s:interface')
    call s:interface.key_nr(a:nr)
  endif
endfunction
"}}}
function! swap#swapmode_key_CR() abort  "{{{
  if exists('s:interface')
    call s:interface.key_CR()
  endif
endfunction
"}}}
function! swap#swapmode_key_BS() abort  "{{{
  if exists('s:interface')
    call s:interface.key_BS()
  endif
endfunction
"}}}
function! swap#swapmode_key_undo() abort  "{{{
  if exists('s:interface')
    call s:interface.key_undo()
  endif
endfunction
"}}}
function! swap#swapmode_key_redo() abort  "{{{
  if exists('s:interface')
    call s:interface.key_redo()
  endif
endfunction
"}}}
function! swap#swapmode_key_current() abort  "{{{
  if exists('s:interface')
    call s:interface.key_current()
  endif
endfunction
"}}}
function! swap#swapmode_key_fix_nr() abort  "{{{
  if exists('s:interface')
    call s:interface.key_fix_nr()
  endif
endfunction
"}}}
function! swap#swapmode_key_move_prev() abort  "{{{
  if exists('s:interface')
    call s:interface.key_move_prev()
  endif
endfunction
"}}}
function! swap#swapmode_key_move_next() abort  "{{{
  if exists('s:interface')
    call s:interface.key_move_next()
  endif
endfunction
"}}}
function! swap#swapmode_key_swap_prev() abort  "{{{
  if exists('s:interface')
    call s:interface.key_swap_prev()
  endif
endfunction
"}}}
function! swap#swapmode_key_swap_next() abort  "{{{
  if exists('s:interface')
    call s:interface.key_swap_next()
  endif
endfunction
"}}}
function! swap#swapmode_key_echo() abort  "{{{
  if exists('s:interface')
    call s:interface.echo()
  endif
endfunction
"}}}
function! swap#swapmode_key_ESC() abort  "{{{
  if exists('s:interface')
    call s:interface.echo()
    let s:interface.escaped = 1
  endif
endfunction
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

let s:interface_prototype = {
      \   'phase': 0,
      \   'order': ['', ''],
      \   'idx'  : {
      \     'current': -1,
      \     'end'    : -1,
      \     'last_current': -1,
      \     'selected': -1,
      \     'is_valid': function('s:interface_idx_is_valid'),
      \   },
      \   'buffer' : {},
      \   'escaped': 0,
      \   'history': [],
      \   'undolevel': 0,
      \   'start': function('s:interface_start'),
      \   'echo' : function('s:interface_echo'),
      \   'echon': function('s:interface_echon'),
      \   'normal': function('s:interface_normal'),
      \   'revise_cursor_pos': function('s:interface_revise_cursor_pos'),
      \   'add_history' : function('s:interface_add_history'),
      \   'truncate_history': function('s:interface_truncate_history'),
      \   'set_current': function('s:interface_set_current'),
      \   'highlight': function('s:interface_highlight'),
      \   'clear_highlight': function('s:interface_clear_highlight'),
      \   'update_highlight': function('s:interface_update_highlight'),
      \   'goto_phase': function('s:interface_goto_phase'),
      \   'exit': function('s:interface_exit'),
      \   'undo_order': function('s:interface_undo_order'),
      \   'redo_order': function('s:interface_redo_order'),
      \   'key_nr': function('s:interface_key_nr'),
      \   'key_CR': function('s:interface_key_CR'),
      \   'key_BS': function('s:interface_key_BS'),
      \   'key_undo': function('s:interface_key_undo'),
      \   'key_redo': function('s:interface_key_redo'),
      \   'key_current': function('s:interface_key_current'),
      \   'key_fix_nr': function('s:interface_key_fix_nr'),
      \   'key_move_prev': function('s:interface_key_move_prev'),
      \   'key_move_next': function('s:interface_key_move_next'),
      \   'key_swap_prev': function('s:interface_key_swap_prev'),
      \   'key_swap_next': function('s:interface_key_swap_next'),
      \ }
"}}}

" swap object "{{{
function! s:swap_search(timeout) dict abort "{{{
  let has_body      = has_key(self.rule, 'body')
  let has_surrounds = has_key(self.rule, 'surrounds')

  if has_body
    if self.region == s:null_region
      let pos = copy(self.curpos)
      let self.region = s:search_body(self.rule.body, pos, a:timeout)
      if self.region != s:null_region
        let self.region.len = s:get_buf_length(self.region)
      endif
    else
      let self.region = deepcopy(s:null_region)
    endif
  elseif has_surrounds
    let nest = get(self.rule.surrounds, -1, 0)
    if self.region == s:null_region
      let pos = [self.curpos, self.curpos]
    else
      let pos = s:get_outer_pos(self.rule.surrounds, self.region)
    endif
    let self.region = s:search_surrounds(self.rule.surrounds, pos, nest, a:timeout)
    if self.region != s:null_region
      let self.region.len = s:get_buf_length(self.region)
    endif
  endif
endfunction
"}}}
function! s:swap_verify(...) dict abort "{{{
  " Check whether the region matches with the conditions to treat as the target.
  " NOTE: The conditions are the following three.
  "       1. Include two items at least.
  "       2. Not less than one of the item is not empty.
  "       3. Include one delimiter at least.
  if !(s:is_valid_region(self.region, self.motionwise)
        \ && (get(a:000, 0, 0) == 0 || s:check_pattern(self.region, self.rule)))
    return 0
  endif

  let text = s:get_buf_text(self.region, self.motionwise)
  call self.parse(text)

  let cond1 = len(self.buffer.items) >= 2
  let cond2 = filter(copy(self.buffer.items), 'v:val.string !=# ""') != []
  let cond3 = filter(copy(self.buffer.all), 'v:val.attr ==# "delimiter"') != []
  if cond1 && cond2 && cond3
    return 1
  else
    return 0
  endif
endfunction
"}}}
function! s:swap_parse(text) dict abort "{{{
  " return a list of dictionaries which have two keys at least, attr and string.
  "   attr   : 'item' or 'delimiter' or 'immutable'.
  "            'item' means that the string is an item reordered.
  "            'delimiter' means that the string is an item for separation. It would not be regarded as an item reordered.
  "            'immutable' is not an 'item' and not a 'delimiter'. It is a string which should not be changed.
  "   string : The value is the string as 'item' or 'delimiter' or 'immutable'.
  " For instance,
  "   'foo,bar' is parsed to [{'attr': 'item', 'string': 'foo'}, {'attr': 'delimiter', 'string': ','}, {'attr': 'item': 'string': 'bar'}]
  " In case that motionwise ==# 'V' or "\<C-v>", delimiter string should be "\n".
  let motionwise = self.motionwise ==# 'V'      ? 'line'
               \ : self.motionwise ==# "\<C-v>" ? 'block'
               \ : 'char'
  let self.buffer.all = s:parse_{motionwise}wise(a:text, self.rule)
  let self.buffer.items = filter(copy(self.buffer.all), 'v:val.attr ==# "item"')
  let self.buffer.delimiters = filter(copy(self.buffer.all), 'v:val.attr ==# "delimiter"')

  " Add tools
  let tools = {
        \   'cursor': function('s:item_cursor'),
        \   'highlight': function('s:item_highlight'),
        \   'clear_highlight': function('s:item_clear_highlight'),
        \   'highlightid': [],
        \ }
  call map(self.buffer.all, 'extend(v:val, deepcopy(tools))')

  " Add positions on the buffer
  call map(self.buffer.all, 'extend(v:val, {"region": deepcopy(s:null_region)})')
  call s:address_{motionwise}wise(self.buffer.all, self.region.head)

  " symbols
  let symbols = self.buffer.symbols
  let symbols['#'] = s:sharp(self.curpos, self.buffer)
  let symbols['^'] = s:hat(self.buffer)
  let symbols['$'] = s:dollar(self.buffer)
endfunction
"}}}
function! s:item_cursor(...) dict abort "{{{
  let to_tail = get(a:000, 0, 0)
  if to_tail
    call setpos('.', self.region.tail)
  else
    call setpos('.', self.region.head)
  endif
endfunction
"}}}
function! s:item_highlight(group) dict abort "{{{
  if self.region.len > 0
    let n = 0
    let order = []
    let order_list = []
    let lines = split(self.string, '\n\zs')
    let n_lines = len(lines)
    if n_lines == 1
      let order = [self.region.head[1:2] + [self.region.len]]
      let order_list = [order]
    else
      for i in range(n_lines)
        if i == 0
          let order += [self.region.head[1:2] + [strlen(lines[0])]]
        elseif i == n_lines-1
          let order += [[self.region.head[1] + i, 1, strlen(lines[i])]]
        else
          let order += [[self.region.head[1] + i]]
        endif

        if n == 7
          let order_list += [copy(order)]
          let order = []
          let n = 0
        else
          let n += 1
        endif
      endfor
      let order_list += [copy(order)]
    endif

    for order in order_list
      let self.highlightid += s:matchaddpos(a:group, order)
    endfor
  endif
endfunction
"}}}
function! s:item_clear_highlight() dict abort  "{{{
  call filter(map(self.highlightid, 's:matchdelete(v:val)'), 'v:val > 0')
endfunction
"}}}
function! s:swap_execute() dict abort "{{{
  if self.state && self.order == []
    let self.undojoin = -1
    let s:interface = deepcopy(s:interface_prototype)
    let s:interface.buffer = self.buffer
    while 1
      let order = s:interface.start()
      let self.undojoin += 1
      if order != []
        call self.swap(order)
      else
        break
      endif
    endwhile
    let self.order = deepcopy(s:interface.truncate_history())
    unlet! s:interface
    echo ''
  else
    let self.undojoin = 0
    for order in self.order
      call self.swap(order)
    endfor
  endif
endfunction
"}}}
function! s:swap_swap(order) dict abort "{{{
  if a:order == []
    return
  endif

  let order = deepcopy(a:order)

  " substitute symbols
  for symbol in ['#', '^', '$']
    if stridx(order[0], symbol) > -1 || stridx(order[1], symbol) > -1
      call s:substitute_symbol(order, symbol, self.buffer.symbols[symbol])
    endif
  endfor

  " evaluate after substituting symbols
  call map(order, 'type(v:val) == s:type_str ? eval(v:val) : v:val')

  let n = len(self.buffer.items) - 1
  let idx = map(copy(order), 'type(v:val) == s:type_num ? v:val - 1 : -1')
  if idx[0] < 0 || idx[0] > n || idx[1] < 0 || idx[1] > n
    " the index is out of range
    return
  endif

  " swap items in buffer
  let item0 = s:extractall(self.buffer.items[idx[0]])
  let item1 = s:extractall(self.buffer.items[idx[1]])
  call extend(self.buffer.items[idx[0]], item1, 'force')
  call extend(self.buffer.items[idx[1]], item0, 'force')
  let motionwise = self.motionwise ==# 'V'      ? 'line'
               \ : self.motionwise ==# "\<C-v>" ? 'block'
               \ : 'char'
  call s:address_{motionwise}wise(self.buffer.all, self.region.head)

  " reflect to the buffer
  call self.reflect(idx[1])
endfunction
"}}}
function! s:swap_reflect(cursor_idx) dict abort "{{{
  " reflect to the buffer
  let undojoin = self.undojoin ? 'undojoin | ' : ''
  let reg = ['"', getreg('"'), getregtype('"')]
  call setreg('"', join(map(copy(self.buffer.all), 'v:val.string'), ''), self.motionwise)
  call setpos('.', self.region.head)
  execute printf('%snormal! "_d%s:call setpos(".", %s)%s""P:', undojoin, self.motionwise, string(self.region.tail), "\<CR>")
  let self.region.head = getpos("'[")
  let self.region.tail = getpos("']")
  call call('setreg', reg)

  " move cursor
  call winrestview(self.view)
  call self.buffer.items[a:cursor_idx].cursor()
  let self.buffer.symbols['#'] = a:cursor_idx + 1
endfunction
"}}}
function! s:buffer_clear_highlight(...) dict abort  "{{{
  let section = get(a:000, 0, 'all')
  call s:clear_highlight_all(self[section])
endfunction
"}}}
let s:swap_obj_prototype = {
      \   'rule'   : {},
      \   'state'  : 0,
      \   'mode'   : 'n',
      \   'motionwise': 'v',
      \   'curpos' : deepcopy(s:null_pos),
      \   'view'   : {},
      \   'order'  : [],
      \   'buffer' : {
      \     'all'       : [],
      \     'items'     : [],
      \     'delimiters': [],
      \     'symbols'   : {'#': 0, '^': 0, '$': 0},
      \     'clear_highlight': function('s:buffer_clear_highlight'),
      \   },
      \   'undojoin': 0,
      \   'region' : deepcopy(s:null_region),
      \   'search' : function('s:swap_search'),
      \   'verify' : function('s:swap_verify'),
      \   'execute': function('s:swap_execute'),
      \   'parse'  : function('s:swap_parse'),
      \   'swap'   : function('s:swap_swap'),
      \   'reflect': function('s:swap_reflect'),
      \ }
"}}}

" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" vim:set ts=2 sts=2 sw=2:
