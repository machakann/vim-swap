" item object - A text item on the buffer

let s:null_pos    = [0, 0, 0, 0]
let s:null_region = {'head': copy(s:null_pos), 'tail': copy(s:null_pos), 'len': -1, 'type': ''}

" patches
if v:version > 704 || (v:version == 704 && has('patch237'))
  let s:has_patch_7_4_362 = has('patch-7.4.362')
else
  let s:has_patch_7_4_362 = v:version == 704 && has('patch362')
endif

function! swap#item#get(item) abort "{{{
  return extend(a:item, deepcopy(s:item_prototype), 'keep')
endfunction
"}}}

let s:item_prototype = {
      \   'attr': '',
      \   'string': '',
      \   'highlightid': [],
      \   'region': deepcopy(s:null_region),
      \ }
function! s:item_prototype.cursor(...) dict abort "{{{
  let to_tail = get(a:000, 0, 0)
  if to_tail
    call setpos('.', self.region.tail)
  else
    call setpos('.', self.region.head)
  endif
endfunction
"}}}
function! s:item_prototype.highlight(group) dict abort "{{{
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
function! s:item_prototype.clear_highlight() dict abort  "{{{
  call filter(map(self.highlightid, 's:matchdelete(v:val)'), 'v:val > 0')
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

" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" vim:set ts=2 sts=2 sw=2:
