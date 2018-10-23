" swap object - Managing a whole action.

let s:const = swap#constant#import(s:, ['TYPESTR', 'TYPENUM', 'NULLREGION'])
let s:lib = swap#lib#import()

let s:TRUE = 1
let s:FALSE = 0
let s:TYPESTR = s:const.TYPESTR
let s:TYPENUM = s:const.TYPENUM
let s:NULLREGION = s:const.NULLREGION
let s:GUI_RUNNING = has('gui_running')


function! swap#swap#new(mode, order_list) abort "{{{
  let swap = deepcopy(s:swap_prototype)
  let swap.mode = a:mode
  let swap.order_list = a:order_list
  let swap.rules = s:get_rules(a:mode)
  return swap
endfunction "}}}


let s:swap_prototype = {
      \   'dotrepeat': s:FALSE,
      \   'mode': '',
      \   'rules': [],
      \   'order_list': [],
      \ }


function! s:swap_prototype.around_cursor() abort "{{{
  let options = s:displace_options()
  try
    call self._around_cursor()
  finally
    call s:restore_options(options)
  endtry
endfunction "}}}


function! s:swap_prototype._around_cursor() abort "{{{
  let rules = deepcopy(self.rules)
  let [buffer, rule] = s:search(rules, 'char')
  if self.dotrepeat
    call self._swap_sequential(buffer)
  else
    if empty(rule)
      return
    endif
    let self.rules = [rule.initialize()]
    if self.order_list != []
      call self._swap_sequential(buffer)
    else
      call self._swap_interactive(buffer)
    endif
  endif
endfunction "}}}


function! s:swap_prototype.region(start, end, type) abort "{{{
  let options = s:displace_options()
  try
    call self._region(a:start, a:end, a:type)
  finally
    call s:restore_options(options)
  endtry
endfunction "}}}


function! s:swap_prototype._region(start, end, type) abort "{{{
  let region = s:get_region(a:start, a:end, a:type)
  if region is# s:NULLREGION
    return
  endif
  let rules = deepcopy(self.rules)
  let [buffer, rule] = s:match(region, rules)
  if self.dotrepeat
    call self._swap_sequential(buffer)
  else
    let self.rules = [rule]
    if self.order_list != []
      call self._swap_sequential(buffer)
    else
      call self._swap_interactive(buffer)
    endif
  endif
endfunction "}}}


function! s:swap_prototype.operatorfunc(type) dict abort "{{{
  if self.mode is# 'n'
    call self.around_cursor()
  elseif self.mode is# 'x'
    let start = getpos("'[")
    let end = getpos("']")
    call self.region(start, end, a:type)
  endif
  let self.dotrepeat = s:TRUE
endfunction "}}}


function! s:swap_prototype._swap_interactive(buffer) dict abort "{{{
  if a:buffer == {}
    return []
  endif

  let undojoin = s:FALSE
  let interface = swap#interface#new()
  try
    while s:TRUE
      let order = interface.query(a:buffer)
      if order == [] | break | endif
      let undojoin = self._swap_once(a:buffer, order, undojoin)
    endwhile
  catch /^Vim:Interrupt$/
  finally
    call a:buffer.clear_highlight()
  endtry
  return interface.history
endfunction "}}}


function! s:swap_prototype._swap_sequential(buffer) dict abort  "{{{
  if a:buffer == {}
    return
  endif

  let undojoin = s:FALSE
  for order in self.order_list
    let undojoin = self._swap_once(a:buffer, order, undojoin)
  endfor
  return self.order_list
endfunction "}}}


function! s:swap_prototype._swap_once(buffer, order, undojoin) dict abort "{{{
  if a:order == []
    return a:undojoin
  endif

  let order = deepcopy(a:order)

  " substitute symbols
  for symbol in ['#', '^', '$']
    if stridx(order[0], symbol) > -1 || stridx(order[1], symbol) > -1
      call s:substitute_symbol(order, symbol, a:buffer.symbols[symbol])
    endif
  endfor

  " evaluate after substituting symbols
  call map(order, 'type(v:val) == s:TYPESTR ? eval(v:val) : v:val')

  let n = len(a:buffer.items)
  if type(order[0]) != s:TYPENUM || type(order[1]) != s:TYPENUM
        \ || order[0] < 1 || order[0] > n || order[1] < 1 || order[1] > n
    " the index is out of range
    return a:undojoin
  endif

  " swap items in buffer
  call a:buffer.swap(order, a:undojoin)
  return s:TRUE
endfunction "}}}


" This method is mainly for textobjects
function! s:swap_prototype.search(motionwise, ...) abort "{{{
  let rules = deepcopy(self.rules)
  let textobj = get(a:000, 0, 0)
  return s:search(rules, a:motionwise, textobj)
endfunction "}}}


function! s:displace_options() abort  "{{{
  let options = {}
  let options.virtualedit = &virtualedit
  let options.whichwrap = &whichwrap
  let options.selection = &selection
  let [&virtualedit, &whichwrap, &selection] = ['onemore', 'h,l', 'inclusive']
  if s:GUI_RUNNING
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
  if s:GUI_RUNNING
    set guicursor&
    let &guicursor = a:options.cursor
  else
    let &t_ve = a:options.cursor
  endif
  let &l:cursorline = a:options.cursorline
endfunction "}}}


function! s:get_rules(mode) abort  "{{{
  let rules = deepcopy(get(g:, 'swap#rules', g:swap#default_rules))
  call map(rules, 'extend(v:val, {"priority": 0}, "keep")')
  call s:lib.sort(reverse(rules), function('s:compare_priority'))
  call filter(rules, 's:filter_filetype(v:val) && s:filter_mode(v:val, a:mode)')
  if a:mode isnot# 'x'
    call s:remove_duplicate_rules(rules)
  endif
  return map(rules, 'swap#rule#get(v:val)')
endfunction "}}}


function! s:filter_filetype(rule) abort  "{{{
  if !has_key(a:rule, 'filetype')
    return s:TRUE
  endif
  let filetypes = split(&filetype, '\.')
  if filetypes == []
    let filter = 'v:val is# ""'
  else
    let filter = 'v:val isnot# "" && count(filetypes, v:val) > 0'
  endif
  return filter(copy(a:rule['filetype']), filter) != []
endfunction "}}}


function! s:filter_mode(rule, mode) abort  "{{{
  if !has_key(a:rule, 'mode')
    return s:TRUE
  endif
  return stridx(a:rule.mode, a:mode) > -1
endfunction "}}}


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
endfunction "}}}


function! s:get_region(start, end, type) abort "{{{
  let region = deepcopy(s:NULLREGION)
  let region.head = a:start
  let region.tail = a:end
  let region.type = a:type
  let region.visualkey = s:lib.motionwise2visualkey(a:type)
  if !s:lib.is_valid_region(region)
    return s:NULLREGION
  endif

  let region.len = s:lib.get_buf_length(region)
  return region
endfunction "}}}


function! s:get_priority_group(rules) abort "{{{
  " NOTE: This function move items in a:rules to priority_group.
  "       Thus it makes changes to a:rules also.
  let priority = get(a:rules[0], 'priority', 0)
  let priority_group = []
  while a:rules != []
    let rule = a:rules[0]
    if rule.priority != priority
      break
    endif
    call add(priority_group, remove(a:rules, 0))
  endwhile
  return priority_group
endfunction "}}}


function! s:search(rules, motionwise, ...) abort "{{{
  let view = winsaveview()
  let textobj = get(a:000, 0, 0)
  let curpos = getpos('.')
  let buffer = {}
  let virtualedit = &virtualedit
  let &virtualedit = 'onemore'
  try
    while a:rules != []
      let priority_group = s:get_priority_group(a:rules)
      let [buffer, rule] = s:search_by_group(priority_group, curpos,
                                           \ a:motionwise, textobj)
      if buffer != {}
        break
      endif
    endwhile
  finally
    let &virtualedit = virtualedit
  endtry
  call winrestview(view)
  return buffer != {} ? [buffer, rule] : [{}, {}]
endfunction "}}}


function! s:search_by_group(priority_group, curpos, motionwise, ...) abort "{{{
  let textobj = get(a:000, 0, 0)
  while a:priority_group != []
    for rule in a:priority_group
      call rule.search(a:curpos, a:motionwise)
    endfor
    call filter(a:priority_group, 's:lib.is_valid_region(v:val.region)')
    call s:lib.sort(a:priority_group, function('s:compare_len'))

    for rule in a:priority_group
      let region = rule.region
      let buffer = swap#parser#parse(region, rule, a:curpos)
      if buffer.swappable() || (textobj && buffer.selectable())
        return [buffer, rule]
      endif
    endfor
  endwhile
  return [{}, {}]
endfunction "}}}


function! s:match(region, rules) abort  "{{{
  if a:region == s:NULLREGION
    return [{}, {}]
  endif

  let view = winsaveview()
  let curpos = getpos('.')
  let buffer = {}
  while a:rules != []
    let priority_group = s:get_priority_group(a:rules)
    let [buffer, rule] = s:match_group(a:region, priority_group, curpos)
    if buffer != {}
      break
    endif
  endwhile
  call winrestview(view)
  return buffer != {} ? [buffer, rule] : [{}, {}]
endfunction "}}}


function! s:match_group(region, priority_group, curpos) abort "{{{
  for rule in a:priority_group
    if rule.match(a:region)
      let buffer = swap#parser#parse(a:region, rule, a:curpos)
      if buffer.swappable()
        return [buffer, rule]
      endif
    endif
  endfor
  return [{}, {}]
endfunction "}}}


function! s:compare_priority(r1, r2) abort "{{{
  let priority_r1 = get(a:r1, 'priority', 0)
  let priority_r2 = get(a:r2, 'priority', 0)
  if priority_r1 > priority_r2
    return -1
  elseif priority_r1 < priority_r2
    return 1
  else
    return 0
  endif
endfunction "}}}


function! s:compare_len(r1, r2) abort "{{{
  return a:r1.region.len - a:r2.region.len
endfunction "}}}


function! s:substitute_symbol(order, symbol, symbol_idx) abort "{{{
  let symbol = s:lib.escape(a:symbol)
  return map(a:order, 'type(v:val) == s:TYPESTR ? substitute(v:val, symbol, a:symbol_idx, "") : v:val')
endfunction "}}}


" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" vim:set ts=2 sts=2 sw=2:
