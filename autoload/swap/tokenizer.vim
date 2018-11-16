" tokenizer - tokenize a buffer text into swappable tokens

let s:Const = swap#constant#import()
let s:Lib = swap#lib#import()


" s:tokenize() return a list of dictionaries which have two keys at least,
" attr and str.
"   attr : 'item' or 'delimiter' or 'immutable'.
"          'item' is a token reordered.
"          'delimiter' is a token separating items.
"          'immutable' is neither an 'item' nor a 'delimiter'. It is a string which should not be changed.
"   str  : The value is the string as 'item' or 'delimiter' or 'immutable'.
" For instance, 'foo,bar' is tokenized to:
"   [{'attr': 'item', 'str': 'foo'},
"    {'attr': 'delimiter', 'str': ','},
"    {'attr': 'item': 'str': 'bar'}]
" In case that motionwise is# 'V' or "\<C-v>", delimiter string should be "\n".
function! s:tokenize(text, type, rule) abort "{{{
  return s:tokenize_{a:type}wise(a:text, a:rule)
endfunction "}}}


function! s:tokenize_charwise(text, rule) abort  "{{{
  let idx = 0
  let end = strlen(a:text)
  let head = 0
  let last_delimiter_tail = -1/0
  let buffer = []

  let targets = {}
  let targets.delimiter = map(copy(get(a:rule, 'delimiter', [])), '[-1, v:val, 0, "delimiter"]')
  let targets.immutable = map(copy(get(a:rule, 'immutable', [])), '[-1, v:val, 0, "immutable"]')
  let targets.braket    = map(copy(get(a:rule, 'braket', [])), '[-1, v:val, 0, "braket"]')
  let targets.quotes    = map(copy(get(a:rule, 'quotes', [])), '[-1, v:val, 0, "quotes"]')
  let targets.literal_quotes = map(copy(get(a:rule, 'literal_quotes', [])), '[-1, v:val, 0, "literal_quotes"]')
  let targets.all = targets.delimiter + targets.immutable + targets.braket + targets.quotes + targets.literal_quotes

  while idx < end
    unlet! pattern  " ugly...
    let [idx, pattern, occurence, kind] = s:shift_to_something_start(a:text, targets.all, idx)
    if idx < 0
      " finish tokenizing
      call s:add_buffer_text(buffer, 'item', a:text, head, idx)
      break
    endif

    if kind is# 'delimiter'
      " a delimiter is found
      " NOTE: I would like to treat zero-width delimiter as possible.
      let last_elem = get(buffer, -1, {'attr': ''})
      if idx == last_delimiter_tail && last_elem.attr is# 'delimiter' && last_elem.str ==# ''
        " zero-width delimiter is found
        let idx += 1
        continue
      endif

      if !(head == idx && last_elem.attr is# 'immutable')
        call s:add_buffer_text(buffer, 'item', a:text, head, idx)
      endif
      if idx == last_delimiter_tail
        " successive delimiters
        let [head, idx] = [idx, s:shift_to_delimiter_end(a:text, pattern, idx, 0)]
      else
        let [head, idx] = [idx, s:shift_to_delimiter_end(a:text, pattern, idx, 1)]
      endif
      call s:add_buffer_text(buffer, 'delimiter', a:text, head, idx)
      if idx < 0 || idx >= end
        break
      else
        let head = idx
        let last_delimiter_tail = idx
      endif
    elseif kind is# 'braket'
      " a bra is found
      let idx = s:shift_to_braket_end(a:text, pattern, targets.quotes, targets.literal_quotes, idx)
      if idx < 0 || idx >= end
        call s:add_buffer_text(buffer, 'item', a:text, head, idx)
        break
      endif
    elseif kind is# 'quotes'
      " a quote is found
      let idx = s:shift_to_quote_end(a:text, pattern, idx)
      if idx < 0 || idx >= end
        call s:add_buffer_text(buffer, 'item', a:text, head, idx)
        break
      endif
    elseif kind is# 'literal_quotes'
      " an literal quote (non-escaped quote) is found
      let idx = s:shift_to_literal_quote_end(a:text, pattern, idx)
      if idx < 0 || idx >= end
        call s:add_buffer_text(buffer, 'item', a:text, head, idx)
        break
      endif
    else
      " an immutable string is found
      if idx != head
        call s:add_buffer_text(buffer, 'item', a:text, head, idx)
      endif
      let [head, idx] = [idx, s:shift_to_immutable_end(a:text, pattern, idx)]
      call s:add_buffer_text(buffer, 'immutable', a:text, head, idx)
      if idx < 0 || idx >= end
        break
      else
        let head = idx
      endif
    endif
  endwhile

  if empty(buffer)
    return []
  endif

  " If the first delimiter is zero-width, remove until it.
  let start = 0
  let idx = 0
  while idx < len(buffer)
    if !empty(buffer[idx]['str'])
      break
    endif
    if buffer[idx]['attr'] is# 'delimiter'
      call remove(buffer, start, idx)
      let start = 0
      let idx = 0
    else
      let idx += 1
    endif
  endwhile
  " If the first token is a delimiter, put an empty item at the first place.
  if buffer[0]['attr'] is# 'delimiter'
    call s:add_buffer_text(buffer, 'item', a:text, 0, 0)
  endif
  " If the last token is a delimiter, put an empty item at the end.
  if buffer[-1]['attr'] is# 'delimiter'
    call s:add_buffer_text(buffer, 'item', a:text, idx, idx)
  endif
  return buffer
endfunction "}}}


function! s:tokenize_linewise(text, rule) abort  "{{{
  let buffer = []
  for text in split(a:text, "\n", 1)[0:-2]
    call s:add_an_token(buffer, 'item', text)
    call s:add_an_token(buffer, 'delimiter', "\n")
  endfor
  return buffer
endfunction "}}}


function! s:tokenize_blockwise(text, rule) abort  "{{{
  let buffer = []
  for text in split(a:text, "\n", 1)
    call s:add_an_token(buffer, 'item', text)
    call s:add_an_token(buffer, 'delimiter', "\n")
  endfor
  call remove(buffer, -1)
  return buffer
endfunction "}}}


function! s:click(text, target, idx) abort  "{{{
  let [idx, pair, _, kind] = a:target
  if idx >= a:idx
    return a:target
  endif

  if kind is# 'delimiter' || kind is# 'immutable'
    " delimiter or immutable
    let a:target[0:2] = s:match(a:text, a:target[0:2], a:idx, 1)
  else
    " braket or quotes
    let a:target[0] = stridx(a:text, pair[0], a:idx)
  endif
  return a:target
endfunction "}}}


function! s:shift_to_something_start(text, targets, idx) abort  "{{{
  let result = [-1, '', 0, '']
  call map(a:targets, 's:click(a:text, v:val, a:idx)')
  call filter(a:targets, 'v:val[0] > -1')
  if a:targets != []
    call s:Lib.sort(a:targets, function('s:compare_idx'))
    let result = a:targets[0]
  endif
  return result
endfunction "}}}


function! s:shift_to_delimiter_end(text, delimiter, idx, current_match) abort  "{{{
  return s:matchend(a:text, [0, a:delimiter, 0], a:idx, a:current_match)[0]
endfunction "}}}


function! s:shift_to_braket_end(text, pair, quotes, literal_quotes, idx) abort  "{{{
  let end = strlen(a:text)
  let idx = s:stridxend(a:text, a:pair[0], a:idx)

  let depth = 0
  while 1
    let lastidx = idx
    let ket = s:stridxend(a:text, a:pair[1], idx)
    " do not take into account 'zero width' braket
    if ket == lastidx
      let idx += 1
      continue
    endif

    if ket < 0
      let idx = -1
    elseif ket >= end
      let idx = end
    else
      let bra = s:stridxend(a:text, a:pair[0], idx)
      if bra == lastidx
        let bra = s:stridxend(a:text, a:pair[0], idx+1)
      endif

      call filter(a:quotes, 'v:val[0] > -1')
      if a:quotes != []
        let quote = s:shift_to_something_start(a:text, a:quotes, idx)
      else
        let quote = [-1]
      endif

      call filter(a:literal_quotes, 'v:val[0] > -1')
      if a:literal_quotes != []
        let literal_quote = s:shift_to_something_start(a:text, a:literal_quotes, idx)
      else
        let literal_quote = [-1]
      endif

      let list_idx = filter([ket, bra, quote[0], literal_quote[0]], 'v:val > -1')
      if list_idx == []
        let idx = -1
      else
        let idx = min(list_idx)
        if idx == ket
          let depth -= 1
        elseif idx == bra
          let depth += 1
        elseif idx == quote[0]
          let idx = s:shift_to_quote_end(a:text, quote[1], quote[0])
          if idx > end
            let idx = -1
          endif
        else
          let idx = s:shift_to_literal_quote_end(a:text, literal_quote[1], literal_quote[0])
          if idx > end
            let idx = -1
          endif
        endif
      endif
    endif

    if idx < 0 || idx >= end || depth < 0
      break
    endif
  endwhile
  return idx
endfunction "}}}


function! s:shift_to_quote_end(text, pair, idx) abort  "{{{
  let idx = s:stridxend(a:text, a:pair[0], a:idx)
  let end = strlen(a:text)
  let quote = 0

  while 1
    let quote = s:stridxend(a:text, a:pair[1], idx)
    " do not take into account 'zero width' quote
    if quote == idx
      let idx += 1
      continue
    endif

    if quote < 0
      let idx = -1
    else
      let idx = quote
      if idx > 1 && idx <= end && stridx(&quoteescape, a:text[idx-2]) > -1
        let n = strchars(matchstr(a:text[: idx-2], printf('%s\+$', s:Lib.escape(a:text[idx-2]))))
        if n%2 == 1
          continue
        endif
      endif
    endif
    break
  endwhile
  return idx
endfunction "}}}


function! s:shift_to_literal_quote_end(text, pair, idx) abort  "{{{
  let idx = s:stridxend(a:text, a:pair[0], a:idx)
  let literal_quote = s:stridxend(a:text, a:pair[1], idx)
  if literal_quote == idx
    let literal_quote = s:stridxend(a:text, a:pair[1], idx+1)
  endif
  return literal_quote
endfunction "}}}


function! s:shift_to_immutable_end(text, immutable, idx) abort  "{{{
  " NOTE: Zero-width immutable would not be considered.
  return s:matchend(a:text, [0, a:immutable, 0], a:idx, 0)[0]
endfunction "}}}


function! s:add_buffer_text(buffer, attr, text, head, next_head) abort  "{{{
  " NOTE: Zero-width 'item', 'delimiter' and 'immutable' should be possible.
  if a:head < 0
    return
  endif

  if a:next_head < 0
    let string = a:text[a:head :]
  elseif a:next_head <= a:head
    let string = ''
  else
    let string = a:text[a:head : a:next_head-1]
  endif
  call s:add_an_token(a:buffer, a:attr, string)
endfunction "}}}


function! s:add_an_token(buffer, attr, string) abort "{{{
  return add(a:buffer, {'attr': a:attr, 'str': a:string})
endfunction "}}}


function! s:match(string, target, idx, ...) abort "{{{
  " NOTE: current_match is like 'c' flag in search()
  let current_match = get(a:000, 0, 1)

  " NOTE: Because s:match_by_occurence() is heavy, it is used only when
  "       a pattern includes '\zs', '\@<=' and '\@<!'.
  if match(a:target[1], '[^\\]\%(\\\\\)*\\zs') > -1 || match(a:target[1], '[^\\]\%(\\\\\)*\\@\d*<[!=]') > -1
    return s:match_by_occurence(a:string, a:target, a:idx, current_match)
  else
    return s:match_by_idx(a:string, a:target, a:idx, current_match)
  endif
endfunction "}}}


function! s:match_by_idx(string, target, idx, current_match) abort  "{{{
  let [idx, pattern, occurrence] = a:target
  let idx = match(a:string, pattern, a:idx)
  if !a:current_match && idx == a:idx
    let idx = match(a:string, pattern, a:idx, 2)
  endif
  return [idx, pattern, occurrence]
endfunction "}}}


function! s:match_by_occurence(string, target, idx, current_match) abort  "{{{
  let [idx, pattern, occurrence] = a:target
  if a:idx < idx
    let occurrence = 0
  endif
  while 1
    let idx = match(a:string, pattern, 0, occurrence + 1)
    if idx >= 0
      let occurrence += 1
      if (a:current_match && idx < a:idx) || (!a:current_match && idx <= a:idx)
        continue
      endif
    endif
    break
  endwhile
  return [idx, pattern, occurrence]
endfunction "}}}


function! s:matchend(string, target, idx, ...) abort "{{{
  " NOTE: current_match is like 'c' flag in search()
  let current_match = get(a:000, 0, 1)

  " NOTE: Because s:match_by_occurence() is heavy, it is used only when
  "       a pattern includes '\zs', '\@<=' and '\@<!'.
  if match(a:target[1], '[^\\]\%(\\\\\)*\\zs') > -1 || match(a:target[1], '[^\\]\%(\\\\\)*\\@\d*<[!=]') > -1
    return s:matchend_by_occurence(a:string, a:target, a:idx, current_match)
  else
    return s:matchend_by_idx(a:string, a:target, a:idx, current_match)
  endif
endfunction "}}}


function! s:matchend_by_occurence(string, target, idx, current_match) abort "{{{
  let [idx, pattern, occurrence] = a:target
  if a:idx < idx
    let occurrence = 0
  endif
  while 1
    let idx = matchend(a:string, pattern, 0, occurrence + 1)
    if idx >= 0
      let occurrence += 1
      if (a:current_match && idx < a:idx) || (!a:current_match && idx <= a:idx)
        continue
      endif
    endif
    break
  endwhile
  return [idx, pattern, occurrence]
endfunction "}}}


function! s:matchend_by_idx(string, target, idx, current_match) abort "{{{
  let [idx, pattern, occurrence] = a:target
  let idx = matchend(a:string, pattern, a:idx)
  if !a:current_match && idx == a:idx
    let idx = matchend(a:string, pattern, a:idx, 2)
  endif
  return [idx, pattern, occurrence]
endfunction "}}}


function! s:stridxend(heystack, needle, ...) abort  "{{{
  let start = get(a:000, 0, 0)
  let idx = stridx(a:heystack, a:needle, start)
  return idx >= 0 ? idx + strlen(a:needle) : idx
endfunction "}}}


function! s:compare_idx(i1, i2) abort "{{{
  return a:i1[0] - a:i2[0]
endfunction "}}}


let s:Tokenizer = {}
let s:Tokenizer.tokenize = function('s:tokenize')


function! swap#tokenizer#import() abort "{{{
  return s:Tokenizer
endfunction "}}}


" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" vim:set ts=2 sts=2 sw=2:
