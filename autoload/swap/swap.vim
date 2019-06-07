" Swap object - Managing a whole action.

let s:Const = swap#constant#import()
let s:Lib = swap#lib#import()
let s:Searcher = swap#searcher#import()
let s:Parser = swap#parser#import()
let s:Buffer = swap#buffer#import()
let s:Mode = swap#mode#import()
let s:Logging = swap#logging#import()

let s:TRUE = 1
let s:FALSE = 0
let s:TYPESTR = s:Const.TYPESTR
let s:TYPENUM = s:Const.TYPENUM
let s:TYPEDICT = s:Const.TYPEDICT
let s:TYPEFUNC = s:Const.TYPEFUNC
let s:NULLREGION = s:Const.NULLREGION
let s:GUI_RUNNING = has('gui_running')

let s:logger = s:Logging.Logger(expand('<sfile>'))


function! swap#swap#new(mode, orders, rules) abort "{{{
  let swap = deepcopy(s:Swap)
  let swap.mode = a:mode
  let swap.orders = a:orders
  let swap.rules = s:get_rules(a:rules, &l:filetype, a:mode)
  return swap
endfunction "}}}


let s:Swap = {
\   'dotrepeat': s:FALSE,
\   'mode': '',
\   'rules': [],
\   'orders': [],
\ }


function! s:Swap.around(pos) abort "{{{
  let options = s:displace_options()
  try
    let pos = s:getpos(a:pos)
    call self._around(pos)
  finally
    call s:restore_options(options)
  endtry
endfunction "}}}


function! s:Swap._around(pos) abort "{{{
  let rules = deepcopy(self.rules)
  let [buffer, rule] = s:search(rules, a:pos)
  if empty(buffer)
    return
  endif
  if self.dotrepeat
    call self._swap_sequential(buffer)
  else
    if empty(self.orders)
      let self.orders = self._swap_interactive(buffer)
    else
      call self._swap_sequential(buffer)
    endif
    " Use the same rule in dot-repeatings
    let self.rules = [rule]
  endif
endfunction "}}}


function! s:Swap.region(start, end, type) abort "{{{
  let options = s:displace_options()
  try
    let start = s:getpos(a:start)
    let end = s:getpos(a:end)
    let type = s:Lib.v2type(a:type)
    call self._region(start, end, type)
  finally
    call s:restore_options(options)
  endtry
endfunction "}}}


function! s:Swap._region(start, end, type) abort "{{{
  let region = s:get_region(a:start, a:end, a:type)
  if region is# s:NULLREGION
    return
  endif
  let rules = deepcopy(self.rules)
  let [buffer, rule] = s:match(region, rules)
  if empty(buffer)
    return
  endif
  if self.dotrepeat
    call self._swap_sequential(buffer)
  else
    if empty(self.orders)
      let self.orders = self._swap_interactive(buffer)
    else
      call self._swap_sequential(buffer)
    endif
    " Use the same rule in dot-repeatings
    let self.rules = [rule]
  endif
endfunction "}}}


function! s:Swap.operatorfunc(type) abort "{{{
  call s:logger.debug('Operatorfunc [mode: %s, dot-repeat: %s]',
  \                   g:swap.mode, g:swap.dotrepeat)
  if self.mode is# 'n'
    call self.around(getpos('.'))
  elseif self.mode is# 'x'
    let start = getpos("'[")
    let end = getpos("']")
    let type = s:Lib.v2type(a:type)
    call self.region(start, end, type)
  endif
  let self.dotrepeat = s:TRUE
endfunction "}}}


function! s:Swap._swap_interactive(buffer) abort "{{{
  if a:buffer == {}
    return []
  endif

  let buffer = a:buffer
  let undojoin = s:FALSE
  let swapmode = s:Mode.Swapmode()
  call s:logger.debug('Swapmode start')
  while s:TRUE
    let orders = swapmode.get_input(buffer)
    if orders == [] | break | endif
    let [buffer, undojoin] = self._edit(buffer, orders, undojoin)
  endwhile
  call s:logger.debug('Swapmode end')
  return swapmode.export_history()
endfunction "}}}


function! s:Swap._swap_sequential(buffer) abort  "{{{
  if a:buffer == {}
    return
  endif

  call self._edit(a:buffer, self.orders, s:FALSE)
endfunction "}}}


function! s:Swap._edit(buffer, orders, undojoin) abort "{{{
  let buffer = a:buffer
  for order in a:orders
    call s:logger.debug('  order: %s', order)
    if order[0] is# 'undo'
      let [buffer, undojoin] = self._restore_buffer(order, a:undojoin)
    elseif order[0] is# 'group'
      let [buffer, undojoin] = self._group(buffer, order, a:undojoin)
    elseif order[0] is# 'ungroup'
      let [buffer, undojoin] = self._ungroup(buffer, order, a:undojoin)
    elseif order[0] is# 'breakup'
      let [buffer, undojoin] = self._breakup(buffer, order, a:undojoin)
    elseif order[0] is# 'reverse'
      let [buffer, undojoin] = self._reverse(buffer, order, a:undojoin)
    elseif order[0] is# 'sort'
      let [buffer, undojoin] = self._sort_items(buffer, order, a:undojoin)
    else
      let [buffer, undojoin] = self._swap_once(buffer, order, a:undojoin)
    endif
    " call s:logger.debug('  buffer: %s', s:string(buffer))
  endfor
  return [buffer, undojoin]
endfunction "}}}


function! s:Swap._swap_once(buffer, order, undojoin) abort "{{{
  " substitute and eval symbols
  let order = map(copy(a:order), 'a:buffer.get_pos(v:val)')
  if !s:is_valid_input(order, a:buffer)
    return [a:buffer, a:undojoin]
  endif

  " swap items on the buffer
  let newbuffer = s:swap(a:buffer, order)
  call s:write(newbuffer, a:undojoin)

  " update buffer information
  let newbuffer.head = getpos("'[")
  let newbuffer.tail = getpos("']")
  call newbuffer.update_tokens()
  call newbuffer.get_item(order[1], s:TRUE).cursor()
  call newbuffer.update_sharp(getpos('.'))
  call newbuffer.update_hat()
  call newbuffer.update_dollar()
  return [newbuffer, s:TRUE]
endfunction "}}}


function! s:Swap._restore_buffer(order, undojoin) abort "{{{
  if a:order[0] isnot# 'undo'
    echoerr 'vim-swap: Invalid arguments for swap._restore_buffer()'
  endif

  " restore the buffer in order
  let newbuffer = a:order[1]
  call s:write(newbuffer, a:undojoin)

  " update buffer information
  let newbuffer.head = getpos("'[")
  let newbuffer.tail = getpos("']")
  call newbuffer.update_tokens()
  call newbuffer.get_item(a:order[2], s:TRUE).cursor()
  call newbuffer.update_sharp(getpos('.'))
  call newbuffer.update_hat()
  call newbuffer.update_dollar()
  return [newbuffer, s:TRUE]
endfunction "}}}


function! s:Swap._sort_items(buffer, order, undojoin) abort "{{{
  if a:order[0] isnot# 'sort'
    echoerr 'vim-swap: Invalid arguments for swap._sort_items()'
  endif
  let curpos = getpos('.')

  " sort items and reflect on the buffer
  let args = a:order[1:]
  let newbuffer = s:sort(a:buffer, args)
  call s:write(newbuffer, a:undojoin)

  " update buffer information
  let newbuffer.head = getpos("'[")
  let newbuffer.tail = getpos("']")
  call newbuffer.update_tokens()
  let pos = newbuffer.update_sharp(curpos)
  call newbuffer.get_item(pos, s:TRUE).cursor()
  call newbuffer.update_hat()
  return [newbuffer, s:TRUE]
endfunction "}}}


function! s:Swap._group(buffer, order, undojoin) abort "{{{
  if a:order[0] isnot# 'group'
    echoerr 'vim-swap: Invalid arguments for swap._group()'
  endif

  let start = a:order[1]
  let end = a:order[2]
  call a:buffer.group(start, end)
  return [a:buffer, a:undojoin]
endfunction "}}}


function! s:Swap._ungroup(buffer, order, undojoin) abort "{{{
  if a:order[0] isnot# 'ungroup'
    echoerr 'vim-swap: Invalid arguments for swap._ungroup()'
  endif

  let pos = a:order[1]
  call a:buffer.ungroup(pos)
  return [a:buffer, a:undojoin]
endfunction "}}}


function! s:Swap._breakup(buffer, order, undojoin) abort "{{{
  if a:order[0] isnot# 'breakup'
    echoerr 'vim-swap: Invalid arguments for swap._breakup()'
  endif

  let pos = a:order[1]
  call a:buffer.breakup(pos)
  return [a:buffer, a:undojoin]
endfunction "}}}


function! s:Swap._reverse(buffer, order, undojoin) abort "{{{
  if a:order[0] isnot# 'reverse'
    echoerr 'vim-swap: Invalid arguments for swap._reverse()'
  endif
  let curpos = getpos('.')

  " reverse items and reflect on the buffer
  let args = a:order[1:]
  let newbuffer = s:reverse(a:buffer, args)
  call s:write(newbuffer, a:undojoin)

  " update buffer information
  let newbuffer.head = getpos("'[")
  let newbuffer.tail = getpos("']")
  call newbuffer.update_tokens()
  let pos = newbuffer.update_sharp(curpos)
  call newbuffer.get_item(pos, s:TRUE).cursor()
  call newbuffer.update_hat()
  return [newbuffer, s:TRUE]
endfunction "}}}


" This method is mainly for textobjects
function! s:Swap.search(pos, ...) abort "{{{
  let rules = deepcopy(self.rules)
  let pos = s:getpos(a:pos)
  let textobj = get(a:000, 0, s:FALSE)
  return s:search(rules, pos, textobj)
endfunction "}}}


function! s:displace_options() abort  "{{{
  let options = {}
  let options.virtualedit = &virtualedit
  let options.whichwrap = &whichwrap
  let options.selection = &selection
  let [&virtualedit, &whichwrap, &selection] = ['onemore', 'h,l', 'inclusive']
  if s:GUI_RUNNING
    let options.cursor = &guicursor
    set guicursor+=a:block-NONE
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


function! s:get_rules(rules, filetype, mode) abort  "{{{
  let rules = deepcopy(a:rules)
  if a:mode is# 'n'
    call filter(rules, 'has_key(v:val, "body") || has_key(v:val, "surrounds")')
  endif
  call filter(rules,
  \ 's:filter_filetype(v:val, a:filetype) && s:filter_mode(v:val, a:mode)')
  call map(rules, 'extend(v:val, {"priority": 0}, "keep")')
  call s:Lib.sort(reverse(rules), function('s:compare_priority'))
  call s:remove_duplicate_rules(rules)
  return rules
endfunction "}}}


function! s:filter_filetype(rule, filetype) abort  "{{{
  if !has_key(a:rule, 'filetype')
    return s:TRUE
  endif
  let filetypes = split(a:filetype, '\.')
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
      let duplicate_body = s:is_duplicate_body(representative, target)
      let duplicate_surrounds = s:is_duplicate_surrounds(representative, target)
      if duplicate_body && duplicate_surrounds
        call remove(a:rules, j)
      else
        let j += 1
      endif
    endwhile
    let i += 1
  endwhile
endfunction "}}}


function! s:is_duplicate_body(a, b) abort "{{{
  if !has_key(a:a, 'body') && !has_key(a:b, 'body')
    return s:TRUE
  endif
  if has_key(a:a, 'body') && has_key(a:b, 'body') && a:a.body == a:b.body
    return s:TRUE
  endif
  return s:FALSE
endfunction "}}}


function! s:is_duplicate_surrounds(a, b) abort "{{{
  if !has_key(a:a, 'surrounds') && !has_key(a:b, 'surrounds')
    return s:TRUE
  endif
  if has_key(a:a, 'surrounds') && has_key(a:b, 'surrounds') &&
  \  a:a.surrounds[0:1] == a:b.surrounds[0:1] &&
  \  get(a:a, 2, 1) == get(a:b, 2, 1)
    return s:TRUE
  endif
  return s:FALSE
endfunction "}}}


function! s:get_region(start, end, type) abort "{{{
  let region = deepcopy(s:NULLREGION)
  let region.head = a:start
  let region.tail = a:end
  let region.type = a:type
  if !s:Lib.is_valid_region(region)
    return s:NULLREGION
  endif

  let region.len = s:Lib.get_buf_length(region)
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


function! s:search(rules, pos, ...) abort "{{{
  call s:logger.debug('Search a swappable region around %s', a:pos)
  let view = winsaveview()
  let textobj = get(a:000, 0, s:FALSE)
  let buffer = {}
  let virtualedit = &virtualedit
  let &virtualedit = 'onemore'
  try
    while a:rules != []
      let priority_group = s:get_priority_group(a:rules)
      let [buffer, rule] = s:search_by_group(priority_group, a:pos, textobj)
      if buffer != {}
        break
      endif
    endwhile
  finally
    let &virtualedit = virtualedit
  endtry
  call winrestview(view)

  if buffer == {}
    call s:logger.info('No match. Swappable region search failed.')
    return [{}, {}]
  endif
  call s:logger.info('Matched. start: %s, end: %s', buffer.head, buffer.tail)
  call s:logger.info('  matched rule: %s', rule)
  " call s:logger.debug('  token list: %s', buffer.all)
  return [buffer, rule]
endfunction "}}}


function! s:search_by_group(priority_group, curpos, textobj) abort "{{{
  let searchitems = map(copy(a:priority_group), '{
  \   "rule": v:val,
  \   "region": deepcopy(s:NULLREGION),
  \ }')
  while searchitems != []
    let done_list = []
    for sitem in searchitems
      let rule = sitem.rule
      let region = sitem.region
      let [region, done] = s:Searcher.search(rule, region, a:curpos)
      let sitem.region = region
      call add(done_list, done)
    endfor
    call filter(searchitems, 'v:val.region isnot# s:NULLREGION')
    call s:Lib.sort(searchitems, function('s:compare_len'))

    for sitem in searchitems
      let rule = sitem.rule
      let region = sitem.region
      let text = s:get_buf_text(region)
      let tokens = s:Parser.parse(text, region.type, rule)
      let buffer = s:Buffer.Buffer(tokens, region, a:curpos)
      if buffer.swappable() || (a:textobj && buffer.selectable())
        return [buffer, rule]
      endif
    endfor
    call filter(searchitems, '!done_list[v:key]')
  endwhile
  return [{}, {}]
endfunction "}}}


function! s:get_buf_text(region) abort  "{{{
  " NOTE: Do *not* use operator+textobject in another textobject!
  "       For example, getting a text with the command is not appropriate.
  "         execute printf('normal! %s:call setpos(".", %s)%s""y', a:retion.motionwise, string(a:region.tail), "\<CR>")
  "       Because it causes confusions for the unit of dot-repeating.
  "       Use visual selection+operator as following.
  let text = ''
  let v = s:Lib.type2v(a:region.type)
  let visual = [getpos("'<"), getpos("'>")]
  let registers = s:saveregisters()
  let selection = &selection
  set selection=inclusive
  try
    call setpos('.', a:region.head)
    execute 'normal! ' . v
    call setpos('.', a:region.tail)
    silent noautocmd normal! ""y
    let text = @@
  finally
    let &selection = selection
    call s:restoreregisters(registers)
    call setpos("'<", visual[0])
    call setpos("'>", visual[1])
    return text
  endtry
endfunction "}}}


function! s:saveregisters() abort "{{{
  let registers = {}
  let registers['0'] = s:getregister('0')
  let registers['1'] = s:getregister('1')
  let registers['2'] = s:getregister('2')
  let registers['3'] = s:getregister('3')
  let registers['4'] = s:getregister('4')
  let registers['5'] = s:getregister('5')
  let registers['6'] = s:getregister('6')
  let registers['7'] = s:getregister('7')
  let registers['8'] = s:getregister('8')
  let registers['9'] = s:getregister('9')
  let registers['"'] = s:getregister('"')
  if &clipboard =~# 'unnamed'
    let registers['*'] = s:getregister('*')
  endif
  if &clipboard =~# 'unnamedplus'
    let registers['+'] = s:getregister('+')
  endif
  return registers
endfunction "}}}


function! s:restoreregisters(registers) abort "{{{
  for [register, contains] in items(a:registers)
    call s:setregister(register, contains)
  endfor
endfunction "}}}


function! s:getregister(register) abort "{{{
  return [getreg(a:register), getregtype(a:register)]
endfunction "}}}


function! s:setregister(register, contains) abort "{{{
  let [value, options] = a:contains
  return setreg(a:register, value, options)
endfunction "}}}


function! s:match(region, rules) abort  "{{{
  call s:logger.debug('Match the region from %s to %s with rules',
  \                   a:region.head, a:region.tail)
  if a:region is# s:NULLREGION
    call s:logger.debug('Invalid region assigned. Matching failed.')
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

  if buffer == {}
    call s:logger.info('No Match. Matching failed.')
    return [{}, {}]
  endif
  call s:logger.info('Matched. start: %s, end: %s', buffer.head, buffer.tail)
  call s:logger.info('  matched rule: %s', rule)
  " call s:logger.debug('  token list: %s', buffer.all)
  return [buffer, rule]
endfunction "}}}


function! s:match_group(region, priority_group, curpos) abort "{{{
  for rule in a:priority_group
    if s:Searcher.match(rule, a:region)
      let text = s:get_buf_text(a:region)
      let tokens = s:Parser.parse(text, a:region.type, rule)
      let buffer = s:Buffer.Buffer(tokens, a:region, a:curpos)
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


function! s:is_valid_input(input, buffer) abort "{{{
  if type(a:input[0]) isnot# s:TYPENUM
    return s:FALSE
  endif
  if type(a:input[1]) isnot# s:TYPENUM
    return s:FALSE
  endif
  let n = len(a:buffer.items)
  if a:input[0] < 1 || a:input[0] > n
    return s:FALSE
  endif
  if a:input[1] < 1 || a:input[1] > n
    return s:FALSE
  endif
  return s:TRUE
endfunction "}}}


" This function returns a shallow copy of a:items with ungrouping
function! s:ungrouped_copy(items) abort "{{{
  let ungrouped_list = []
  for item in a:items
    if item.attr is# 'itemgroup'
      call extend(ungrouped_list, item.flatten())
    else
      call add(ungrouped_list, item)
    endif
  endfor
  return ungrouped_list
endfunction "}}}


function! s:new_buffer(buffer, items) abort "{{{
  let newbuffer = deepcopy(a:buffer)
  call filter(newbuffer.all, 0)
  call filter(newbuffer.items, 0)

  " Fill items into newbuffer.items without ungrouping
  call extend(newbuffer.items, a:items)

  " Fill items into newbuffer.all with ungrouping
  let ungrouped_list = s:ungrouped_copy(newbuffer.items)
  for token in a:buffer.all
    if token.attr is# 'item'
      call add(newbuffer.all, remove(ungrouped_list, 0))
    else
      call add(newbuffer.all, token)
    endif
  endfor
  return newbuffer
endfunction "}}}


function! s:swap(buffer, order) abort "{{{
  let itemindexes = range(len(a:buffer.items))
  let idx1 = a:order[0] - 1
  let idx2 = a:order[1] - 1
  call remove(itemindexes, idx1)
  call insert(itemindexes, idx2, idx1)
  call remove(itemindexes, idx2)
  call insert(itemindexes, idx1, idx2)

  let items = []
  for i in itemindexes
    let token = a:buffer.items[i]
    call add(items, token)
  endfor
  return s:new_buffer(a:buffer, items)
endfunction "}}}


let s:INVALID = 0

function! s:sort(buffer, args) abort "{{{
  let start = a:buffer.get_pos(get(a:args, 0, 1), s:TRUE) - 1
  let end = a:buffer.get_pos(get(a:args, 1, '$'), s:TRUE) - 1
  let items = deepcopy(a:buffer.items)
  let [front, mid, back] = s:split(items, start, end)

  let mid = s:lockall(mid)
  sandbox let sorted_items = call(s:Lib.sort, [mid] + a:args[2:])
  let sorted_items = s:unlockall(sorted_items)

  return s:new_buffer(a:buffer, front + sorted_items + back)
endfunction "}}}


function! s:lockall(list) abort "{{{
  for item in a:list
    call s:lock(item)
  endfor
  return a:list
endfunction "}}}


function! s:lock(item) abort "{{{
  lockvar! a:item
endfunction "}}}


function! s:unlockall(list) abort "{{{
  for item in a:list
    unlockvar! item
  endfor
  return a:list
endfunction "}}}


function! s:string(buffer) abort "{{{
  return join(map(copy(a:buffer.all), 'v:val.str'), '')
endfunction "}}}


function! s:write(buffer, undojoin) abort "{{{
  let str = s:string(a:buffer)
  let v = s:Lib.type2v(a:buffer.type)
  let view = winsaveview()
  let undojoin_cmd = a:undojoin ? 'undojoin | ' : ''
  let reg = ['"', getreg('"'), getregtype('"')]
  call setreg('"', str, v)
  call setpos('.', a:buffer.head)
  silent execute printf('%snoautocmd normal! "_d%s:call setpos(".", %s)%s""P:',
  \                     undojoin_cmd, v, string(a:buffer.tail), "\<CR>")
  call call('setreg', reg)
  call winrestview(view)
endfunction "}}}


function! s:getpos(pos) abort "{{{
  if type(a:pos) is# s:TYPESTR
    return getpos(a:pos)
  endif
  return a:pos
endfunction "}}}


function! s:reverse(buffer, args) abort "{{{
  let start = a:buffer.get_pos(get(a:args, 0, 1), s:TRUE) - 1
  let end = a:buffer.get_pos(get(a:args, 1, '$'), s:TRUE) - 1
  let items = deepcopy(a:buffer.items)
  let [front, mid, back] = s:split(items, start, end)
  return s:new_buffer(a:buffer, front + reverse(mid) + back)
endfunction "}}}


function! s:split(list, start, end) abort "{{{
  let front = a:start == 0 ? [] : a:list[: a:start-1]
  let mid = a:list[a:start : a:end]
  let back = a:list[a:end+1 :]
  return [front, mid, back]
endfunction "}}}


" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" vim:set ts=2 sts=2 sw=2:
