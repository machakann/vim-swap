" Rule object - Describe the rule of swapping action.

let s:const = swap#constant#import()
let s:NULLCOORD = s:const.NULLCOORD
let s:NULLPOS = s:const.NULLPOS
let s:NULLREGION = s:const.NULLREGION
let s:lib = swap#lib#import()


function! swap#rule#get(rule) abort "{{{
  return extend(a:rule, deepcopy(s:Rule), 'force')
endfunction "}}}


let s:Rule = {
      \   'region': deepcopy(s:NULLREGION)
      \ }


function! s:Rule.search(curpos, motionwise) dict abort  "{{{
  let timeout = g:swap#stimeoutlen
  if has_key(self, 'body')
    if self.region == s:NULLREGION
      let self.region = s:search_body(self.body, a:curpos, timeout)
      if self.region != s:NULLREGION && s:lib.is_in_between(a:curpos, self.region.head, self.region.tail)
        let self.region.len = s:lib.get_buf_length(self.region)
        let self.region.type = a:motionwise
        return self.region
      endif
    endif
  elseif has_key(self, 'surrounds')
    let nest = get(self.surrounds, -1, 0)
    if self.region == s:NULLREGION
      let pos = [a:curpos, a:curpos]
    else
      let pos = s:get_outer_pos(self.surrounds, self.region)
    endif
    let self.region = s:search_surrounds(self.surrounds, pos, nest, timeout)
    if self.region != s:NULLREGION
      let [head, tail] = s:get_outer_pos(self.surrounds, self.region)
      if s:lib.is_in_between(a:curpos, head, tail)
        let self.region.len = s:lib.get_buf_length(self.region)
        let self.region.type = a:motionwise
        return self.region
      endif
    endif
  endif
  let self.region = deepcopy(s:NULLREGION)
  return self.region
endfunction "}}}


function! s:Rule.match(region) dict abort  "{{{
  let timeout = g:swap#stimeoutlen

  if has_key(self, 'body')
    if s:match_body(self.body, a:region, timeout)
      let self.region = a:region
      return 1
    else
      return 0
    endif
  endif

  if has_key(self, 'surrounds')
    if s:match_surrounds(self.surrounds, a:region, timeout)
      let self.region = a:region
      return 1
    else
      return 0
    endif
  endif

  return 1
endfunction "}}}


function! s:Rule.initialize() dict abort  "{{{
  let self.region = deepcopy(s:NULLREGION)
  return self
endfunction "}}}


function! s:search_body(body, pos, timeout) abort "{{{
  call setpos('.', a:pos)
  let head = searchpos(a:body, 'cbW',  0, a:timeout)
  if head == s:NULLCOORD | return deepcopy(s:NULLREGION) | endif
  let head = s:lib.c2p(head)
  let tail = searchpos(a:body, 'eW', 0, a:timeout)
  if tail == s:NULLCOORD | return deepcopy(s:NULLREGION) | endif
  let tail = s:lib.c2p(tail)
  if s:lib.is_ahead(tail, head) && s:lib.is_in_between(a:pos, head, tail)
    let target = extend(deepcopy(s:NULLREGION), {'head': head, 'tail': tail}, 'force')
  else
    let target = deepcopy(s:NULLREGION)
  endif
  return target
endfunction "}}}


function! s:search_surrounds(surrounds, pos, nest, timeout) abort "{{{
  if a:pos[0] == s:NULLPOS || a:pos[1] == s:NULLPOS
    return deepcopy(s:NULLREGION)
  endif

  call setpos('.', a:pos[1])
  if a:nest
    let tail = s:searchpos_nested_tail(a:surrounds, a:timeout)
  else
    let tail = s:searchpos_nonest_tail(a:surrounds, a:timeout)
  endif
  if tail == s:NULLCOORD | return deepcopy(s:NULLREGION) | endif

  if a:nest
    let head = s:searchpos_nested_head(a:surrounds, a:timeout)
  else
    call setpos('.', a:pos[0])
    let head = s:searchpos_nonest_head(a:surrounds, a:timeout)
  endif
  if head == s:NULLCOORD | return deepcopy(s:NULLREGION) | endif

  let tail = s:lib.get_left_pos(s:lib.c2p(tail))
  let head = s:lib.get_right_pos(s:lib.c2p(head))
  return extend(deepcopy(s:NULLREGION), {'head': head, 'tail': tail}, 'force')
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
  let is_matched = 1
  let cur_pos = getpos('.')
  call setpos('.', a:region.head)
  if getpos('.')[1:2] != searchpos(a:body, 'cnW', 0, a:timeout)
    let is_matched = 0
  endif
  if searchpos(a:body, 'enW', 0, a:timeout) != a:region.tail[1:2]
    let is_matched = 0
  endif
  call setpos('.', cur_pos)
  return is_matched
endfunction "}}}


function! s:match_surrounds(surrounds, region, timeout) abort "{{{
  " NOTE: s:match_surrounds does not match nesting.
  "       Maybe it is reasonable considering use cases.
  let is_matched = 1
  let cur_pos = getpos('.')
  if s:lib.get_left_pos(a:region.head)[1:2] != searchpos(a:surrounds[0], 'cenW', 0, a:timeout)
    let is_matched = 0
  endif
  if is_matched && s:lib.get_right_pos(a:region.tail)[1:2] != searchpos(a:surrounds[1], 'bcnW', 0, a:timeout)
    let is_matched = 0
  endif
  call setpos('.', cur_pos)
  return is_matched
endfunction "}}}


function! s:get_outer_pos(surrounds, region) abort  "{{{
  let timeout = g:swap#stimeoutlen
  call setpos('.', a:region.head)
  let head = s:lib.c2p(searchpos(a:surrounds[0], 'bW', 0, timeout))
  if head != s:NULLPOS
    let head = s:lib.get_left_pos(head)
  endif

  call setpos('.', a:region.tail)
  let tail = s:lib.c2p(searchpos(a:surrounds[1], 'eW', 0, timeout))
  if tail != s:NULLPOS
    let tail = s:lib.get_right_pos(tail)
  endif
  return [head, tail]
endfunction "}}}


" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" vim:set ts=2 sts=2 sw=2:
