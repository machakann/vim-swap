" rule object - Describe the rule of swapping action.

let s:null_coord  = [0, 0]
let s:null_pos    = [0, 0, 0, 0]
let s:null_region = {'head': copy(s:null_pos), 'tail': copy(s:null_pos), 'len': -1, 'type': ''}

function! swap#rule#get(rule) abort "{{{
  return extend(a:rule, deepcopy(s:rule_prototype), 'force')
endfunction
"}}}

let s:rule_prototype = {
      \   'region': deepcopy(s:null_region)
      \ }
function! s:rule_prototype.search(curpos, motionwise) dict abort  "{{{
  let timeout = g:swap#stimeoutlen
  if has_key(self, 'body')
    if self.region == s:null_region
      let self.region = s:search_body(self.body, a:curpos, timeout)
      if self.region != s:null_region && s:is_in_between(a:curpos, self.region.head, self.region.tail)
        let self.region.len = s:get_buf_length(self.region)
        let self.region.visualkey = s:motionwise2visualkey(a:motionwise)
        let self.region.type = a:motionwise
        return self.region
      endif
    endif
  elseif has_key(self, 'surrounds')
    let nest = get(self.surrounds, -1, 0)
    if self.region == s:null_region
      let pos = [a:curpos, a:curpos]
    else
      let pos = s:get_outer_pos(self.surrounds, self.region)
    endif
    let self.region = s:search_surrounds(self.surrounds, pos, nest, timeout)
    if self.region != s:null_region
      let [head, tail] = s:get_outer_pos(self.surrounds, self.region)
      if s:is_in_between(a:curpos, head, tail)
        let self.region.len = s:get_buf_length(self.region)
        let self.region.visualkey = s:motionwise2visualkey(a:motionwise)
        let self.region.type = a:motionwise
        return self.region
      endif
    endif
  endif
  let self.region = deepcopy(s:null_region)
  return self.region
endfunction
"}}}
function! s:rule_prototype.check(region) dict abort  "{{{
  let timeout = g:swap#stimeoutlen

  if has_key(self, 'body')
    if s:check_body(self.body, a:region, timeout)
      let self.region = a:region
      return 1
    else
      return 0
    endif
  endif

  if has_key(self, 'surrounds')
    if s:check_surrounds(self.surrounds, a:region, timeout)
      let self.region = a:region
      return 1
    else
      return 0
    endif
  endif

  return 1
endfunction
"}}}
function! s:rule_prototype.initialize() dict abort  "{{{
  let self.region = deepcopy(s:null_region)
  return self
endfunction
"}}}

function! s:search_body(body, pos, timeout) abort "{{{
  call setpos('.', a:pos)
  let tail = searchpos(a:body, 'ceW', 0, a:timeout)
  if tail == s:null_coord | return deepcopy(s:null_region) | endif
  let tail = s:c2p(tail)
  let head = searchpos(a:body, 'bW',  0, a:timeout)
  if head == s:null_coord | return deepcopy(s:null_region) | endif
  let head = s:c2p(head)
  return s:is_ahead(tail, head) && s:is_in_between(a:pos, head, tail)
        \ ? extend(deepcopy(s:null_region), {'head': head, 'tail': tail}, 'force')
        \ : deepcopy(s:null_region)
endfunction
"}}}
function! s:search_surrounds(surrounds, pos, nest, timeout, ...) abort "{{{
  if a:pos[0] == s:null_pos || a:pos[1] == s:null_pos
    return deepcopy(s:null_region)
  endif

  let is_skip = get(a:000, 0, 0)
  let skip_expr = is_skip ? 's:skip(1)' : 's:skip(0)'

  call setpos('.', a:pos[1])
  let tail = s:searchpos(a:nest, a:surrounds, 0, skip_expr, a:timeout)
  if tail == s:null_coord | return deepcopy(s:null_region) | endif
  let is_tail_skipping_syntax = is_skip ? 0 : s:is_skipping_syntax(tail)

  if !a:nest
    call setpos('.', a:pos[0])
  endif

  let head = s:searchpos(a:nest, a:surrounds, 1, skip_expr, a:timeout)
  if head == s:null_coord | return deepcopy(s:null_region) | endif
  let is_head_skipping_syntax = is_skip ? 0 : s:is_skipping_syntax(head)

  if is_head_skipping_syntax && is_tail_skipping_syntax && !s:is_successive_syntax(head, tail)
    " If the syntax region is not successive, search again with skipping specific sytaxes.
    return s:search_surrounds(a:surrounds, a:pos, a:nest, a:timeout, 1)
  elseif is_head_skipping_syntax && !is_tail_skipping_syntax
    " search head which is not in specific syntaxes
    let head = s:searchpos(a:nest, a:surrounds, 1, 's:skip(1)', a:timeout)
    if head == s:null_coord | return deepcopy(s:null_region) | endif
  elseif !is_head_skipping_syntax && is_tail_skipping_syntax
    " search tail which is not in specific syntaxes
    let tail = s:searchpos(a:nest, a:surrounds, 0, 's:skip(1)', a:timeout)
    if tail == s:null_coord | return deepcopy(s:null_region) | endif
  endif

  let tail = s:get_left_pos(s:c2p(tail))
  let head = s:get_right_pos(s:c2p(head))
  return extend(deepcopy(s:null_region), {'head': head, 'tail': tail}, 'force')
endfunction
"}}}
function! s:searchpos(nest, pattern, is_head, skip_expr, timeout) abort  "{{{
  if a:nest
    if !a:is_head && searchpos(a:pattern[0], 'cn', line('.')) == getpos('.')[1:2]
      normal! l
    endif
    let flag = a:is_head ? 'bW' : 'cW'
    let coord = searchpairpos(a:pattern[0], '', a:pattern[1], flag, a:skip_expr, 0, a:timeout)
    if coord != s:null_coord && a:is_head
      let coord = searchpos(a:pattern[0], 'ceW', 0, a:timeout)
    endif
  else
    let coord = copy(s:null_coord)
    let flag = a:is_head ? 'beW' : 'cW'
    let pattern = a:is_head ? a:pattern[0] : a:pattern[1]
    let coord = searchpos(pattern, flag, 0, a:timeout)
    let flag = a:is_head ? 'beW' : 'W'
    while coord != s:null_coord && eval(a:skip_expr)
      let coord = searchpos(pattern, flag, 0, a:timeout)
    endwhile
  endif
  return coord
endfunction
"}}}
function! s:skip(is_skip) abort "{{{
  return a:is_skip ? s:is_skipping_syntax(getpos('.')[1:2]) : 0
endfunction
"}}}
function! s:is_skipping_syntax(coord) abort "{{{
  let syntax = s:get_displaysyntax(a:coord)
  return syntax ==# 'Constant' || syntax ==# 'String' || syntax ==# 'Comment'
endfunction
"}}}
function! s:is_successive_syntax(head, tail) abort  "{{{
  call cursor(a:head)
  let tail = s:c2p(a:tail)
  let syntax = s:get_displaysyntax(a:head)
  let is_successive = 1
  let [&virtualedit, &whichwrap] = ['', 'h,l']
  while 1
    normal! l
    let pos = getpos('.')

    if s:is_ahead(pos, tail)
      break
    endif

    if s:get_displaysyntax(pos[1:2]) !=# syntax
      let is_successive = 0
      break
    endif
  endwhile
  let [&virtualedit, &whichwrap] = ['onemore', 'h,l']
  return is_successive
endfunction
"}}}
function! s:get_displaysyntax(coord) abort  "{{{
  return synIDattr(synIDtrans(synID(a:coord[0], a:coord[1], 1)), 'name')
endfunction
"}}}
function! s:check_body(body, region, timeout) abort "{{{
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
endfunction
"}}}
function! s:check_surrounds(surrounds, region, timeout) abort "{{{
  " NOTE: s:match_surrounds does not check nesting.
  "       Maybe it is reasonable considering use cases.
  let is_matched = 1
  let cur_pos = getpos('.')
  if s:get_left_pos(a:region.head)[1:2] != searchpos(a:surrounds[0], 'cenW', 0, a:timeout)
    let is_matched = 0
  endif
  if is_matched && s:get_right_pos(a:region.tail)[1:2] != searchpos(a:surrounds[1], 'bcnW', 0, a:timeout)
    let is_matched = 0
  endif
  call setpos('.', cur_pos)
  return is_matched
endfunction
"}}}
function! s:get_outer_pos(surrounds, region) abort  "{{{
  let timeout = g:swap#stimeoutlen
  call setpos('.', a:region.head)
  let head = s:c2p(searchpos(a:surrounds[0], 'bW', 0, timeout))
  if head != s:null_pos
    let head = s:get_left_pos(head)
  endif

  call setpos('.', a:region.tail)
  let tail = s:c2p(searchpos(a:surrounds[1], 'eW', 0, timeout))
  if tail != s:null_pos
    let tail = s:get_right_pos(tail)
  endif
  return [head, tail]
endfunction
"}}}
function! s:get_left_pos(pos, ...) abort  "{{{
  call setpos('.', a:pos)
  execute printf('normal! %dh', get(a:000, 0, 1))
  return getpos('.')
endfunction
"}}}
function! s:get_right_pos(pos, ...) abort  "{{{
  call setpos('.', a:pos)
  execute printf('normal! %dl', get(a:000, 0, 1))
  return getpos('.')
endfunction
"}}}

let [s:get_buf_length, s:c2p, s:is_ahead, s:is_in_between, s:motionwise2visualkey]
      \ = swap#lib#funcref(['get_buf_length', 'c2p', 'is_ahead', 'is_in_between', 'motionwise2visualkey'])

" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" vim:set ts=2 sts=2 sw=2:
