" interface object - Interactive order determination, "swap mode".

let s:const = swap#constant#import()
let s:lib = swap#lib#import()

let s:TRUE = 1
let s:FALSE = 0
let s:TYPENUM = s:const.TYPENUM
let s:TYPESTR = s:const.TYPESTR

" phase enum
let s:FIRST = 0       " in the first target determination
let s:SECOND = 1      " in the second target determination
let s:DONE = 2        " Both the targets have been determined
let s:CANCELLED = 3   " cancelled by Esc

" patches
if v:version > 704 || (v:version == 704 && has('patch237'))
  let s:has_patch_7_4_311 = has('patch-7.4.311')
else
  let s:has_patch_7_4_311 = v:version == 704 && has('patch311')
endif


function! swap#interface#new() abort  "{{{
  let s:interface = deepcopy(s:interface_prototype)
  return s:interface
endfunction "}}}



" operation object - representing an edit action
" operation.kind is either 'swap', 'undo' or 'redo'.
let s:operation_prototype = {
  \   'kind': '',
  \   'input': ['', ''],
  \ }


function! s:operation_prototype.set_input(phase, input) abort "{{{
  let input = copy(self.input)
  if a:phase is# s:FIRST
    let input[0] = a:input
  elseif a:phase is# s:SECOND
    let input[1] = a:input
  else
    echoerr 'vim-swap: Invalid argument for operation.set_input()'
  endif
  return s:operation('swap', input)
endfunction "}}}


function! s:operation_prototype.append_input(phase, input) abort "{{{
  let input = copy(self.input)
  if a:phase is# s:FIRST
    let input[0] .= a:input
  elseif a:phase is# s:SECOND
    let input[1] .= a:input
  else
    echoerr 'vim-swap: Invalid argument for operation.append_input()'
  endif
  return s:operation('swap', input)
endfunction "}}}


function! s:operation_prototype.truncate_input(phase) abort "{{{
  let input = copy(self.input)
  if a:phase is# s:FIRST
    let input[0] = input[0][0:-2]
  elseif a:phase is# s:SECOND
    let input[1] = input[1][0:-2]
  else
    echoerr 'vim-swap: Invalid argument for operation.truncate_input()'
  endif
  return s:operation('swap', input)
endfunction "}}}


function! s:operation_prototype.get_input(phase) abort "{{{
  if a:phase is# s:FIRST
    return self.input[0]
  elseif a:phase is# s:SECOND
    return self.input[1]
  endif
  echoerr 'vim-swap: Invalid argument for operation.get_input()'
endfunction "}}}


function! s:operation(kind, input) abort "{{{
  let op = deepcopy(s:operation_prototype)
  let op.kind = a:kind
  let op.input = a:input
  return op
endfunction "}}}



" interface object - for interactive determination of swap actions
" swap#interface#new() returns a instance of this object
let s:interface_prototype = {
      \   'idx'  : {
      \     'current': -1,
      \     'end': -1,
      \     'last_current': -1,
      \     'selected': -1,
      \   },
      \   'buffer': {},
      \   'history': [],
      \   'undolevel': 0,
      \ }


" This function asks user to input keys to determine an operation
function! s:interface_prototype.query(buffer) dict abort "{{{
  if empty(a:buffer)
    return []
  endif

  let self.buffer = a:buffer
  let self.idx.current = -1
  let self.idx.last_current = -1
  let self.idx.selected = -1
  let self.idx.end = len(self.buffer.items) - 1

  let idx = self.buffer.index['#'] - 1
  if self.buffer.items[idx].string is# ''
    let idx = s:move_next_skipping_blank(self.buffer.items, idx)
  endif

  let phase = 0
  let op = s:operation('swap', ['', ''])
  let key_map = deepcopy(get(g:, 'swap#keymappings', g:swap#default_keymappings))
  call self.set_current(idx)
  call self.echo(phase, op)
  call self.highlight()
  redraw
  try
    while phase < s:DONE
      let funclist = s:query(key_map)
      let [phase, op] = self.call(funclist, phase, op)
    endwhile
  finally
    call self.clear_highlight()
    " clear messages
    echo ''
  endtry

  if phase is# s:CANCELLED
    return []
  endif

  if op.kind is# 'swap'
    call self.add_history(op)
  endif
  return op.input
endfunction "}}}


function! s:interface_prototype.echo(phase, op) dict abort "{{{
  if a:phase >= s:DONE
    return
  endif

  let max_len = &columns - 25
  let message = []

  for op in self.history[: -1*(self.undolevel+1)]
    let message += [[op.input[0], g:swap#hl_itemnr]]
    let message += [[g:swap#arrow, g:swap#hl_arrow]]
    let message += [[op.input[1], g:swap#hl_itemnr]]
    let message += [[', ', 'NONE']]
  endfor
  if a:phase is# s:FIRST
    if a:op.input[0] isnot# ''
      let higoup = self.idx.is_valid(a:op.input[0])
               \ ? g:swap#hl_itemnr : 'ErrorMsg'
      let message += [[a:op.input[0], higoup]]
    else
      if !empty(message)
        call remove(message, -1)
      endif
    endif
  elseif a:phase == 1
    if a:op.input[1] isnot# ''
      let message += [[a:op.input[0], g:swap#hl_itemnr]]
      let message += [[g:swap#arrow, g:swap#hl_arrow]]
      let higoup = self.idx.is_valid(a:op.input[1])
               \ ? g:swap#hl_itemnr : 'ErrorMsg'
      let message += [[a:op.input[1], higoup]]
    else
      let message += [[a:op.input[0], g:swap#hl_itemnr]]
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
      let precedes = precedes is# '' ? '<' : precedes
      call insert(message, [precedes, 'SpecialKey'])
    endif
  endif

  echohl ModeMsg
  echo 'Swap mode: '
  echohl NONE
  for mes in message
    call self.echon(mes[0], mes[1])
  endfor
endfunction "}}}


function! s:interface_prototype.echon(str, ...) dict abort "{{{
  let hl = get(a:000, 0, 'NONE')
  execute 'echohl ' . hl
  echon a:str
  echohl NONE
endfunction "}}}


function! s:interface_prototype.revise_cursor_pos() dict abort  "{{{
  let curpos = getpos('.')
  if self.idx.is_valid(self.idx.current)
    let item = self.buffer.items[self.idx.current]
    if s:lib.is_in_between(curpos, item.region.head, item.region.tail) && curpos != item.region.tail
      " no problem!
      return
    endif
  endif

  let head = self.buffer.items[0].region.head
  let tail = self.buffer.items[self.idx.end].region.tail
  let self.idx.last_current = self.idx.current
  if s:lib.is_ahead(head, curpos)
    let self.idx.current = -1
  elseif curpos == tail || s:lib.is_ahead(curpos, tail)
    let self.idx.current = self.idx.end + 1
  else
    let sharp = self.buffer.update_sharp(curpos)
    let self.idx.current = sharp - 1
  endif
  call self.update_highlight()
endfunction "}}}


function! s:interface_prototype.call(funclist, phase, op) abort "{{{
  let phase = a:phase
  let op = a:op
  for name in a:funclist
    let fname = 'swapmode_' . name
    let [phase, op] = self[fname](a:phase, op)
    if phase is# s:DONE
      break
    endif
  endfor
  call self.revise_cursor_pos()
  redraw
  return [phase, op]
endfunction "}}}


function! s:interface_prototype.add_history(op) dict abort  "{{{
  call self.truncate_history()
  call add(self.history, a:op)
endfunction "}}}


function! s:interface_prototype.truncate_history() dict abort  "{{{
  if self.undolevel == 0
    return self.history
  endif
  let endidx = -1*self.undolevel
  call remove(self.history, endidx, -1)
  let self.undolevel = 0
  return self.history
endfunction "}}}


function! s:interface_prototype.set_current(idx) dict abort "{{{
  call self.buffer.items[a:idx].cursor()

  " update side-scrolling
  " FIXME: Any standard way?
  if s:has_patch_7_4_311
    call winrestview({})
  endif

  let self.idx.last_current = self.idx.current
  let self.idx.current = a:idx
endfunction "}}}


function! s:interface_prototype.highlight() dict abort "{{{
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
endfunction "}}}


function! s:interface_prototype.clear_highlight() dict abort  "{{{
  call self.buffer.clear_highlight('items')
endfunction "}}}


function! s:interface_prototype.update_highlight() dict abort  "{{{
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
endfunction "}}}


let s:NOTHING = 0

function! s:interface_prototype.select(idxstr) abort "{{{
  let self.idx.selected = str2nr(a:idxstr) - 1
endfunction "}}}


function! s:interface_prototype.idx.is_valid(idx) dict abort  "{{{
  if type(a:idx) == s:TYPENUM
    return a:idx >= 0 && a:idx <= self.end
  elseif type(a:idx) == s:TYPESTR
    return str2nr(a:idx) >= 0 && str2nr(a:idx) <= self.end
  endif
  return 0
endfunction "}}}


function! s:query(key_map) abort "{{{
  let key_map = insert(copy(a:key_map), {'input': "\<Esc>", 'output': ['Esc']})   " for safety
  let clock = swap#clock#new()
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

    let c = type(c) == s:TYPENUM ? nr2char(c) : c
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
    let key = key_map[-1]
  else
    let key = {}
  endif
  return get(key, 'output', [])
endfunction "}}}


function! s:is_input_matched(candidate, input, flag) abort "{{{
  if !has_key(a:candidate, 'output') || !has_key(a:candidate, 'input')
    return 0
  endif

  if !a:flag && a:input is# ''
    return 1
  endif

  " If a:flag == 0, check forward match. Otherwise, check complete match.
  if a:flag
    return a:input is# a:candidate.input
  endif

  let idx = strlen(a:input) - 1
  return a:input is# a:candidate.input[: idx]
endfunction "}}}


function! s:move_prev_skipping_blank(items, current) abort  "{{{
  " skip empty items
  let idx = a:current - 1
  while idx >= 0
    if a:items[idx].string isnot# ''
      break
    endif
    let idx -= 1
  endwhile
  return idx < 0 ? a:current : idx
endfunction "}}}


function! s:move_next_skipping_blank(items, current) abort  "{{{
  " skip empty items
  let idx = a:current + 1
  let end = len(a:items) - 1
  while idx <= end
    if a:items[idx].string isnot# ''
      break
    endif
    let idx += 1
  endwhile
  return idx > end ? a:current : idx
endfunction "}}}


function! s:flip(input) abort "{{{
  return [a:input[1], a:input[0]]
endfunction "}}}


" NOTE: Key function list
"    {0~9} : Input {0~9} to specify an item.
"    CR    : Fix the input number. If nothing has been input, fix to the item under the cursor.
"    BS    : Erase the previous input.
"    undo  : Undo the current operation.
"    redo  : Redo the previous operation.
"    current : Fix to the item under the cursor.
"    move_prev : Move to the previous item.
"    move_next : Move to the next item.
"    swap_prev : Swap the current item with the previous item.
"    swap_next : Swap the current item with the next item.
function! s:interface_prototype.swapmode_nr(nr, phase, op) dict abort  "{{{
  if a:phase >= s:DONE
    return [a:phase, a:op]
  endif

  let op = a:op.append_input(a:phase, a:nr)
  call self.echo(a:phase, op)
  return [a:phase, op]
endfunction "}}}
function! s:interface_prototype.swapmode_0(phase, op) abort "{{{
  return self.swapmode_nr(0, a:phase, a:op)
endfunction "}}}
function! s:interface_prototype.swapmode_1(phase, op) abort "{{{
  return self.swapmode_nr(1, a:phase, a:op)
endfunction "}}}
function! s:interface_prototype.swapmode_2(phase, op) abort "{{{
  return self.swapmode_nr(2, a:phase, a:op)
endfunction "}}}
function! s:interface_prototype.swapmode_3(phase, op) abort "{{{
  return self.swapmode_nr(3, a:phase, a:op)
endfunction "}}}
function! s:interface_prototype.swapmode_4(phase, op) abort "{{{
  return self.swapmode_nr(4, a:phase, a:op)
endfunction "}}}
function! s:interface_prototype.swapmode_5(phase, op) abort "{{{
  return self.swapmode_nr(5, a:phase, a:op)
endfunction "}}}
function! s:interface_prototype.swapmode_6(phase, op) abort "{{{
  return self.swapmode_nr(6, a:phase, a:op)
endfunction "}}}
function! s:interface_prototype.swapmode_7(phase, op) abort "{{{
  return self.swapmode_nr(7, a:phase, a:op)
endfunction "}}}
function! s:interface_prototype.swapmode_8(phase, op) abort "{{{
  return self.swapmode_nr(8, a:phase, a:op)
endfunction "}}}
function! s:interface_prototype.swapmode_9(phase, op) abort "{{{
  return self.swapmode_nr(9, a:phase, a:op)
endfunction "}}}


function! s:interface_prototype.swapmode_CR(phase, op) dict abort  "{{{
  if a:phase >= s:DONE
    return [a:phase, a:op]
  endif

  let input = a:op.get_input(a:phase)
  if input is# ''
    return self.swapmode_current(a:phase, a:op)
  endif
  return self.key_fix_nr(a:phase, a:op)
endfunction "}}}


function! s:interface_prototype.swapmode_BS(phase, op) dict abort  "{{{
  let phase = a:phase
  let op = a:op
  if phase is# s:FIRST
    if a:op.get_input(s:FIRST) isnot# ''
      let op = a:op.truncate_input(s:FIRST)
      call self.echo(phase, op)
    endif
  elseif phase is# s:SECOND
    if a:op.get_input(s:SECOND) isnot# ''
      let op = a:op.truncate_input(s:SECOND)
    else
      let op = a:op.truncate_input(s:FIRST)
      let phase = s:FIRST
      call self.select(s:NOTHING)
      call self.update_highlight()
    endif
    call self.echo(phase, op)
  endif
  return [phase, op]
endfunction "}}}


function! s:interface_prototype.swapmode_undo(phase, op) dict abort "{{{
  if a:phase >= s:DONE
    return [a:phase, a:op]
  endif

  if len(self.history) <= self.undolevel
    return [a:phase, a:op]
  endif

  let phase = s:DONE
  let prev = self.history[-1*(self.undolevel+1)]
  let op = s:operation('undo', s:flip(prev.input))
  let self.undolevel += 1
  return [phase, op]
endfunction "}}}


function! s:interface_prototype.swapmode_redo(phase, op) dict abort "{{{
  if a:phase >= s:DONE
    return [a:phase, a:op]
  endif

  if self.undolevel == 0
    return [a:phase, a:op]
  endif

  let phase = s:DONE
  let next = self.history[-1*self.undolevel]
  let op = s:operation('redo', next.input)
  let self.undolevel -= 1
  return [phase, op]
endfunction "}}}


function! s:interface_prototype.swapmode_current(phase, op) dict abort "{{{
  let phase = a:phase
  let op = a:op.set_input(phase, string(self.idx.current) + 1)
  if phase is# s:FIRST
    let phase = s:SECOND
    call self.select(op.input[0])
    call self.echo(phase, op)
  elseif phase is# s:SECOND
    let phase = s:DONE
  endif
  return [phase, op]
endfunction "}}}


function! s:interface_prototype.swapmode_fix_nr(phase, op) dict abort "{{{
  if a:op.kind isnot# 'swap'
    return [a:phase, a:op]
  endif

  let phase = a:phase
  if phase is# s:FIRST
    let idx = str2nr(a:op.get_input(s:FIRST)) - 1
    if self.idx.is_valid(idx)
      call self.set_current(idx)
      let phase = s:SECOND
      call self.select(a:op.input[0])
      call self.echo(phase, a:op)
      call self.update_highlight()
    endif
  elseif phase is# s:SECOND
    let idx = str2nr(a:op.get_input(s:SECOND)) - 1
    if self.idx.is_valid(idx)
      let phase = s:DONE
    else
      call self.echo(phase, a:op)
    endif
  endif
  return [phase, a:op]
endfunction "}}}


function! s:interface_prototype.swapmode_move_prev(phase, op) dict abort  "{{{
  if a:phase >= s:DONE
    return [a:phase, a:op]
  endif

  if self.idx.current <= 0
    return [a:phase, a:op]
  endif

  let idx = s:move_prev_skipping_blank(
    \ self.buffer.items, min([self.idx.current, self.idx.end+1]))
  call self.set_current(idx)
  call self.update_highlight()
  return [a:phase, a:op]
endfunction "}}}


function! s:interface_prototype.swapmode_move_next(phase, op) dict abort  "{{{
  if a:phase >= s:DONE
    return [a:phase, a:op]
  endif

  if self.idx.current >= self.idx.end
    return [a:phase, a:op]
  endif

  let idx = s:move_next_skipping_blank(
    \ self.buffer.items, max([-1, self.idx.current]))
  call self.set_current(idx)
  call self.update_highlight()
  return [a:phase, a:op]
endfunction "}}}


function! s:interface_prototype.swapmode_swap_prev(phase, op) dict abort  "{{{
  if a:phase >= s:DONE
    return [a:phase, a:op]
  endif

  if self.idx.current <= 0 || self.idx.current > self.idx.end
    return [a:phase, a:op]
  endif

  let input = [self.idx.current+1, self.idx.current]
  let op = s:operation('swap', input)
  let phase = s:DONE
  return [phase, op]
endfunction "}}}


function! s:interface_prototype.swapmode_swap_next(phase, op) dict abort  "{{{
  if a:phase >= s:DONE
    return [a:phase, a:op]
  endif

  if self.idx.current < 0 || self.idx.current >= self.idx.end
    return [a:phase, a:op]
  endif

  let input = [self.idx.current+1, self.idx.current+2]
  let op = s:operation('swap', input)
  let phase = s:DONE
  return [phase, op]
endfunction "}}}


function! s:interface_prototype.swapmode_Esc(phase, op) dict abort  "{{{
  if a:phase >= s:DONE
    return [a:phase, a:op]
  endif

  if self.idx.current < 0 && self.idx.current >= self.idx.end
    return [a:phase, a:op]
  endif

  call self.echo(a:phase, a:op)
  let phase = s:CANCELLED
  return [phase, a:op]
endfunction "}}}


" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" vim:set ts=2 sts=2 sw=2:
