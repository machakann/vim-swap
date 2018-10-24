" textobj object - Select an item.

" The key mapping interface function. Use like this:
"   noremap <silent> i, :<C-u>call swap#textobj#select('i')<CR>
"   noremap <silent> a, :<C-u>call swap#textobj#select('a')<CR>
function! swap#textobj#select(type) abort "{{{
  let l:count = v:count1
  let TEXTOBJ = !!1
  let swap = swap#swap#new('n', [])
  let [buffer, rule] = swap.search('char', TEXTOBJ)
  if empty(buffer) || empty(buffer.items)
    return
  endif
  if a:type is# 'a'
    let [start, end] = s:get_target_a(buffer, l:count)
  elseif a:type is# 'i'
    let [start, end] = s:get_target_i(buffer, l:count)
  else
    return
  endif

  normal! v
  call setpos('.', start.region.head)
  normal! o
  call setpos('.', end.region.tail)
  if &selection isnot# 'exclusive'
    normal! h
  endif
endfunction "}}}


function! s:get_target_i(buffer, count) abort "{{{
  let cursoritemidx = a:buffer.index['#'] - 1
  let cursoritem = a:buffer.items[cursoritemidx]
  let lastitemidx = a:buffer.index['$'] - 1
  let enditemidx = min([cursoritemidx + a:count - 1, lastitemidx])
  let enditem = a:buffer.items[enditemidx]
  return [cursoritem, enditem]
endfunction "}}}


function! s:get_target_a(buffer, count) abort "{{{
  let [cursoritem, enditem] = s:get_target_i(a:buffer, a:count)
  let conj_delimiter = s:get_preconjugate_delimiter(a:buffer, cursoritem)
  if !empty(conj_delimiter)
    return [conj_delimiter, enditem]
  endif

  let conj_delimiter = s:get_postconjugate_delimiter(a:buffer, enditem)
  if !empty(conj_delimiter)
    return [cursoritem, conj_delimiter]
  endif
  return [cursoritem, enditem]
endfunction "}}}


function! s:get_preconjugate_delimiter(buffer, cursoritem) abort "{{{
  if a:cursoritem.idx < 0
    return {}
  endif

  if a:cursoritem.idx > 0
    for i in range(a:cursoritem.idx - 1, 0, -1)
      if a:buffer.all[i]['attr'] is# 'delimiter'
        return a:buffer.all[i]
      endif
    endfor
  endif
  return {}
endfunction "}}}


function! s:get_postconjugate_delimiter(buffer, enditem) abort "{{{
  if a:enditem.idx < 0
    return {}
  endif

  if a:enditem.idx < len(a:buffer.all) - 1
    for i in range(a:enditem.idx + 1, len(a:buffer.all) - 1)
      if a:buffer.all[i]['attr'] is# 'delimiter'
        return a:buffer.all[i]
      endif
    endfor
  endif
  return {}
endfunction "}}}


" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" vim:set ts=2 sts=2 sw=2:
