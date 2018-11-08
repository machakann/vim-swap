" Buffer - represents a region of the buffer swappped as delimited items

let s:Const = swap#constant#import()
let s:Lib = swap#lib#import()

let s:TRUE = 1
let s:FALSE = 0
let s:TYPENUM = s:Const.TYPENUM
let s:TYPESTR = s:Const.TYPESTR
let s:NULLREGION = s:Const.NULLREGION


function! swap#buffer#import() abort "{{{
  return s:Buffers
endfunction "}}}


" Item object - represents an swappable item on the buffer {{{
let s:Item = extend({
  \   'idx': -1,
  \   'attr': '',
  \   'str': '',
  \   'highlightid': [],
  \ }, deepcopy(s:NULLREGION))
function! s:Item.cursor(...) abort "{{{
  let to_tail = get(a:000, 0, 0)
  if to_tail
    call setpos('.', self.tail)
  else
    call setpos('.', self.head)
  endif
endfunction "}}}


function! s:Item.highlight(group) abort "{{{
  if self.len <= 0
    return
  endif

  let n = 0
  let order = []
  let order_list = []
  let lines = split(self.str, '\n\zs')
  let n_lines = len(lines)
  if n_lines == 1
    let order = [self.head[1:2] + [self.len]]
    let order_list = [order]
  else
    for i in range(n_lines)
      if i == 0
        let order += [self.head[1:2] + [strlen(lines[0])]]
      elseif i == n_lines-1
        let order += [[self.head[1] + i, 1, strlen(lines[i])]]
      else
        let order += [[self.head[1] + i]]
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
endfunction "}}}


function! s:Item.clear_highlight() abort  "{{{
  call filter(map(self.highlightid, 's:matchdelete(v:val)'), 'v:val > 0')
endfunction "}}}


function! s:Item(idx, attr, str) abort "{{{
  let item = deepcopy(s:Item)
  let item.idx = a:idx
  let item.attr = a:attr
  let item.str = a:str
  return item
endfunction "}}}


" function! s:matchaddpos(group, pos) abort "{{{
if exists('*matchaddpos')
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
endfunction "}}}
"}}}


" Buffer object - represents a swapping region of buffer {{{
let s:Buffer = extend({
  \   'all': [],
  \   'items': [],
  \   'mark': {'#': 0, '^': 0, '$': 0},
  \ }, deepcopy(s:NULLREGION))


function! s:Buffer.swappable() abort  "{{{
  " Check whether the region matches with the conditions to treat as the target.
  " NOTE: The conditions are the following three.
  "       1. Include two items at least.
  "       2. Not less than one of the item is not empty.
  "       3. Include one delimiter at least.
  if len(self.items) < 2
    return s:FALSE
  endif
  if filter(copy(self.items), 'v:val.str isnot# ""') == []
    return s:FALSE
  endif
  if filter(copy(self.all), 'v:val.attr is# "delimiter"') == []
    return s:FALSE
  endif
  return s:TRUE
endfunction "}}}


function! s:Buffer.selectable() abort  "{{{
  return filter(copy(self.items), 'v:val.str isnot# ""') != []
endfunction "}}}


function! s:Buffer.update_items() abort "{{{
  call s:address_{self.type}wise(self)
  call map(self.all, 'extend(v:val, {"idx": v:key})')
endfunction "}}}


function! s:Buffer.update_sharp(curpos) abort "{{{
  let sharp = 0
  if self.all != []
    if s:Lib.in_order_of(a:curpos, self.head)
      let sharp = 1
    else
      for text in self.items
        let sharp += 1
        if s:Lib.in_order_of(a:curpos, text.tail)
          break
        endif
      endfor
      if sharp > len(self.items)
        let sharp = len(self.items)
      endif
    endif
  endif
  let self.mark['#'] = sharp
  return sharp
endfunction "}}}


function! s:Buffer.update_hat() abort "{{{
  let hat = 0
  for text in self.items
    let hat += 1
    if text.str isnot# ''
      break
    endif
  endfor
  let self.mark['^'] = hat
  return hat
endfunction "}}}


function! s:Buffer.update_dollar() abort "{{{
  let dollar = len(self.items)
  let self.mark['$'] = dollar
  return dollar
endfunction "}}}


function! s:Buffer.is_valid(pos) abort "{{{
  return a:pos >= 1 && a:pos <= len(self.items)
endfunction "}}}


" Evaluate 'pos' expression string
function! s:Buffer.eval(pos) abort "{{{
  let str = a:pos
  for [symbol, symbolpos] in items(self.mark)
    if stridx(str, symbol) > -1
      let str = s:substitute_symbol(str, symbol, symbolpos)
    endif
  endfor
  sandbox let pos = eval(str)
  return pos
endfunction "}}}


" Sanitize and materialize a position
function! s:Buffer.get_pos(pos, ...) abort "{{{
  if type(a:pos) is# s:TYPENUM
    " 1, 2, 3, ...
    if self.is_valid(a:pos)
      return a:pos
    else
      let clamp = get(a:000, 0, s:FALSE)
      return clamp ? s:clamp(a:pos, 1, len(self.items)) : 0
    endif
  elseif type(a:pos) is# s:TYPESTR
    if a:pos =~# '\m^\d\+$'
      " '1', '2', '3', ...
      return self.get_pos(str2nr(a:pos))
    else
      if has_key(self.mark, a:pos)
        " '^', '#', '$', ...
        return self.mark[a:pos]
      else
        " '^+1', '#-1', '#+1', '$-1', ...
        return self.eval(a:pos)
      endif
    endif
  endif
  echoerr printf('vim-swap: Invalid argument for Buffer.get_pos(); %s [type: %d]',
          \ string(a:pos), type(a:pos))
endfunction "}}}


function! s:Buffer.get_item(pos, ...) abort "{{{
  let clamp = get(a:000, 0, s:FALSE)
  let pos = self.get_pos(a:pos, clamp)
  if pos is# 0
    return {}
  endif
  return self.items[pos - 1]
endfunction "}}}


function! s:address_charwise(buffer) abort  "{{{
  let pos = copy(a:buffer.head)
  for item in a:buffer.all
    if stridx(item.str, "\n") < 0
      let len = strlen(item.str)
      let item.len  = len
      let item.head = copy(pos)
      let pos[2] += len
      let item.tail = copy(pos)
    else
      let lines = split(item.str, '\n\zs', 1)
      let item.len  = strlen(item.str)
      let item.head = copy(pos)
      let pos[1] += len(lines) - 1
      let pos[2] = strlen(lines[-1]) + 1
      let item.tail = copy(pos)
    endif
  endfor
  return a:buffer
endfunction "}}}


function! s:address_linewise(buffer) abort  "{{{
  let lnum = a:buffer.head[1]
  for item in a:buffer.all
    if item.attr is# 'item'
      let len = strlen(item.str)
      let item.len  = len
      let item.head = [0, lnum, 1, 0]
      let item.tail = [0, lnum, len+1, 0]
    elseif item.attr is# 'delimiter'
      let item.len = 1
      let item.head = [0, lnum, col([lnum, '$']), 0]
      let item.tail = [0, lnum+1, 1, 0]
      let lnum += 1
    endif
  endfor
  return a:buffer
endfunction "}}}


function! s:address_blockwise(buffer) abort  "{{{
  let view = winsaveview()
  let lnum = a:buffer.head[1]
  let virtcol = a:buffer.head[2]
  for item in a:buffer.all
    if item.attr is# 'item'
      let col = s:Lib.virtcol2col(lnum, virtcol)
      let len = strlen(item.str)
      let item.len  = len
      let item.head = [0, lnum, col, 0]
      let item.tail = [0, lnum, col+len, 0]
    elseif item.attr is# 'delimiter'
      let item.len = 0
      let item.head = [0, lnum, col+len, 0]
      let item.tail = [0, lnum, col+len, 0]
      let lnum += 1
    endif
  endfor
  call winrestview(view)
  return a:buffer
endfunction "}}}


function! s:substitute_symbol(str, symbol, symbol_idx) abort "{{{
  let symbol = s:Lib.escape(a:symbol)
  return substitute(a:str, symbol, a:symbol_idx, '')
endfunction "}}}


function! s:clamp(x, lo, hi) abort "{{{
  return max([a:lo, min(a:x, a:hi)])
endfunction "}}}
"}}}


let s:Buffers = {}


function! s:Buffers.Buffer(region, parseditems) abort "{{{
  let buffer = deepcopy(s:Buffer)
  let buffer.all = map(copy(a:parseditems),
  \                    's:Item(v:key, v:val.attr, v:val.str)')
  let buffer.items = filter(copy(buffer.all), 'v:val.attr is# "item"')
  call extend(buffer, deepcopy(a:region))
  return buffer
endfunction "}}}


" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" vim:set ts=2 sts=2 sw=2:
