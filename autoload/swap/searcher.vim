" Searcher module - Search & match a swappable region on the current buffer

let s:Const = swap#constant#import()
let s:Lib = swap#lib#import()

let s:TRUE = 1
let s:FALSE = 0
let s:NULLCOORD = s:Const.NULLCOORD
let s:NULLPOS = s:Const.NULLPOS
let s:NULLREGION = s:Const.NULLREGION


let s:CONTINUE = 0
let s:DONE = 1

function! s:search(rule, region, curpos) abort  "{{{
  let timeout = g:swap#stimeoutlen
  if has_key(a:rule, 'body')
    let body = a:rule.body
    return s:search_body(body, a:curpos, timeout)
  elseif has_key(a:rule, 'surrounds')
    let surrounds = a:rule.surrounds
    let nest = get(surrounds, -1, 0)
    if a:region == s:NULLREGION
      let [head, tail] = [a:curpos, a:curpos]
    else
      let [head, tail] = s:get_outer_pos(a:region.head, a:region.tail, surrounds)
    endif
    return s:search_surrounds(surrounds, head, tail, a:curpos, nest, timeout)
  endif
  return [s:NULLREGION, s:DONE]
endfunction "}}}


function! s:match(rule, region) abort  "{{{
  let timeout = g:swap#stimeoutlen

  if has_key(a:rule, 'body')
    if s:match_body(a:rule.body, a:region, timeout)
      return s:TRUE
    else
      return s:FALSE
    endif
  endif

  if has_key(a:rule, 'surrounds')
    if s:match_surrounds(a:rule.surrounds, a:region, timeout)
      return s:TRUE
    else
      return s:FALSE
    endif
  endif

  return s:TRUE
endfunction "}}}


function! s:search_body(body, curpos, timeout) abort "{{{
  call setpos('.', a:curpos)
  let head = searchpos(a:body, 'cbW',  0, a:timeout)
  if head == s:NULLCOORD | return [s:NULLREGION, s:DONE] | endif
  let head = s:Lib.c2p(head)
  let tail = searchpos(a:body, 'eW', 0, a:timeout)
  if tail == s:NULLCOORD | return [s:NULLREGION, s:DONE] | endif
  let tail = s:Lib.c2p(tail)
  if !s:Lib.in_order_of(head, tail) ||
  \  !s:Lib.is_in_between(a:curpos, head, tail)
    return [s:NULLREGION, s:DONE]
  endif
  let region = deepcopy(s:NULLREGION)
  let region.head = head
  let region.tail = tail
  let region.len = s:Lib.get_buf_length(region)
  let region.type = 'char'
  return [region, s:DONE]
endfunction "}}}


function! s:search_surrounds(surrounds, serachhead, searchtail, curpos, nest, timeout) abort "{{{
  call setpos('.', a:searchtail)
  if a:nest
    let tail = s:searchpos_nested_tail(a:surrounds, a:timeout)
  else
    let tail = s:searchpos_nonest_tail(a:surrounds, a:timeout)
  endif
  if tail == s:NULLCOORD | return [s:NULLREGION, s:DONE] | endif

  if a:nest
    let head = s:searchpos_nested_head(a:surrounds, a:timeout)
  else
    call setpos('.', a:serachhead)
    let head = s:searchpos_nonest_head(a:surrounds, a:timeout)
  endif
  if head == s:NULLCOORD | return [s:NULLREGION, s:DONE] | endif

  let tail = s:Lib.get_left_pos(s:Lib.c2p(tail))
  let head = s:Lib.get_right_pos(s:Lib.c2p(head))
  let [surroundhead, surroundtail] = s:get_outer_pos(head, tail, a:surrounds)
  if !s:Lib.is_in_between(a:curpos, surroundhead, surroundtail)
    return [s:NULLREGION, s:DONE]
  endif
  let region = deepcopy(s:NULLREGION)
  let region.head = head
  let region.tail = tail
  let region.len = s:Lib.get_buf_length(region)
  let region.type = 'char'
  return [region, s:CONTINUE]
endfunction "}}}


function! s:searchpos_nested_head(pattern, timeout) abort  "{{{
  let coord = searchpairpos(a:pattern[0], '', a:pattern[1], 'bW', '', 0, a:timeout)
  if coord != s:NULLCOORD
    let coord = searchpos(a:pattern[0], 'ceW', 0, a:timeout)
  endif
  return coord
endfunction "}}}


function! s:searchpos_nested_tail(pattern, timeout) abort  "{{{
  if searchpos(a:pattern[0], 'cn', line('.')) == getpos('.')[1:2]
    normal! l
  endif
  return searchpairpos(a:pattern[0], '', a:pattern[1], 'cW', '', 0, a:timeout)
endfunction "}}}


function! s:searchpos_nonest_head(pattern, timeout) abort  "{{{
  call search(a:pattern[0], 'bW', 0, a:timeout)
  return searchpos(a:pattern[0], 'ceW', 0, a:timeout)
endfunction "}}}


function! s:searchpos_nonest_tail(pattern, timeout) abort  "{{{
  call search(a:pattern[1], 'ceW', 0, a:timeout)
  return searchpos(a:pattern[1], 'bcW', 0, a:timeout)
endfunction "}}}


function! s:match_body(body, region, timeout) abort "{{{
  let is_matched = s:TRUE
  let cur_pos = getpos('.')
  call setpos('.', a:region.head)
  if getpos('.')[1:2] != searchpos(a:body, 'cnW', 0, a:timeout)
    let is_matched = s:FALSE
  endif
  if searchpos(a:body, 'enW', 0, a:timeout) != a:region.tail[1:2]
    let is_matched = s:FALSE
  endif
  call setpos('.', cur_pos)
  return is_matched
endfunction "}}}


function! s:match_surrounds(surrounds, region, timeout) abort "{{{
  " NOTE: s:match_surrounds does not match nesting.
  "       Maybe it is reasonable considering use cases.
  let is_matched = s:TRUE
  let cur_pos = getpos('.')
  if s:Lib.get_left_pos(a:region.head)[1:2] != searchpos(a:surrounds[0], 'cenW', 0, a:timeout)
    let is_matched = s:FALSE
  endif
  if is_matched && s:Lib.get_right_pos(a:region.tail)[1:2] != searchpos(a:surrounds[1], 'bcnW', 0, a:timeout)
    let is_matched = s:FALSE
  endif
  call setpos('.', cur_pos)
  return is_matched
endfunction "}}}


function! s:get_outer_pos(head, tail, surrounds) abort  "{{{
  let timeout = g:swap#stimeoutlen
  call setpos('.', a:head)
  let head = s:Lib.c2p(searchpos(a:surrounds[0], 'bW', 0, timeout))
  if head != s:NULLPOS
    let head = s:Lib.get_left_pos(head)
  endif

  call setpos('.', a:tail)
  let tail = s:Lib.c2p(searchpos(a:surrounds[1], 'eW', 0, timeout))
  if tail != s:NULLPOS
    let tail = s:Lib.get_right_pos(tail)
  endif
  return [head, tail]
endfunction "}}}


let s:Seacher = {}
let s:Seacher.search = function('s:search')
let s:Seacher.match = function('s:match')


function! swap#searcher#import() abort "{{{
  return s:Seacher
endfunction "}}}


" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" vim:set ts=2 sts=2 sw=2:
