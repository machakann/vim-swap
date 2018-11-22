" parser - parse a buffer text into swappable elements

let s:Const = swap#constant#import()
let s:Lib = swap#lib#import()

let s:TRUE = 1
let s:FALSE = 0
let s:TYPELIST = s:Const.TYPELIST

let s:sort = s:Lib.sort
let s:matchstrpos = s:Lib.matchstrpos


" Element - a parsed item; either 'item', 'delimiter' or 'immutable' "{{{
function! s:Element(attr, str) abort
  return {'attr': a:attr, 'str': a:str}
endfunction
"}}}


" Object - a remarkable landmark for tokenizing "{{{
let s:Object = {
\   'kind': '',
\   'pat': '',
\   'last_found': [-1, -1, 0],
\ }

function! s:Object(kind, pat) abort "{{{
  let obj = deepcopy(s:Object)
  let obj.kind = a:kind
  let obj.pat = a:pat
  let obj._match_method = 'idx'
  if a:kind is# 'item' || a:kind is# 'immutable'
    if s:is_preceding_match_included(a:pat)
      let obj.search = obj.search_pat_by_count
    else
      let obj.search = obj.search_pat_by_idx
    endif
  elseif a:kind is# 'delimiter'
    if s:is_preceding_match_included(a:pat)
      let obj.search = obj.search_delimiter_by_count
    else
      let obj.search = obj.search_delimiter_by_idx
    endif
  elseif a:kind is# 'literal_quotes'
    let pat = obj.pat
    let obj.pat = printf('\%(%s.\{-}%s\|%s.*$\)', pat[0], pat[1], pat[0])
    let obj.search = obj.search_pat_by_idx
  elseif a:kind is# 'quotes' || a:kind is# 'braket'
    let obj.search = obj.search_pair_start
  elseif a:kind is# 'bra' || a:kind is# 'ket'
    let obj.search = obj.search_str
  else
    echoerr 'vim-swap: Error occurred in the parser'
  endif
  return obj
endfunction"}}}

function! s:Object.search_pair_start(text, idx, lastmatch) abort "{{{
  let [start, end, l:count] = self.last_found
  if start < a:idx
    let start = stridx(a:text, self.pat[0], a:idx)
    let end = start + strlen(self.pat[0])
    let self.last_found = [start, end, l:count + 1]
  endif
  return {'kind': self.kind, 'pat': self.pat, 'start': start, 'end': end}
endfunction "}}}

function! s:Object.search_str(text, idx, lastmatch) abort "{{{
  let [start, end, l:count] = self.last_found
  if start < a:idx
    let start = stridx(a:text, self.pat, a:idx)
    let end = start + strlen(self.pat)
    let self.last_found = [start, end, l:count + 1]
  endif
  return {'kind': self.kind, 'pat': self.pat, 'start': start, 'end': end}
endfunction "}}}

function! s:Object.search_pat_by_count(text, idx, lastmatch) abort "{{{
  let [start, end, l:count] = self.last_found
  while start <= a:idx
    let [_, start, end] = s:matchstrpos(a:text, self.pat, 0, l:count + 1)
    let l:count += 1
    if start == -1
      break
    endif
  endwhile
  let self.last_found = [start, end, l:count]
  return {'kind': self.kind, 'pat': self.pat, 'start': start, 'end': end}
endfunction "}}}

function! s:Object.search_pat_by_idx(text, idx, lastmatch) abort "{{{
  let [_, start, end] = s:matchstrpos(a:text, self.pat, a:idx)
  let self.last_found = [start, end, -1]
  return {'kind': self.kind, 'pat': self.pat, 'start': start, 'end': end}
endfunction "}}}

function! s:Object.search_delimiter_by_count(text, idx, lastmatch) abort "{{{
  let idx = a:idx
  if s:is_zero_width_delimiter_match(a:lastmatch)
    " if the last match is a zero-width delimiter, it should be skipped
    let idx += 1
  endif
  return self.search_pat_by_count(a:text, idx, a:lastmatch)
endfunction "}}}

function! s:Object.search_delimiter_by_idx(text, idx, lastmatch) abort "{{{
  let idx = a:idx
  if s:is_zero_width_delimiter_match(a:lastmatch)
    " if the last match is a zero-width delimiter, it should be skipped
    let idx += 1
  endif
  return self.search_pat_by_idx(a:text, idx, a:lastmatch)
endfunction "}}}

function! s:is_zero_width_delimiter_match(match) abort "{{{
  return a:match != {} &&
  \      a:match.kind is# 'delimiter' &&
  \      a:match.start == a:match.end
endfunction "}}}

function! s:is_preceding_match_included(pat) abort "{{{
  return match(a:pat, '\%(^\|[^\\]\)\%(\\\\\)*\\zs') > -1 ||
  \      match(a:pat, '\%(^\|[^\\]\)\%(\\\\\)*\\@\d*<[!=]') > -1
endfunction "}}}
"}}}


function! s:parse_linewise(text, rule) abort  "{{{
  let elements = []
  for text in split(a:text, "\n", 1)[0:-2]
    call add(elements, s:Element('item', text))
    call add(elements, s:Element('delimiter', "\n"))
  endfor
  return elements
endfunction "}}}


function! s:parse_blockwise(text, rule) abort  "{{{
  let elements = []
  for text in split(a:text, "\n", 1)
    call add(elements, s:Element('item', text))
    call add(elements, s:Element('delimiter', "\n"))
  endfor
  call remove(elements, -1)
  return elements
endfunction "}}}


" NOTE: The order of kinds reflects the priority; the earlier is the stronger
let s:KIND_LIST = ['item', 'delimiter', 'braket', 'quotes', 'literal_quotes',
\                  'immutable']

function! s:parse_charwise(text, rule) abort  "{{{
  if a:text is# ''
    return []
  endif

  let objects = s:make_objects(a:rule)
  let fallbackattr = s:fallbackattr(objects)
  let tokens = s:tokenize(a:text, objects)
  let elements = s:parse(a:text, tokens, fallbackattr)
  let elements = s:insert_empty_item_between_successive_delimiters(elements)
  let elements = s:remove_first_zero_width_delimiter(elements)
  let elements = s:prohibit_ended_delimiters(elements)
  return elements
endfunction "}}}


function! s:make_objects(rule) abort "{{{
  let objects = []
  for kind in s:KIND_LIST
    let objects += s:objectize(kind, a:rule)
  endfor
  return objects
endfunction "}}}


function! s:objectize(kind, rule) abort "{{{
  let pattern_list = get(a:rule, a:kind, [])
  return map(copy(pattern_list), 's:Object(a:kind, v:val)')
endfunction "}}}


function! s:fallbackattr(objects) abort "{{{
  let num_item = len(filter(copy(a:objects), 'v:val.kind is# "item"'))
  let num_delimiter = len(filter(copy(a:objects), 'v:val.kind is# "delimiter"'))
  if num_item == 0 && num_delimiter != 0
    return 'item'
  elseif num_item != 0 && num_delimiter == 0
    return 'delimiter'
  endif
  return 'immutable'
endfunction "}}}


function! s:search_nearest_object(text, objects, idx, lastmatch) abort "{{{
  let match_list = map(copy(a:objects), 'v:val.search(a:text, a:idx, a:lastmatch)')
  call filter(match_list, 'v:val.start != -1')
  call filter(a:objects, 'v:val.last_found[1] != -1')
  if match_list == []
    return {}
  endif

  " Choose the nearest object
  call s:sort(match_list, s:COMPAREFUNC)
  return match_list[0]
endfunction "}}}


function! s:compare_start(a, b) abort "{{{
  return a:a.start - a:b.start
endfunction "}}}
let s:COMPAREFUNC = function('s:compare_start')


function! s:search_quote_end(text, pair, idx) abort  "{{{
  let idx = a:idx
  let end = strlen(a:text)
  while 1
    let idx = s:stridxend(a:text, a:pair[1], idx)
    if idx == -1
      let idx = end
      break
    endif
    if stridx(&quoteescape, a:text[idx-2]) == -1 || idx < 2
      break
    endif

    let pat = printf('%s\+$', s:Lib.escape(a:text[idx-2]))
    let n = strchars(matchstr(a:text[: idx-2], pat))
    if n%2 == 0
      break
    endif
  endwhile
  return idx
endfunction "}}}


function! s:search_braket_end(text, pair, all_quotes, idx) abort  "{{{
  let idx = a:idx
  let end = strlen(a:text)
  let objects = [
  \   s:Object('bra', a:pair[0]),
  \   s:Object('ket', a:pair[1]),
  \ ] + a:all_quotes
  let depth = 1
  while depth > 0
    let match = s:search_nearest_object(a:text, objects, idx, {})
    if match == {}
      let idx = -1
      break
    endif

    let kind = match.kind
    if kind is# 'ket'
      let depth -= 1
    elseif kind is# 'bra'
      let depth += 1
    elseif kind is# 'quotes'
      let match.end = s:search_quote_end(a:text, match.pat, match.end)
    elseif kind is# 'literal_quotes'
      " nothing to do
    else
      " should not reach here
      echoerr 'vim-swap: Error occurred in the parser'
    endif

    let idx = match.end
    if idx < 0 || idx >= end
      let idx = end
      break
    endif
  endwhile
  return idx
endfunction "}}}


function! s:stridxend(heystack, needle, ...) abort  "{{{
  let start = get(a:000, 0, 0)
  let idx = stridx(a:heystack, a:needle, start)
  if idx < 0
    return -1
  endif
  return idx + strlen(a:needle)
endfunction "}}}


function! s:substring(text, start, end) abort "{{{
  if a:start == a:end
    return ''
  endif
  return a:text[a:start : a:end - 1]
endfunction "}}}


function! s:copy_all_quotations(objects) abort "{{{
  return filter(copy(a:objects),
  \ 'v:val.kind is# "quotes" || v:val.kind is# "literal_quotes"')
endfunction "}}}


function! s:tokenize(text, objects) abort "{{{
  let mark = 0
  let match = {}
  let textend = strlen(a:text)
  let tokens = []
  while s:TRUE
    let match = s:search_nearest_object(a:text, a:objects, mark, match)
    if match == {}
      call add(tokens, [mark, textend, ''])
      break
    endif
    if mark isnot# match.start
      " Fill the gap
      call add(tokens, [mark, match.start, ''])
    endif

    let kind = match.kind
    if kind is# 'quotes'
      let match.end = s:search_quote_end(a:text, match.pat, match.end)
    elseif kind is# 'braket'
      let all_quotes = s:copy_all_quotations(a:objects)
      let match.end = s:search_braket_end(a:text, match.pat, all_quotes, match.end)
    endif
    call add(tokens, [match.start, match.end, match.kind])
    if match.end >= textend
      break
    endif
    let mark = match.end
  endwhile
  return tokens
endfunction "}}}


function! s:parse(text, tokens, fallbackattr) abort "{{{
  " interpret kind to attr
  for t in a:tokens
    let kind = t[2]
    if kind is# 'item'
      let attr = 'item'
    elseif kind is# 'delimiter'
      let attr = 'delimiter'
    elseif kind is# 'quotes'
      let attr = 'item'
    elseif kind is# 'literal_quotes'
      let attr = 'item'
    elseif kind is# 'braket'
      let attr = 'item'
    elseif kind is# 'immutable'
      let attr = 'immutable'
    else
      let attr = a:fallbackattr
    endif
    let t[2] = attr
  endfor

  if len(a:tokens) > 1
    " merge
    let i = 1
    while i < len(a:tokens)
      let prev = a:tokens[i - 1]
      let prevkind = prev[2]
      let t = a:tokens[i]
      let kind = t[2]
      if (kind is# 'item' || kind is# 'immutable') && kind is# prevkind
        let prev[1] = t[1]
        call remove(a:tokens, i)
        continue
      endif
      let i += 1
    endwhile
  endif

  return map(a:tokens,
  \ '{"attr": v:val[2], "str": s:substring(a:text, v:val[0], v:val[1])}')
endfunction "}}}


function! s:insert_empty_item_between_successive_delimiters(elements) abort "{{{
  let i = 1
  while i < len(a:elements)
    let prevelem = a:elements[i - 1]
    let elem = a:elements[i]
    if prevelem.attr is# 'delimiter' && elem.attr is# 'delimiter'
      call insert(a:elements, s:Element('item', ''), i)
      let i += 1
    endif
    let i += 1
  endwhile
  return a:elements
endfunction "}}}


function! s:remove_first_zero_width_delimiter(elements) abort "{{{
  while a:elements != [] && s:is_zero_width_delimiter_element(a:elements[0])
    call remove(a:elements, 0)
  endwhile
  return a:elements
endfunction "}}}


function! s:is_zero_width_delimiter_element(element) abort "{{{
  return a:element.attr is# 'delimiter' && a:element.str is# ''
endfunction "}}}


function! s:prohibit_ended_delimiters(elements) abort "{{{
  if a:elements == []
    return a:elements
  endif

  " If the first element is a delimiter, insert an empty item at the first place.
  let firstelement = a:elements[0]
  if firstelement.attr is# 'delimiter'
    call insert(a:elements, s:Element('item', ''), 0)
  endif
  " If the last element is a delimiter, insert an empty item at the end.
  let lastelement = a:elements[-1]
  if lastelement.attr is# 'delimiter'
    call add(a:elements, s:Element('item', ''))
  endif
  return a:elements
endfunction "}}}


" s:parse() return a list of dictionaries which have two keys at least,
" attr and str.
"   attr : 'item' or 'delimiter' or 'immutable'.
"          'item' is a element reordered.
"          'delimiter' is a element separating items.
"          'immutable' is neither an 'item' nor a 'delimiter'. It is a string which should not be changed.
"   str  : The value is the string as 'item' or 'delimiter' or 'immutable'.
" For instance, 'foo,bar' is parsed to:
"   [{'attr': 'item', 'str': 'foo'},
"    {'attr': 'delimiter', 'str': ','},
"    {'attr': 'item': 'str': 'bar'}]
" In case that motionwise is# 'V' or "\<C-v>", delimiter string should be "\n".
function! s:Parser_parse(text, type, rule) abort "{{{
  return s:parse_{a:type}wise(a:text, a:rule)
endfunction "}}}


let s:Parser = {}
let s:Parser.parse = function('s:Parser_parse')


function! swap#parser#import() abort "{{{
  return s:Parser
endfunction "}}}


" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" vim:set ts=2 sts=2 sw=2:
