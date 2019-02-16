" Buffer - represents a region of the buffer swappped as delimited tokens

let s:Const = swap#constant#import()
let s:Lib = swap#lib#import()

let s:TRUE = 1
let s:FALSE = 0
let s:TYPENUM = s:Const.TYPENUM
let s:TYPESTR = s:Const.TYPESTR
let s:NULLREGION = s:Const.NULLREGION


" Token object - represents an swappable token on the buffer {{{
let s:Token = extend({
\   'attr': '',
\   'str': '',
\   'higroup': '',
\   '_highlightid': [],
\ }, deepcopy(s:NULLREGION))

function! s:Token(attr, str, type) abort "{{{
  let token = deepcopy(s:Token)
  let token.attr = a:attr
  let token.str = a:str
  let token.type = a:type
  return token
endfunction "}}}


function! s:Token.cursor(...) abort "{{{
  let to_tail = get(a:000, 0, 0)
  if to_tail
    call setpos('.', self.tail)
  else
    call setpos('.', self.head)
  endif
endfunction "}}}


function! s:Token.highlight(higroup) abort "{{{
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
    let self._highlightid += s:matchaddpos(a:higroup, order)
  endfor
  let self.higroup = a:higroup
endfunction "}}}


function! s:Token.clear_highlight() abort  "{{{
  let self.higroup = ''
  if empty(self._highlightid)
    return
  endif
  call filter(map(self._highlightid, 's:matchdelete(v:val)'), 'v:val > 0')
endfunction "}}}


" function! s:matchaddpos(higroup, pos) abort "{{{
if exists('*matchaddpos')
  function! s:matchaddpos(higroup, pos) abort
    return [matchaddpos(a:higroup, a:pos)]
  endfunction
else
  function! s:matchaddpos(higroup, pos) abort
    let id_list = []
    for pos in a:pos
      if len(pos) == 1
        let id_list += [matchadd(a:higroup, printf('\%%%dl', pos[0]))]
      else
        let id_list += [matchadd(a:higroup, printf('\%%%dl\%%>%dc.*\%%<%dc', pos[0], pos[1]-1, pos[1]+pos[2]))]
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


" Grouped Token - represents a token grouping other multiple tokens {{{
let s:GroupedToken = extend(deepcopy(s:Token),{
\   'including': [],
\ })

function! s:GroupedToken(tokens) abort "{{{
  let token = deepcopy(s:GroupedToken)
  let token.attr = 'itemgroup'
  let token.including = a:tokens
  call token.update()
  return token
endfunction "}}}


function! s:GroupedToken.highlight(higroup) abort "{{{
  for item in self.including
    call item.highlight(a:higroup)
  endfor
  let self.higroup = a:higroup
endfunction "}}}


function! s:GroupedToken.clear_highlight() abort  "{{{
  for item in self.including
    call item.clear_highlight()
  endfor
  let self.higroup = ''
endfunction "}}}


function! s:GroupedToken.update() abort "{{{
  let stack = copy(self.including)
  while !empty(stack)
    let item = remove(stack, -1)
    if item.attr is# 'itemgroup'
      call item.update()
      call extend(stack, item.including)
    endif
  endwhile
  return s:update(self)
endfunction "}}}


function! s:update(itemgroup) abort "{{{
  let a:itemgroup.head = a:itemgroup.including[0].head
  let a:itemgroup.tail = a:itemgroup.including[-1].tail
  let a:itemgroup.type = a:itemgroup.including[0].type
  let a:itemgroup.str = join(map(copy(a:itemgroup.including), 'v:val.str'), '')
  let a:itemgroup.len = strlen(a:itemgroup.str)
  return a:itemgroup
endfunction "}}}


" This method returns a shallow copy of GroupToken.including with ungrouping
function! s:GroupedToken.flatten() abort "{{{
  let list = copy(self.including)
  while !s:flatten_done(list)
    let list = s:flatten(list)
  endwhile
  return list
endfunction "}}}


function! s:flatten(list) abort "{{{
  let list = []
  for item in a:list
    if item.attr is# 'itemgroup'
      let list += item.including
    else
      let list += [item]
    endif
  endfor
  return list
endfunction "}}}


function! s:flatten_done(list) abort "{{{
  return empty(filter(copy(a:list), 'v:val.attr is# "itemgroup"'))
endfunction "}}}
"}}}


" Buffer object - represents a swapping region of buffer {{{
let s:Buffer = extend({
\   'all': [],
\   'items': [],
\   'mark': {'#': 0, '^': 0, '$': 0},
\ }, deepcopy(s:NULLREGION))

function! s:Buffer(tokens, region, curpos) abort "{{{
  let buffer = deepcopy(s:Buffer)
  let buffer.all =
  \ map(copy(a:tokens), 's:Token(v:val.attr, v:val.str, a:region.type)')
  let buffer.items = filter(copy(buffer.all), 'v:val.attr is# "item"')
  call extend(buffer, deepcopy(a:region))
  call buffer.update_tokens()
  call buffer.update_sharp(a:curpos)
  call buffer.update_hat()
  call buffer.update_dollar()
  return buffer
endfunction "}}}


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


function! s:Buffer.update_tokens() abort "{{{
  call s:address_{self.type}wise(self)
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
  elseif type(a:pos) is# s:TYPESTR && a:pos isnot# ''
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
  \              string(a:pos), type(a:pos))
endfunction "}}}


function! s:Buffer.get_item(pos, ...) abort "{{{
  let clamp = get(a:000, 0, s:FALSE)
  let pos = self.get_pos(a:pos, clamp)
  if pos is# 0
    return {}
  endif
  return self.items[pos - 1]
endfunction "}}}


function! s:Buffer.group(start, end) abort "{{{
  let start = self.get_pos(a:start) - 1
  let end = self.get_pos(a:end) - 1
  if start < 0 || end < 0 || start >= end
    return
  endif

  let token_list = remove(self.items, start, end)
  let grouped = s:GroupedToken(token_list)
  call insert(self.items, grouped, start)
  call self.update_hat()
  call self.update_sharp(getpos('.'))
  call self.update_dollar()
endfunction "}}}


function! s:Buffer.ungroup(pos) abort "{{{
  let itemgroup = self.get_item(a:pos)
  if get(itemgroup, 'attr', '') isnot# 'itemgroup'
    return
  endif
  if empty(itemgroup.including)
    return
  endif

  let i0 = self.get_pos(a:pos) - 1
  call remove(self.items, i0)
  for [i, item] in s:Lib.enumerate(itemgroup.including)
    call insert(self.items, item, i0 + i)
  endfor
endfunction "}}}


function! s:Buffer.breakup(pos) abort "{{{
  let itemgroup = self.get_item(a:pos)
  if get(itemgroup, 'attr', '') isnot# 'itemgroup'
    return
  endif
  if empty(itemgroup.including)
    return
  endif

  let i0 = self.get_pos(a:pos) - 1
  call remove(self.items, i0)
  for [i, item] in s:Lib.enumerate(itemgroup.flatten())
    call insert(self.items, item, i0 + i)
  endfor
endfunction "}}}


function! s:address_charwise(buffer) abort  "{{{
  let pos = copy(a:buffer.head)
  for token in a:buffer.all
    if stridx(token.str, "\n") < 0
      let len = strlen(token.str)
      let token.len  = len
      let token.head = copy(pos)
      let pos[2] += len
      let token.tail = copy(pos)
    else
      let lines = split(token.str, '\n\zs', 1)
      let token.len  = strlen(token.str)
      let token.head = copy(pos)
      let pos[1] += len(lines) - 1
      let pos[2] = strlen(lines[-1]) + 1
      let token.tail = copy(pos)
    endif
  endfor
  for item in a:buffer.items
    if item.attr is# 'itemgroup'
      call item.update()
    endif
  endfor
  return a:buffer
endfunction "}}}


function! s:address_linewise(buffer) abort  "{{{
  let lnum = a:buffer.head[1]
  for token in a:buffer.all
    if token.attr is# 'item'
      let len = strlen(token.str)
      let token.len  = len
      let token.head = [0, lnum, 1, 0]
      let token.tail = [0, lnum, len+1, 0]
    elseif token.attr is# 'delimiter'
      let token.len = 1
      let token.head = [0, lnum, col([lnum, '$']), 0]
      let token.tail = [0, lnum+1, 1, 0]
      let lnum += 1
    endif
  endfor
  for item in a:buffer.items
    if item.attr is# 'itemgroup'
      call item.update()
    endif
  endfor
  return a:buffer
endfunction "}}}


function! s:address_blockwise(buffer) abort  "{{{
  let view = winsaveview()
  let lnum = a:buffer.head[1]
  let virtcol = a:buffer.head[2]
  for token in a:buffer.all
    if token.attr is# 'item'
      let col = s:Lib.virtcol2col(lnum, virtcol)
      let len = strlen(token.str)
      let token.len  = len
      let token.head = [0, lnum, col, 0]
      let token.tail = [0, lnum, col+len, 0]
    elseif token.attr is# 'delimiter'
      let token.len = 0
      let token.head = [0, lnum, col+len, 0]
      let token.tail = [0, lnum, col+len, 0]
      let lnum += 1
    endif
  endfor
  for item in a:buffer.items
    if item.attr is# 'itemgroup'
      call item.update()
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


let s:BufferModule = {}
let s:BufferModule.Buffer = function('s:Buffer')

function! swap#buffer#import() abort "{{{
  return s:BufferModule
endfunction "}}}


" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" vim:set ts=2 sts=2 sw=2:
