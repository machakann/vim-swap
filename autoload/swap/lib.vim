" Lib - Miscellaneous functions library.

let s:Const = swap#constant#import()
let s:NULLPOS = s:Const.NULLPOS

" patches
if v:version > 704 || (v:version == 704 && has('patch237'))
  let s:has_patch_7_4_358 = has('patch-7.4.358')
else
  let s:has_patch_7_4_358 = v:version == 704 && has('patch358')
endif


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


function! s:sort(list, func, ...) abort "{{{
  " FIXME: The number of item in a:list would not be large, but if there was
  "        any efficient argorithm, I would rewrite here.
  let n = len(a:list)
  for i in range(n)
    if n - 2 >= i
      let min = n - 1
      for j in range(n - 2, i, -1)
        if call(a:func, [a:list[min], a:list[j]] + a:000) >= 1
          let min = j
        endif
      endfor

      if min > i
        call insert(a:list, remove(a:list, min), i)
      endif
    endif
  endfor
  return a:list
endfunction "}}}


function! s:compare_ascend(i, j) abort "{{{
  return a:i.str is# a:j.str ? 0 : a:i.str < a:j.str ? -1 : 1
endfunction "}}}


function! s:compare_descend(i, j) abort "{{{
  return a:i.str is# a:j.str ? 0 : a:i.str > a:j.str ? -1 : 1
endfunction "}}}


function! s:is_valid_region(region) abort "{{{
  return a:region.head != s:Const.NULLPOS && a:region.tail != s:Const.NULLPOS &&
  \     (a:region.type is# 'line' || s:in_order_of(a:region.head, a:region.tail))
endfunction "}}}


" Return true is pos2 is later than pos1 on the buffer
" NOTE: Return false even if pos1 == pos2
function! s:in_order_of(pos1, pos2) abort  "{{{
  return a:pos1[1] < a:pos2[1] || (a:pos1[1] == a:pos2[1] && a:pos1[2] < a:pos2[2])
endfunction "}}}


function! s:is_in_between(pos, head, tail) abort  "{{{
  return a:pos != s:NULLPOS && a:head != s:NULLPOS && a:tail != s:NULLPOS &&
  \     (a:pos[1] > a:head[1] || (a:pos[1] == a:head[1] && a:pos[2] >= a:head[2])) &&
  \     (a:pos[1] < a:tail[1] || (a:pos[1] == a:tail[1] && a:pos[2] <= a:tail[2]))
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
  return a:type is# 'char' ? 'v' :
  \      a:type is# 'line' ? 'V' :
  \      a:type is# 'block' ? "\<C-v>" :
  \      a:type
endfunction "}}}


function! s:v2type(v) abort "{{{
  return a:v is# 'v' ? 'char' :
  \      a:v is# 'V' ? 'line' :
  \      a:v is# "\<C-v>" ? 'block' :
  \      a:v
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


function! s:enumerate(list) abort "{{{
  return map(copy(a:list), '[v:key, v:val]')
endfunction "}}}


" This is a matchstrpos() implementation for old vim
" NOTE: expr should be string, list is not supported
function! s:matchstrpos(expr, pat, ...) abort "{{{
  let str = call('matchstr', [a:expr, a:pat] + a:000)
  let start = call('match', [a:expr, a:pat] + a:000)
  let end = call('matchend', [a:expr, a:pat] + a:000)
  return [str, start, end]
endfunction "}}}


unlet! s:Lib
let s:Lib = {}
let s:Lib.get_buf_length = function('s:get_buf_length')
let s:Lib.buf_byte_len = function('s:buf_byte_len')
let s:Lib.c2p = function('s:c2p')
let s:Lib.sort = s:has_patch_7_4_358 ? function('sort') : function('s:sort')
let s:Lib.compare_ascend = function('s:compare_ascend')
let s:Lib.compare_descend = function('s:compare_descend')
let s:Lib.is_valid_region = function('s:is_valid_region')
let s:Lib.in_order_of = function('s:in_order_of')
let s:Lib.is_in_between = function('s:is_in_between')
let s:Lib.escape = function('s:escape')
let s:Lib.virtcol2col = function('s:virtcol2col')
let s:Lib.type2v = function('s:type2v')
let s:Lib.v2type = function('s:v2type')
let s:Lib.get_left_pos = function('s:get_left_pos')
let s:Lib.get_right_pos = function('s:get_right_pos')
let s:Lib.enumerate = function('s:enumerate')
let s:Lib.matchstrpos = exists('*matchstrpos') ? function('matchstrpos')
\                                              : function('s:matchstrpos')
lockvar! s:Lib


function! swap#lib#import() abort "{{{
  return s:Lib
endfunction "}}}


" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" vim:set ts=2 sts=2 sw=2:
