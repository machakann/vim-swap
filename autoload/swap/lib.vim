" Lib - Miscellaneous functions library.

let s:const = swap#constant#import()
let s:NULLPOS = s:const.NULLPOS

" patches
if v:version > 704 || (v:version == 704 && has('patch237'))
  let s:has_patch_7_4_358 = has('patch-7.4.358')
else
  let s:has_patch_7_4_358 = v:version == 704 && has('patch358')
endif


function! swap#lib#import() abort "{{{
  return s:Lib
endfunction "}}}


function! s:get_buf_length(region) abort  "{{{
  return s:buf_byte_len(a:region.head, a:region.tail) + 1
endfunction "}}}


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
endfunction "}}}


function! s:c2p(coord) abort  "{{{
  return [0] + a:coord + [0]
endfunction "}}}


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


function! s:is_valid_region(region) abort "{{{
  return a:region.head != s:const.NULLPOS && a:region.tail != s:const.NULLPOS
        \ && (a:region.type is# 'line' || s:is_ahead(a:region.tail, a:region.head))
endfunction "}}}


function! s:is_ahead(pos1, pos2) abort  "{{{
  return a:pos1[1] > a:pos2[1] || (a:pos1[1] == a:pos2[1] && a:pos1[2] > a:pos2[2])
endfunction "}}}


function! s:is_in_between(pos, head, tail) abort  "{{{
  return a:pos != s:NULLPOS && a:head != s:NULLPOS && a:tail != s:NULLPOS
    \ && ((a:pos[1] > a:head[1]) || ((a:pos[1] == a:head[1]) && (a:pos[2] >= a:head[2])))
    \ && ((a:pos[1] < a:tail[1]) || ((a:pos[1] == a:tail[1]) && (a:pos[2] <= a:tail[2])))
endfunction "}}}


function! s:escape(string) abort  "{{{
  return escape(a:string, '~"\.^$[]*')
endfunction "}}}


function! s:virtcol2col(lnum, virtcol) abort  "{{{
  call cursor(a:lnum, 1)
  execute printf('normal! %d|', a:virtcol)
  return col('.')
endfunction "}}}


function! s:type2v(type) abort  "{{{
  return a:type is# 'line'  ? 'V'
     \ : a:type is# 'block' ? "\<C-v>"
     \ : 'v'
endfunction "}}}


function! s:get_left_pos(pos, ...) abort  "{{{
  call setpos('.', a:pos)
  if a:pos != [0, 1, 1, 0]
    execute printf('normal! %dh', get(a:000, 0, 1))
  endif
  return getpos('.')
endfunction "}}}


function! s:get_right_pos(pos, ...) abort  "{{{
  call setpos('.', a:pos)
  if a:pos != [0, line('$'), max([1, col('$') - 1]), 0]
    execute printf('normal! %dl', get(a:000, 0, 1))
  endif
  return getpos('.')
endfunction "}}}


let s:Lib = {}
let s:Lib.get_buf_length = function('s:get_buf_length')
let s:Lib.buf_byte_len = function('s:buf_byte_len')
let s:Lib.c2p = function('s:c2p')
let s:Lib.sort = function('s:sort')
let s:Lib.is_valid_region = function('s:is_valid_region')
let s:Lib.is_ahead = function('s:is_ahead')
let s:Lib.is_in_between = function('s:is_in_between')
let s:Lib.escape = function('s:escape')
let s:Lib.virtcol2col = function('s:virtcol2col')
let s:Lib.type2v = function('s:type2v')
let s:Lib.get_left_pos = function('s:get_left_pos')
let s:Lib.get_right_pos = function('s:get_right_pos')
lockvar! s:Lib


" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" vim:set ts=2 sts=2 sw=2:
