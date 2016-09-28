" buffer object - The target of a swapping action.

let s:null_pos    = [0, 0, 0, 0]
let s:null_region = {'head': copy(s:null_pos), 'tail': copy(s:null_pos), 'len': -1, 'type': ''}

function! swap#buffer#new() abort "{{{
  return deepcopy(s:buffer_prototype)
endfunction
"}}}

let s:buffer_prototype = {
      \   'region': deepcopy(s:null_region),
      \   'all': [],
      \   'items': [],
      \   'delimiters': [],
      \   'symbols': {'#': 0, '^': 0, '$': 0},
      \ }
function! s:buffer_prototype.functionalize() dict abort "{{{
  return map(self.all, 'swap#item#get(v:val)')
endfunction
"}}}
function! s:buffer_prototype.clear_highlight(...) dict abort  "{{{
  " NOTE: This function itself does not redraw.
  if !g:swap#highlight
    return
  endif

  let section = get(a:000, 0, 'all')
  for text in self[section]
    if text.highlightid != []
      call text.clear_highlight()
    endif
  endfor
endfunction
"}}}
function! s:buffer_prototype.swappable() dict abort  "{{{
  " Check whether the region matches with the conditions to treat as the target.
  " NOTE: The conditions are the following three.
  "       1. Include two items at least.
  "       2. Not less than one of the item is not empty.
  "       3. Include one delimiter at least.
  let cond1 = len(self.items) >= 2
  let cond2 = filter(copy(self.items), 'v:val.string !=# ""') != []
  let cond3 = filter(copy(self.all), 'v:val.attr ==# "delimiter"') != []
  return cond1 && cond2 && cond3 ? 1 : 0
endfunction
"}}}
function! s:buffer_prototype.swap(i1, i2) dict abort  "{{{
  let item1 = s:extractall(self.items[a:i1])
  let item2 = s:extractall(self.items[a:i2])
  call extend(self.items[a:i1], item2, 'force')
  call extend(self.items[a:i2], item1, 'force')
endfunction
"}}}
function! s:buffer_prototype.address() dict abort "{{{
  return s:address_{self.region.type}wise(self.all, self.region)
endfunction
"}}}
function! s:buffer_prototype.get_sharp(curpos) dict abort "{{{
  let sharp = 0
  if self.all != []
    if s:is_ahead(self.all[0].region.head, a:curpos)
      let sharp = 1
    else
      for text in self.items
        let sharp += 1
        if s:is_ahead(text.region.tail, a:curpos)
          break
        endif
      endfor
      if sharp > len(self.items)
        let sharp = len(self.items)
      endif
    endif
  endif
  return sharp
endfunction
"}}}
function! s:buffer_prototype.set_sharp(curpos) dict abort "{{{
  let self.symbols['#'] = self.get_sharp(a:curpos)
endfunction
"}}}
function! s:buffer_prototype.get_hat() dict abort "{{{
  let hat = 0
  for text in self.items
    let hat += 1
    if text.string !=# ''
      break
    endif
  endfor
  return hat
endfunction
"}}}
function! s:buffer_prototype.set_hat() dict abort "{{{
  let self.symbols['^'] = self.get_hat()
endfunction
"}}}
function! s:buffer_prototype.get_dollar() dict abort "{{{
  return len(self.items)
endfunction
"}}}
function! s:buffer_prototype.set_dollar() dict abort "{{{
  let self.symbols['$'] = self.get_dollar()
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
function! s:address_charwise(buffer, region) abort  "{{{
  let pos = copy(a:region.head)
  for item in a:buffer
    if stridx(item.string, "\n") < 0
      let len = strlen(item.string)
      let item.region.len  = len
      let item.region.head = copy(pos)
      let pos[2] += len
      let item.region.tail = copy(pos)
    else
      let lines = split(item.string, '\n\zs', 1)
      let item.region.len  = strlen(item.string)
      let item.region.head = copy(pos)
      let pos[1] += len(lines) - 1
      let pos[2] = strlen(lines[-1]) + 1
      let item.region.tail = copy(pos)
    endif
  endfor
  return a:buffer
endfunction
"}}}
function! s:address_linewise(buffer, region) abort  "{{{
  let lnum = a:region.head[1]
  for item in a:buffer
    if item.attr ==# 'item'
      let len = strlen(item.string)
      let item.region.len  = len
      let item.region.head = [0, lnum, 1, 0]
      let item.region.tail = [0, lnum, len+1, 0]
    elseif item.attr ==# 'delimiter'
      let item.region.len = 1
      let item.region.head = [0, lnum, col([lnum, '$']), 0]
      let item.region.tail = [0, lnum+1, 1, 0]
      let lnum += 1
    endif
  endfor
  return a:buffer
endfunction
"}}}
function! s:address_blockwise(buffer, region) abort  "{{{
  let view = winsaveview()
  let lnum = a:region.head[1]
  let virtcol = a:region.head[2]
  for item in a:buffer
    if item.attr ==# 'item'
      let col = s:virtcol2col(lnum, virtcol)
      let len = strlen(item.string)
      let item.region.len  = len
      let item.region.head = [0, lnum, col, 0]
      let item.region.tail = [0, lnum, col+len, 0]
    elseif item.attr ==# 'delimiter'
      let item.region.len = 0
      let item.region.head = [0, lnum, col+len, 0]
      let item.region.tail = [0, lnum, col+len, 0]
      let lnum += 1
    endif
  endfor
  call winrestview(view)
  return a:buffer
endfunction
"}}}

let [s:is_ahead, s:virtcol2col] = swap#lib#funcref(['is_ahead', 'virtcol2col'])

" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" vim:set ts=2 sts=2 sw=2:
