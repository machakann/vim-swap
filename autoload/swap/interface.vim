" interface object - Interactive order determination, "swap mode".

let s:type_str = type('')
let s:type_num = type(0)

" patches
if v:version > 704 || (v:version == 704 && has('patch237'))
  let s:has_patch_7_4_311 = has('patch-7.4.311')
else
  let s:has_patch_7_4_311 = v:version == 704 && has('patch311')
endif

function! swap#interface#new() abort  "{{{
  let s:interface = deepcopy(s:interface_prototype)
  return s:interface
endfunction
"}}}

let s:interface_prototype = {
      \   'phase': 0,
      \   'order': ['', ''],
      \   'idx'  : {
      \     'current': -1,
      \     'end'    : -1,
      \     'last_current': -1,
      \     'selected': -1,
      \   },
      \   'buffer' : {},
      \   'escaped': 0,
      \   'history': [],
      \   'undolevel': 0,
      \ }
function! s:interface_prototype.query(buffer) dict abort "{{{
  if empty(a:buffer)
    return []
  endif

  let self.phase = 0
  let self.order = ['', '']
  let self.buffer = a:buffer
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

  " clear messages
  echo ''
  return self.order
endfunction
"}}}
function! s:interface_prototype.echo() dict abort "{{{
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
function! s:interface_prototype.echon(str, ...) dict abort "{{{
  let hl = get(a:000, 0, 'NONE')
  execute 'echohl ' . hl
  echon a:str
  echohl NONE
endfunction
"}}}
function! s:interface_prototype.normal(key) dict abort "{{{
  if has_key(a:key, 'noremap') && a:key.noremap
    execute 'noautocmd normal! ' . a:key.output
  else
    execute 'noautocmd normal ' . a:key.output
  endif
endfunction
"}}}
function! s:interface_prototype.revise_cursor_pos() dict abort  "{{{
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
    let sharp = self.buffer.update_sharp(curpos)
    let self.idx.current = sharp - 1
  endif
  call self.update_highlight()
endfunction
"}}}
function! s:interface_prototype.add_history() dict abort  "{{{
  call self.truncate_history()
  call add(self.history, self.order)
  return self.history
endfunction
"}}}
function! s:interface_prototype.truncate_history() dict abort  "{{{
  if self.undolevel
    let endidx = -1*self.undolevel
    call remove(self.history, endidx, -1)
    let self.undolevel = 0
  endif
  return self.history
endfunction
"}}}
function! s:interface_prototype.set_current(idx) dict abort "{{{
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
endfunction
"}}}
function! s:interface_prototype.clear_highlight() dict abort  "{{{
  call self.buffer.clear_highlight('items')
endfunction
"}}}
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
endfunction
"}}}
function! s:interface_prototype.goto_phase(phase) dict abort "{{{
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
function! s:interface_prototype.exit() dict abort  "{{{
  call self.goto_phase(-2)
endfunction
"}}}
function! s:interface_prototype.undo_order() dict abort  "{{{
  let prev_order = self.history[-1*(self.undolevel+1)]
  return [prev_order[1], prev_order[0]]
endfunction
"}}}
function! s:interface_prototype.redo_order() dict abort  "{{{
  return copy(self.history[-1*self.undolevel])
endfunction
"}}}
function! s:interface_prototype.idx.is_valid(idx) dict abort  "{{{
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
function! s:interface_prototype.key_nr(nr) dict abort  "{{{
  if self.phase == 0 || self.phase == 1
    let self.order[self.phase] .= a:nr
    call self.echo()
  endif
endfunction
"}}}
function! s:interface_prototype.key_CR() dict abort  "{{{
  if get(self.order, self.phase, '') ==# ''
    call self.key_current()
  else
    call self.key_fix_nr()
  endif
endfunction
"}}}
function! s:interface_prototype.key_BS() dict abort  "{{{
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
function! s:interface_prototype.key_undo() dict abort "{{{
  if self.phase == 0 || self.phase == 1
    if len(self.history) > self.undolevel
      let self.order = self.undo_order()
      let self.undolevel += 1
      call self.exit()
    endif
  endif
endfunction
"}}}
function! s:interface_prototype.key_redo() dict abort "{{{
  if self.phase == 0 || self.phase == 1
    if self.undolevel
      let self.order = self.redo_order()
      let self.undolevel -= 1
      call self.exit()
    endif
  endif
endfunction
"}}}
function! s:interface_prototype.key_current() dict abort "{{{
  if self.phase == 0
    let self.order[0] = string(self.idx.current) + 1
    call self.goto_phase(1)
  elseif self.phase == 1
    let self.order[1] = string(self.idx.current) + 1
    call self.goto_phase(2)
  endif
endfunction
"}}}
function! s:interface_prototype.key_fix_nr() dict abort "{{{
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
function! s:interface_prototype.key_move_prev() dict abort  "{{{
  if self.phase == 0 || self.phase == 1
    if self.idx.current > 0
      let idx = s:move_prev_skipping_blank(self.buffer.items, min([self.idx.current, self.idx.end+1]))
      call self.set_current(idx)
      call self.update_highlight()
    endif
  endif
endfunction
"}}}
function! s:interface_prototype.key_move_next() dict abort  "{{{
  if self.phase == 0 || self.phase == 1
    if self.idx.current < self.idx.end
      let idx = s:move_next_skipping_blank(self.buffer.items, max([-1, self.idx.current]))
      call self.set_current(idx)
      call self.update_highlight()
    endif
  endif
endfunction
"}}}
function! s:interface_prototype.key_swap_prev() dict abort  "{{{
  if self.phase == 0 || self.phase == 1
    if self.idx.current > 0 && self.idx.current <= self.idx.end
      let self.order = [self.idx.current+1, self.idx.current]
      call self.goto_phase(2)
    endif
  endif
endfunction
"}}}
function! s:interface_prototype.key_swap_next() dict abort  "{{{
  if self.phase == 0 || self.phase == 1
    if self.idx.current >= 0 && self.idx.current < self.idx.end
      let self.order = [self.idx.current+1, self.idx.current+2]
      call self.goto_phase(2)
    endif
  endif
endfunction
"}}}

function! swap#interface#swapmode_key_nr(nr) abort  "{{{
  if exists('s:interface')
    call s:interface.key_nr(a:nr)
  endif
endfunction
"}}}
function! swap#interface#swapmode_key_CR() abort  "{{{
  if exists('s:interface')
    call s:interface.key_CR()
  endif
endfunction
"}}}
function! swap#interface#swapmode_key_BS() abort  "{{{
  if exists('s:interface')
    call s:interface.key_BS()
  endif
endfunction
"}}}
function! swap#interface#swapmode_key_undo() abort  "{{{
  if exists('s:interface')
    call s:interface.key_undo()
  endif
endfunction
"}}}
function! swap#interface#swapmode_key_redo() abort  "{{{
  if exists('s:interface')
    call s:interface.key_redo()
  endif
endfunction
"}}}
function! swap#interface#swapmode_key_current() abort  "{{{
  if exists('s:interface')
    call s:interface.key_current()
  endif
endfunction
"}}}
function! swap#interface#swapmode_key_fix_nr() abort  "{{{
  if exists('s:interface')
    call s:interface.key_fix_nr()
  endif
endfunction
"}}}
function! swap#interface#swapmode_key_move_prev() abort  "{{{
  if exists('s:interface')
    call s:interface.key_move_prev()
  endif
endfunction
"}}}
function! swap#interface#swapmode_key_move_next() abort  "{{{
  if exists('s:interface')
    call s:interface.key_move_next()
  endif
endfunction
"}}}
function! swap#interface#swapmode_key_swap_prev() abort  "{{{
  if exists('s:interface')
    call s:interface.key_swap_prev()
  endif
endfunction
"}}}
function! swap#interface#swapmode_key_swap_next() abort  "{{{
  if exists('s:interface')
    call s:interface.key_swap_next()
  endif
endfunction
"}}}
function! swap#interface#swapmode_key_echo() abort  "{{{
  if exists('s:interface')
    call s:interface.echo()
  endif
endfunction
"}}}
function! swap#interface#swapmode_key_ESC() abort  "{{{
  if exists('s:interface')
    call s:interface.echo()
    let s:interface.escaped = 1
  endif
endfunction
"}}}

let [s:is_ahead, s:is_in_between] = swap#lib#funcref(['is_ahead', 'is_in_between'])

" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" vim:set ts=2 sts=2 sw=2:
