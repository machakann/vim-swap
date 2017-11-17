let s:suite = themis#suite('swap: ')

let s:scope = themis#helper('scope')
let s:parser = s:scope.funcs('autoload/swap/parser.vim')
let s:lib = s:scope.funcs('autoload/swap/lib.vim')

function! s:suite.before_each() abort "{{{
  %delete
  set selection&
  unlet! rule
  unlet! g:swap#rules
endfunction "}}}
function! s:suite.after() abort "{{{
  call s:suite.before_each()
endfunction "}}}

" unit tests
function! s:suite.shift_to_something_start() abort  "{{{
  let rule = {'surrounds': ['(', ')', 1], 'delimiter': [',\s*'], 'braket': [['(', ')'], ['[', ']'], ['{', '}']], 'quotes': [['"', '"']], 'literal_quotes': [["'", "'"]], 'immutable': ['\%(^\s\|\n\)\s*']}
  let targets = []
  let targets += map(copy(get(rule, 'delimiter', [])), '[-1, v:val, 0, "delimiter"]')
  let targets += map(copy(get(rule, 'immutable', [])), '[-1, v:val, 0, "immutable"]')
  let targets += map(copy(get(rule, 'braket', [])), '[-1, v:val, 0, "braket"]')
  let targets += map(copy(get(rule, 'quotes', [])), '[-1, v:val, 0, "quotes"]')
  let targets += map(copy(get(rule, 'literal_quotes', [])), '[-1, v:val, 0, "literal_quotes"]')

  let [idx, pattern, occurence, kind] = s:parser.shift_to_something_start('foo"bar"', deepcopy(targets), 0)
  call g:assert.equals(idx, 3)
  call g:assert.equals(kind, 'quotes')
  call g:assert.equals(pattern, ['"', '"'])
  unlet! pattern

  let [idx, pattern, occurence, kind] = s:parser.shift_to_something_start('foo(bar)', deepcopy(targets), 0)
  call g:assert.equals(idx, 3)
  call g:assert.equals(kind, 'braket')
  call g:assert.equals(pattern, ['(', ')'])
  unlet! pattern

  let [idx, pattern, occurence, kind] = s:parser.shift_to_something_start('foo, bar', deepcopy(targets), 0)
  call g:assert.equals(idx, 3)
  call g:assert.equals(kind, 'delimiter')
  call g:assert.equals(pattern, ',\s*')
  unlet! pattern

  let [idx, pattern, occurence, kind] = s:parser.shift_to_something_start('"foo"', deepcopy(targets), 0)
  call g:assert.equals(idx, 0)
  call g:assert.equals(kind, 'quotes')
  call g:assert.equals(pattern, ['"', '"'])
  unlet! pattern

  let [idx, pattern, occurence, kind] = s:parser.shift_to_something_start('(foo)', deepcopy(targets), 0)
  call g:assert.equals(idx, 0)
  call g:assert.equals(kind, 'braket')
  call g:assert.equals(pattern, ['(', ')'])
  unlet! pattern

  let [idx, pattern, occurence, kind] = s:parser.shift_to_something_start(',foo', deepcopy(targets), 0)
  call g:assert.equals(idx, 0)
  call g:assert.equals(kind, 'delimiter')
  call g:assert.equals(pattern, ',\s*')
  unlet! pattern

  let [idx, pattern, occurence, kind] = s:parser.shift_to_something_start('foobar', deepcopy(targets), 0)
  call g:assert.equals(idx, -1)
  call g:assert.equals(kind, '')
  call g:assert.equals(pattern, '')
  unlet! pattern
endfunction "}}}
function! s:suite.shift_to_braket_end() abort  "{{{
  let rule = {'surrounds': ['(', ')', 1], 'delimiter': [',\s*'], 'braket': [['(', ')'], ['[', ']'], ['{', '}']], 'quotes': [['"', '"']], 'literal_quotes': [["'", "'"]], 'immutable': ['\%(^\s\|\n\)\s*']}
  let quotes = map(copy(get(rule, 'quotes', [])), '[0, v:val, 0, "quotes"]')
  let literal_quotes = map(copy(get(rule, 'literal_quotes', [])), '[0, v:val, 0, "literal_quotes"]')

  let idx = s:parser.shift_to_braket_end('(foo)', ['(', ')'], deepcopy(quotes), deepcopy(literal_quotes), 0)
  call g:assert.equals(idx, 5)

  let idx = s:parser.shift_to_braket_end('foo(bar)baz', ['(', ')'], deepcopy(quotes), deepcopy(literal_quotes), 3)
  call g:assert.equals(idx, 8)

  let idx = s:parser.shift_to_braket_end('(foo)bar(baz)', ['(', ')'], deepcopy(quotes), deepcopy(literal_quotes), 0)
  call g:assert.equals(idx, 5)

  let idx = s:parser.shift_to_braket_end('(foo)bar(baz)', ['(', ')'], deepcopy(quotes), deepcopy(literal_quotes), 8)
  call g:assert.equals(idx, 13)

  let idx = s:parser.shift_to_braket_end('(foo(bar)baz)', ['(', ')'], deepcopy(quotes), deepcopy(literal_quotes), 0)
  call g:assert.equals(idx, 13)

  let idx = s:parser.shift_to_braket_end('(foo(bar)baz)', ['(', ')'], deepcopy(quotes), deepcopy(literal_quotes), 4)
  call g:assert.equals(idx, 9)

  let idx = s:parser.shift_to_braket_end('()', ['(', ')'], deepcopy(quotes), deepcopy(literal_quotes), 0)
  call g:assert.equals(idx, 2)

  let idx = s:parser.shift_to_braket_end('(foo(bar)', ['(', ')'], deepcopy(quotes), deepcopy(literal_quotes), 0)
  call g:assert.equals(idx, 9)

  let idx = s:parser.shift_to_braket_end(' ()', ['(', ')'], deepcopy(quotes), deepcopy(literal_quotes), 0)
  call g:assert.equals(idx, 3)

  let idx = s:parser.shift_to_braket_end('(foo")"bar)', ['(', ')'], deepcopy(quotes), deepcopy(literal_quotes), 0)
  call g:assert.equals(idx, 11)

  let idx = s:parser.shift_to_braket_end("(foo')'bar)", ['(', ')'], deepcopy(quotes), deepcopy(literal_quotes), 0)
  call g:assert.equals(idx, 11)
endfunction "}}}
function! s:suite.shift_to_quote_end() abort "{{{
  let idx = s:parser.shift_to_quote_end('"foo"', ['"', '"'], 0)
  call g:assert.equals(idx, 5)

  let idx = s:parser.shift_to_quote_end('foo"bar"baz', ['"', '"'], 3)
  call g:assert.equals(idx, 8)

  let idx = s:parser.shift_to_quote_end('"foo"bar"baz"', ['"', '"'], 0)
  call g:assert.equals(idx, 5)

  let idx = s:parser.shift_to_quote_end('"foo"bar"baz"', ['"', '"'], 8)
  call g:assert.equals(idx, 13)

  let idx = s:parser.shift_to_quote_end('"foo\"bar"', ['"', '"'], 0)
  call g:assert.equals(idx, 10)

  let idx = s:parser.shift_to_quote_end('"foo\\"bar"', ['"', '"'], 0)
  call g:assert.equals(idx, 7)

  let idx = s:parser.shift_to_quote_end('"foo\\\"bar"', ['"', '"'], 0)
  call g:assert.equals(idx, 12)

  let idx = s:parser.shift_to_quote_end('foobar', ['"', '"'], 0)
  call g:assert.equals(idx, -1)

  let idx = s:parser.shift_to_quote_end('"foobar', ['"', '"'], 0)
  call g:assert.equals(idx, -1)

  let idx = s:parser.shift_to_quote_end('"foo\"bar', ['"', '"'], 0)
  call g:assert.equals(idx, -1)

  let idx = s:parser.shift_to_quote_end('"\"foobar', ['"', '"'], 0)
  call g:assert.equals(idx, -1)

  let idx = s:parser.shift_to_quote_end('"foobar\"', ['"', '"'], 0)
  call g:assert.equals(idx, -1)

  let idx = s:parser.shift_to_quote_end('""', ['"', '"'], 0)
  call g:assert.equals(idx, 2)

  let idx = s:parser.shift_to_quote_end('"\"', ['"', '"'], 0)
  call g:assert.equals(idx, -1)
endfunction "}}}
function! s:suite.shift_to_literal_quote_end() abort "{{{
  let idx = s:parser.shift_to_literal_quote_end("'foo'", ["'", "'"], 0)
  call g:assert.equals(idx, 5, 'failed at #1')

  let idx = s:parser.shift_to_literal_quote_end("foo'bar'baz", ["'", "'"], 3)
  call g:assert.equals(idx, 8, 'failed at #2')

  let idx = s:parser.shift_to_literal_quote_end("'foo'bar'baz'", ["'", "'"], 0)
  call g:assert.equals(idx, 5, 'failed at #3')

  let idx = s:parser.shift_to_literal_quote_end("'foo'bar'baz'", ["'", "'"], 8)
  call g:assert.equals(idx, 13, 'failed at #4')

  let idx = s:parser.shift_to_literal_quote_end('''foo\''bar''', ["'", "'"], 0)
  call g:assert.equals(idx, 6, 'failed at #5')

  let idx = s:parser.shift_to_literal_quote_end('''foo\\''bar''', ["'", "'"], 0)
  call g:assert.equals(idx, 7, 'failed at #6')

  let idx = s:parser.shift_to_literal_quote_end('''foo\\\''bar''', ["'", "'"], 0)
  call g:assert.equals(idx, 8, 'failed at #7')

  let idx = s:parser.shift_to_literal_quote_end('foobar', ["'", "'"], 0)
  call g:assert.equals(idx, -1, 'failed at #8')

  let idx = s:parser.shift_to_literal_quote_end("'foobar", ["'", "'"], 0)
  call g:assert.equals(idx, -1, 'failed at #9')

  let idx = s:parser.shift_to_literal_quote_end('''foo\''bar', ["'", "'"], 0)
  call g:assert.equals(idx, 6, 'failed at #10')

  let idx = s:parser.shift_to_literal_quote_end('''\''foobar', ["'", "'"], 0)
  call g:assert.equals(idx, 3, 'failed at #11')

  let idx = s:parser.shift_to_literal_quote_end('''foobar\''', ["'", "'"], 0)
  call g:assert.equals(idx, 9, 'failed at #12')

  let idx = s:parser.shift_to_literal_quote_end("''", ["'", "'"], 0)
  call g:assert.equals(idx, 2, 'failed at #13')

  let idx = s:parser.shift_to_literal_quote_end('''\''', ["'", "'"], 0)
  call g:assert.equals(idx, 3, 'failed at #14')
endfunction "}}}
function! s:suite.buf_byte_len() abort "{{{
  call append(0, ['abc'])
  normal! 1G
  let l = s:lib.buf_byte_len([0, 1, 1, 0], getpos('.'))
  call g:assert.equals(l, 0)

  call append(0, ['abc'])
  normal! 1Gl
  let l = s:lib.buf_byte_len([0, 1, 1, 0], getpos('.'))
  call g:assert.equals(l, 1)

  call append(0, ['abc'])
  normal! 1G2l
  let l = s:lib.buf_byte_len([0, 1, 1, 0], getpos('.'))
  call g:assert.equals(l, 2)

  call append(0, ['abc', 'def'])
  normal! 2G
  let l = s:lib.buf_byte_len([0, 1, 1, 0], getpos('.'))
  call g:assert.equals(l, 4)

  call append(0, ['abc', 'def'])
  normal! 2Gl
  let l = s:lib.buf_byte_len([0, 1, 1, 0], getpos('.'))
  call g:assert.equals(l, 5)

  call append(0, ['abc', 'def'])
  normal! 2G2l
  let l = s:lib.buf_byte_len([0, 1, 1, 0], getpos('.'))
  call g:assert.equals(l, 6)

  call append(0, ['abc', 'def', 'ghi'])
  normal! 3G
  let l = s:lib.buf_byte_len([0, 1, 1, 0], getpos('.'))
  call g:assert.equals(l, 8)

  call append(0, ['abc', 'def', 'ghi'])
  normal! 3Gl
  let l = s:lib.buf_byte_len([0, 1, 1, 0], getpos('.'))
  call g:assert.equals(l, 9)

  call append(0, ['abc', 'def', 'ghi'])
  normal! 3G2l
  let l = s:lib.buf_byte_len([0, 1, 1, 0], getpos('.'))
  call g:assert.equals(l, 10)

  call append(0, ['', 'def', 'ghi'])
  normal! 1G
  let l = s:lib.buf_byte_len([0, 1, 1, 0], getpos('.'))
  call g:assert.equals(l, 0)

  call append(0, ['', 'def', 'ghi'])
  normal! 2G
  let l = s:lib.buf_byte_len([0, 1, 1, 0], getpos('.'))
  call g:assert.equals(l, 1)

  call append(0, ['', 'def', 'ghi'])
  normal! 3G
  let l = s:lib.buf_byte_len([0, 1, 1, 0], getpos('.'))
  call g:assert.equals(l, 5)

  call append(0, ['abc', '', 'ghi'])
  normal! 2G
  let l = s:lib.buf_byte_len([0, 1, 1, 0], getpos('.'))
  call g:assert.equals(l, 4)

  call append(0, ['abc', '', 'ghi'])
  normal! 3G
  let l = s:lib.buf_byte_len([0, 1, 1, 0], getpos('.'))
  call g:assert.equals(l, 5)

  call append(0, ['abc', 'def', ''])
  normal! 3G
  let l = s:lib.buf_byte_len([0, 1, 1, 0], getpos('.'))
  call g:assert.equals(l, 8)
endfunction "}}}
function! s:suite.parse_charwise() dict abort  "{{{
  let rule = {'surrounds': ['(', ')', 1], 'delimiter': [',\s*'], 'braket': [['(', ')'], ['[', ']'], ['{', '}']], 'quotes': [['"', '"']], 'literal_quotes': [["'", "'"]], 'immutable': ['\%(^\s\|\n\)\s*']}

  " #1
  let stuffs = s:parser.parse_charwise('foo, bar', rule)
  call g:assert.equals(stuffs, [
        \   {'attr': 'item',      'string': 'foo'},
        \   {'attr': 'delimiter', 'string': ', '},
        \   {'attr': 'item',      'string': 'bar'},
        \ ], 'failed at #1')

  " #2
  let stuffs = s:parser.parse_charwise('foo, bar, baz', rule)
  call g:assert.equals(stuffs, [
        \   {'attr': 'item',      'string': 'foo'},
        \   {'attr': 'delimiter', 'string': ', '},
        \   {'attr': 'item',      'string': 'bar'},
        \   {'attr': 'delimiter', 'string': ', '},
        \   {'attr': 'item',      'string': 'baz'},
        \ ], 'failed at #2')

  " #3
  let stuffs = s:parser.parse_charwise('foo, (bar, baz)', rule)
  call g:assert.equals(stuffs, [
        \   {'attr': 'item',      'string': 'foo'},
        \   {'attr': 'delimiter', 'string': ', '},
        \   {'attr': 'item',      'string': '(bar, baz)'},
        \ ], 'failed at #3')

  " #4
  let stuffs = s:parser.parse_charwise('foo, [bar, baz]', rule)
  call g:assert.equals(stuffs, [
        \   {'attr': 'item',      'string': 'foo'},
        \   {'attr': 'delimiter', 'string': ', '},
        \   {'attr': 'item',      'string': '[bar, baz]'},
        \ ], 'failed at #4')

  " #5
  let stuffs = s:parser.parse_charwise('foo, {bar, baz}', rule)
  call g:assert.equals(stuffs, [
        \   {'attr': 'item',      'string': 'foo'},
        \   {'attr': 'delimiter', 'string': ', '},
        \   {'attr': 'item',      'string': '{bar, baz}'},
        \ ], 'failed at #5')

  " #6
  let stuffs = s:parser.parse_charwise('foo, "bar, baz"', rule)
  call g:assert.equals(stuffs, [
        \   {'attr': 'item',      'string': 'foo'},
        \   {'attr': 'delimiter', 'string': ', '},
        \   {'attr': 'item',      'string': '"bar, baz"'},
        \ ], 'failed at #6')

  " #7
  let stuffs = s:parser.parse_charwise("foo, 'bar, baz'", rule)
  call g:assert.equals(stuffs, [
        \   {'attr': 'item',      'string': 'foo'},
        \   {'attr': 'delimiter', 'string': ', '},
        \   {'attr': 'item',      'string': "'bar, baz'"},
        \ ], 'failed at #7')

  " #8
  let stuffs = s:parser.parse_charwise('(foo, bar), baz, qux', rule)
  call g:assert.equals(stuffs, [
        \   {'attr': 'item',      'string': '(foo, bar)'},
        \   {'attr': 'delimiter', 'string': ', '},
        \   {'attr': 'item',      'string': 'baz'},
        \   {'attr': 'delimiter', 'string': ', '},
        \   {'attr': 'item',      'string': 'qux'},
        \ ], 'failed at #8')

  " #9
  let stuffs = s:parser.parse_charwise('foo, (bar, baz), qux', rule)
  call g:assert.equals(stuffs, [
        \   {'attr': 'item',      'string': 'foo'},
        \   {'attr': 'delimiter', 'string': ', '},
        \   {'attr': 'item',      'string': '(bar, baz)'},
        \   {'attr': 'delimiter', 'string': ', '},
        \   {'attr': 'item',      'string': 'qux'},
        \ ], 'failed at #9')

  " #10
  let stuffs = s:parser.parse_charwise('foo, bar, (baz, qux)', rule)
  call g:assert.equals(stuffs, [
        \   {'attr': 'item',      'string': 'foo'},
        \   {'attr': 'delimiter', 'string': ', '},
        \   {'attr': 'item',      'string': 'bar'},
        \   {'attr': 'delimiter', 'string': ', '},
        \   {'attr': 'item',      'string': '(baz, qux)'},
        \ ], 'failed at #10')

  " #10
  let stuffs = s:parser.parse_charwise('"foo, bar", (baz, qux)', rule)
  call g:assert.equals(stuffs, [
        \   {'attr': 'item',      'string': '"foo, bar"'},
        \   {'attr': 'delimiter', 'string': ', '},
        \   {'attr': 'item',      'string': '(baz, qux)'},
        \ ], 'failed at #10')

  " #11
  let stuffs = s:parser.parse_charwise('"foo, (bar, baz)", qux', rule)
  call g:assert.equals(stuffs, [
        \   {'attr': 'item',      'string': '"foo, (bar, baz)"'},
        \   {'attr': 'delimiter', 'string': ', '},
        \   {'attr': 'item',      'string': 'qux'},
        \ ], 'failed at #11')

  " #12
  let stuffs = s:parser.parse_charwise('(foo, "bar, baz"), qux', rule)
  call g:assert.equals(stuffs, [
        \   {'attr': 'item',      'string': '(foo, "bar, baz")'},
        \   {'attr': 'delimiter', 'string': ', '},
        \   {'attr': 'item',      'string': 'qux'},
        \ ], 'failed at #12')

  " #13
  let stuffs = s:parser.parse_charwise("foo, bar,\n baz, qux", rule)
  call g:assert.equals(stuffs, [
        \   {'attr': 'item',      'string': 'foo'},
        \   {'attr': 'delimiter', 'string': ', '},
        \   {'attr': 'item',      'string': 'bar'},
        \   {'attr': 'delimiter', 'string': ','},
        \   {'attr': 'immutable', 'string': "\n "},
        \   {'attr': 'item',      'string': 'baz'},
        \   {'attr': 'delimiter', 'string': ', '},
        \   {'attr': 'item',      'string': 'qux'},
        \ ], 'failed at #13')

  " #14
  let stuffs = s:parser.parse_charwise("foo, bar\n    , baz, qux", rule)
  call g:assert.equals(stuffs, [
        \   {'attr': 'item',      'string': 'foo'},
        \   {'attr': 'delimiter', 'string': ', '},
        \   {'attr': 'item',      'string': 'bar'},
        \   {'attr': 'immutable', 'string': "\n    "},
        \   {'attr': 'delimiter', 'string': ', '},
        \   {'attr': 'item',      'string': 'baz'},
        \   {'attr': 'delimiter', 'string': ', '},
        \   {'attr': 'item',      'string': 'qux'},
        \ ], 'failed at #14')

  " #15
  let stuffs = s:parser.parse_charwise("foo, bar, , baz", rule)
  call g:assert.equals(stuffs, [
        \   {'attr': 'item',      'string': 'foo'},
        \   {'attr': 'delimiter', 'string': ', '},
        \   {'attr': 'item',      'string': 'bar'},
        \   {'attr': 'delimiter', 'string': ', '},
        \   {'attr': 'item',      'string': ''},
        \   {'attr': 'delimiter', 'string': ', '},
        \   {'attr': 'item',      'string': 'baz'},
        \ ], 'failed at #15')

  " #16
  let stuffs = s:parser.parse_charwise("foo, bar,", rule)
  call g:assert.equals(stuffs, [
        \   {'attr': 'item',      'string': 'foo'},
        \   {'attr': 'delimiter', 'string': ', '},
        \   {'attr': 'item',      'string': 'bar'},
        \   {'attr': 'delimiter', 'string': ','},
        \   {'attr': 'item',      'string': ''},
        \ ], 'failed at #16')

  " #17
  let stuffs = s:parser.parse_charwise(", foo, bar", rule)
  call g:assert.equals(stuffs, [
        \   {'attr': 'item',      'string': ''},
        \   {'attr': 'delimiter', 'string': ', '},
        \   {'attr': 'item',      'string': 'foo'},
        \   {'attr': 'delimiter', 'string': ', '},
        \   {'attr': 'item',      'string': 'bar'},
        \ ], 'failed at #17')

  " #18
  " zero-width delimiter
  let rule = {'body': '\a\+', 'delimiter': ['\C\ze[A-Z]'],}
  let stuffs = s:parser.parse_charwise('FooBarBaz', rule)
  call g:assert.equals(stuffs, [
        \   {'attr': 'item',      'string': 'Foo'},
        \   {'attr': 'delimiter', 'string': ''},
        \   {'attr': 'item',      'string': 'Bar'},
        \   {'attr': 'delimiter', 'string': ''},
        \   {'attr': 'item',      'string': 'Baz'},
        \ ], 'failed at #18')
endfunction "}}}

" integration test
function! s:suite.integration_normal() abort  "{{{
  " #1
  call setline(1, '(foo, bar, baz)')
  execute "normal gglgsl\<Esc>"
  call g:assert.equals(getline('.'), '(bar, foo, baz)', 'failed at #1')

  " #2
  call setline(1, '(foo, bar, baz)')
  execute "normal gg6lgsl\<Esc>"
  call g:assert.equals(getline('.'), '(foo, baz, bar)', 'failed at #2')

  " #3
  call setline(1, '(foo, bar, baz)')
  execute "normal gg11lgsl\<Esc>"
  call g:assert.equals(getline('.'), '(foo, bar, baz)', 'failed at #3')

  " #4
  call setline(1, '(foo, bar, baz)')
  execute "normal gglgsh\<Esc>"
  call g:assert.equals(getline('.'), '(foo, bar, baz)', 'failed at #4')

  " #5
  call setline(1, '(foo, bar, baz)')
  execute "normal gg6lgsh\<Esc>"
  call g:assert.equals(getline('.'), '(bar, foo, baz)', 'failed at #5')

  " #6
  call setline(1, '(foo, bar, baz)')
  execute "normal gg11lgsh\<Esc>"
  call g:assert.equals(getline('.'), '(foo, baz, bar)', 'failed at #6')

  " #7
  call setline(1, '(foo, bar, baz)')
  execute "normal gglgsjl\<Esc>"
  call g:assert.equals(getline('.'), '(foo, baz, bar)', 'failed at #7')

  " #8
  call setline(1, '(foo, bar, baz)')
  execute "normal gg6lgsjl\<Esc>"
  call g:assert.equals(getline('.'), '(foo, bar, baz)', 'failed at #8')

  " #9
  call setline(1, '(foo, bar, baz)')
  execute "normal gg11lgsjl\<Esc>"
  call g:assert.equals(getline('.'), '(foo, bar, baz)', 'failed at #9')

  " #10
  call setline(1, '(foo, bar, baz)')
  execute "normal gglgskh\<Esc>"
  call g:assert.equals(getline('.'), '(foo, bar, baz)', 'failed at #10')

  " #11
  call setline(1, '(foo, bar, baz)')
  execute "normal gg6lgskh\<Esc>"
  call g:assert.equals(getline('.'), '(foo, bar, baz)', 'failed at #11')

  " #12
  call setline(1, '(foo, bar, baz)')
  execute "normal gg11lgskh\<Esc>"
  call g:assert.equals(getline('.'), '(bar, foo, baz)', 'failed at #12')

  " #13
  call setline(1, '(foo, bar, baz)')
  execute "normal gglgsjkl\<Esc>"
  call g:assert.equals(getline('.'), '(bar, foo, baz)', 'failed at #13')

  " #14
  call setline(1, '(foo, bar, baz)')
  execute "normal gglgskjl\<Esc>"
  call g:assert.equals(getline('.'), '(foo, baz, bar)', 'failed at #14')

  " #15
  call setline(1, '(foo, bar, baz)')
  execute "normal gg11lgsjkh\<Esc>"
  call g:assert.equals(getline('.'), '(bar, foo, baz)', 'failed at #15')

  " #16
  call setline(1, '(foo, bar, baz)')
  execute "normal gg11lgskjh\<Esc>"
  call g:assert.equals(getline('.'), '(foo, baz, bar)', 'failed at #16')

  " #16
  call setline(1, '(foo, bar, baz)')
  execute "normal gglgs12\<Esc>"
  call g:assert.equals(getline('.'), '(bar, foo, baz)', 'failed at #16')

  " #17
  call setline(1, '(foo, bar, baz)')
  execute "normal gglgs23\<Esc>"
  call g:assert.equals(getline('.'), '(foo, baz, bar)', 'failed at #17')

  " #18
  call setline(1, '(foo, bar, baz)')
  execute "normal gglgs13\<Esc>"
  call g:assert.equals(getline('.'), '(baz, bar, foo)', 'failed at #18')

  " #19
  call setline(1, '(foo, bar, baz)')
  execute "normal gglgs1223u\<Esc>"
  call g:assert.equals(getline('.'), '(bar, foo, baz)', 'failed at #19')

  " #20
  call setline(1, '(foo, bar, baz)')
  execute "normal gglgs1223u\<C-r>\<Esc>"
  call g:assert.equals(getline('.'), '(bar, baz, foo)', 'failed at #20')

  " #21
  call setline(1, '(foo, bar, baz)')
  execute "normal gglg>"
  call g:assert.equals(getline('.'), '(bar, foo, baz)', 'failed at #21')

  " #22
  call setline(1, '(foo, bar, baz)')
  execute "normal gg6lg>"
  call g:assert.equals(getline('.'), '(foo, baz, bar)', 'failed at #22')

  " #23
  call setline(1, '(foo, bar, baz)')
  execute "normal gg11lg>"
  call g:assert.equals(getline('.'), '(foo, bar, baz)', 'failed at #23')

  " #24
  call setline(1, '(foo, bar, baz)')
  execute "normal gglg<"
  call g:assert.equals(getline('.'), '(foo, bar, baz)', 'failed at #24')

  " #25
  call setline(1, '(foo, bar, baz)')
  execute "normal gg6lg<"
  call g:assert.equals(getline('.'), '(bar, foo, baz)', 'failed at #25')

  " #26
  call setline(1, '(foo, bar, baz)')
  execute "normal gg11lg<"
  call g:assert.equals(getline('.'), '(foo, baz, bar)', 'failed at #26')

  " The case for changing the end position of region.
  " #27
  call append(0, ['(', 'f,', 'b,', 'baz)'])
  execute "normal 2Ggsllh\<Esc>"
  call g:assert.equals(getline(1), '(',    'failed at #27')
  call g:assert.equals(getline(2), 'b,',   'failed at #27')
  call g:assert.equals(getline(3), 'f,',   'failed at #27')
  call g:assert.equals(getline(4), 'baz)', 'failed at #27')
  %delete
endfunction "}}}
function! s:suite.integration_normal_selection_option() abort  "{{{
  " #1
  set selection=exclusive
  call setline(1, '(foo, bar, baz)')
  normal ggfbg<
  call g:assert.equals(getline('.'), '(bar, foo, baz)', 'failed at #1')

  " #2
  set selection=old
  call setline(1, '(foo, bar, baz)')
  normal ggfbg<
  call g:assert.equals(getline('.'), '(bar, foo, baz)', 'failed at #2')

  " #3
  set selection=exclusive
  call setline(1, '(foo, bar, baz)')
  normal ggfbg>
  call g:assert.equals(getline('.'), '(foo, baz, bar)', 'failed at #3')

  " #4
  set selection=old
  call setline(1, '(foo, bar, baz)')
  normal ggfbg>
  call g:assert.equals(getline('.'), '(foo, baz, bar)', 'failed at #4')

  " #5
  set selection=exclusive
  call setline(1, '(foo, bar, baz)')
  execute "normal gglgsl\<Esc>"
  call g:assert.equals(getline('.'), '(bar, foo, baz)', 'failed at #5')

  " #6
  set selection=old
  call setline(1, '(foo, bar, baz)')
  execute "normal gglgsl\<Esc>"
  call g:assert.equals(getline('.'), '(bar, foo, baz)', 'failed at #6')
endfunction "}}}
function! s:suite.integration_visual() abort  "{{{
  " #1
  call setline(1, 'foo, bar, baz')
  execute "normal ggv$gsl\<Esc>"
  call g:assert.equals(getline('.'), 'bar, foo, baz', 'failed at #1')

  " #2
  call append(0, ['foo', 'bar', 'baz'])
  execute "normal ggV2jgsl\<Esc>"
  call g:assert.equals(getline(1), 'bar', 'failed at #2')
  call g:assert.equals(getline(2), 'foo', 'failed at #2')
  call g:assert.equals(getline(3), 'baz', 'failed at #2')
  %delete

  " #3
  call append(0, ['foo', 'bar', 'baz'])
  execute "normal gg\<C-v>2jlgsl\<Esc>"
  call g:assert.equals(getline(1), 'bao', 'failed at #3')
  call g:assert.equals(getline(2), 'for', 'failed at #3')
  call g:assert.equals(getline(3), 'baz', 'failed at #3')
  %delete
endfunction "}}}
function! s:suite.integration_textobj_i() abort "{{{
  " #1
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', ']}]
  call setline(1, 'foo, bar, baz')
  call cursor(1, 1)
  call swap#textobj#select('i')
  call g:assert.equals(mode(), 'v', 'Failed at #1-1')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 1, 0], 'Failed at #1-2')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 3, 0], 'Failed at #1-3')
  execute "normal! \<Esc>"

  " #2
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', ']}]
  call setline(1, 'foo, bar, baz')
  call cursor(1, 6)
  call swap#textobj#select('i')
  call g:assert.equals(mode(), 'v', 'Failed at #2-1')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 6, 0], 'Failed at #2-2')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 8, 0], 'Failed at #2-3')
  execute "normal! \<Esc>"

  " #3
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', ']}]
  call setline(1, 'foo, bar, baz')
  call cursor(1, 11)
  call swap#textobj#select('i')
  call g:assert.equals(mode(), 'v', 'Failed at #3-1')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 11, 0], 'Failed at #3-2')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 13, 0], 'Failed at #3-3')
  execute "normal! \<Esc>"

  " #4
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', ']}]
  call setline(1, 'foo, bar, baz')
  call cursor(1, 4)
  call swap#textobj#select('i')
  call g:assert.equals(mode(), 'v', 'Failed at #4-1')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 6, 0], 'Failed at #4-2')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 8, 0], 'Failed at #4-3')
  execute "normal! \<Esc>"

  " #5
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', ']}]
  call setline(1, 'foo, bar, baz')
  call cursor(1, 9)
  call swap#textobj#select('i')
  call g:assert.equals(mode(), 'v', 'Failed at #5-1')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 11, 0], 'Failed at #5-2')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 13, 0], 'Failed at #5-3')
  execute "normal! \<Esc>"

  " #6
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', ']}]
  call setline(1, 'foo, bar, baz')
  call cursor(1, 1)
  execute "normal! 2:\<C-u>call swap#textobj#select('i')\<CR>"
  call g:assert.equals(mode(), 'v', 'Failed at #6-1')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 1, 0], 'Failed at #6-2')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 8, 0], 'Failed at #6-3')
  execute "normal! \<Esc>"

  " #7
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', ']}]
  call setline(1, 'foo, bar, baz')
  call cursor(1, 1)
  execute "normal! 3:\<C-u>call swap#textobj#select('i')\<CR>"
  call g:assert.equals(mode(), 'v', 'Failed at #7-1')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1,  1, 0], 'Failed at #7-2')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 13, 0], 'Failed at #7-3')
  execute "normal! \<Esc>"

  " #8
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', ']}]
  call setline(1, 'foo, bar, baz')
  call cursor(1, 6)
  execute "normal! 2:\<C-u>call swap#textobj#select('i')\<CR>"
  call g:assert.equals(mode(), 'v', 'Failed at #8-1')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1,  6, 0], 'Failed at #8-2')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 13, 0], 'Failed at #8-3')
  execute "normal! \<Esc>"

  " #9
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', '], 'immutable': ['\s*"immutable\d\?"\s*']}]
  call setline(1, 'foo, "immutable" bar, baz')
  call cursor(1, 16)
  call swap#textobj#select('i')
  call g:assert.equals(mode(), 'v', 'Failed at #9-1')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 18, 0], 'Failed at #9-2')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 20, 0], 'Failed at #9-3')
  execute "normal! \<Esc>"

  " #10
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', '], 'immutable': ['\s*"immutable\d\?"\s*']}]
  call setline(1, 'foo, "immutable1" "immutable2" bar, baz')
  call cursor(1, 32)
  call swap#textobj#select('i')
  call g:assert.equals(mode(), 'v', 'Failed at #10-1')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 32, 0], 'Failed at #10-2')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 34, 0], 'Failed at #10-3')
  execute "normal! \<Esc>"

  " #11
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', '], 'immutable': ['\s*"immutable\d\?"\s*']}]
  call setline(1, 'foo, "immutable1" "immutable2" bar, baz')
  call cursor(1, 18)
  call swap#textobj#select('i')
  call g:assert.equals(mode(), 'v', 'Failed at #11-1')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 32, 0], 'Failed at #11-2')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 34, 0], 'Failed at #11-3')
  execute "normal! \<Esc>"

  " #12
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', ']}]
  call setline(1, ', foo, bar, baz')
  call cursor(1, 1)
  call swap#textobj#select('i')
  call g:assert.equals(mode(), 'v', 'Failed at #12-1')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 3, 0], 'Failed at #12-2')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 5, 0], 'Failed at #12-3')
  execute "normal! \<Esc>"

  " #13
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', ']}]
  call setline(1, 'foo, bar, baz, ')
  call cursor(1, 11)
  call swap#textobj#select('i')
  call g:assert.equals(mode(), 'v', 'Failed at #13-1')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 11, 0], 'Failed at #13-2')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 13, 0], 'Failed at #13-3')
  execute "normal! \<Esc>"
endfunction "}}}
function! s:suite.integration_textobj_a() abort "{{{
  " #1
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', ']}]
  call setline(1, 'foo, bar, baz')
  call cursor(1, 1)
  call swap#textobj#select('a')
  call g:assert.equals(mode(), 'v', 'Failed at #1-1')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 1, 0], 'Failed at #1-2')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 5, 0], 'Failed at #1-3')
  execute "normal! \<Esc>"

  " #2
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', ']}]
  call setline(1, 'foo, bar, baz')
  call cursor(1, 6)
  call swap#textobj#select('a')
  call g:assert.equals(mode(), 'v', 'Failed at #2-1')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 4, 0], 'Failed at #2-2')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 8, 0], 'Failed at #2-3')
  execute "normal! \<Esc>"

  " #3
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', ']}]
  call setline(1, 'foo, bar, baz')
  call cursor(1, 11)
  call swap#textobj#select('a')
  call g:assert.equals(mode(), 'v', 'Failed at #3-1')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1,  9, 0], 'Failed at #3-2')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 13, 0], 'Failed at #3-3')
  execute "normal! \<Esc>"

  " #4
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', ']}]
  call setline(1, 'foo, bar, baz')
  call cursor(1, 4)
  call swap#textobj#select('a')
  call g:assert.equals(mode(), 'v', 'Failed at #4-1')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 4, 0], 'Failed at #4-2')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 8, 0], 'Failed at #4-3')
  execute "normal! \<Esc>"

  " #5
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', ']}]
  call setline(1, 'foo, bar, baz')
  call cursor(1, 9)
  call swap#textobj#select('a')
  call g:assert.equals(mode(), 'v', 'Failed at #5-1')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1,  9, 0], 'Failed at #5-2')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 13, 0], 'Failed at #5-3')
  execute "normal! \<Esc>"

  " #6
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', ']}]
  call setline(1, 'foo, bar, baz')
  call cursor(1, 1)
  execute "normal! 2:\<C-u>call swap#textobj#select('a')\<CR>"
  call g:assert.equals(mode(), 'v', 'Failed at #6-1')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1,  1, 0], 'Failed at #6-2')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 10, 0], 'Failed at #6-3')
  execute "normal! \<Esc>"

  " #7
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', ']}]
  call setline(1, 'foo, bar, baz')
  call cursor(1, 1)
  execute "normal! 3:\<C-u>call swap#textobj#select('a')\<CR>"
  call g:assert.equals(mode(), 'v', 'Failed at #7-1')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1,  1, 0], 'Failed at #7-2')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 13, 0], 'Failed at #7-3')
  execute "normal! \<Esc>"

  " #8
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', ']}]
  call setline(1, 'foo, bar, baz')
  call cursor(1, 6)
  execute "normal! 2:\<C-u>call swap#textobj#select('a')\<CR>"
  call g:assert.equals(mode(), 'v', 'Failed at #8-1')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1,  4, 0], 'Failed at #8-2')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 13, 0], 'Failed at #8-3')
  execute "normal! \<Esc>"

  " #9
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', '], 'immutable': ['\s*"immutable\d\?"\s*']}]
  call setline(1, 'foo, "immutable" bar, baz')
  call cursor(1, 16)
  call swap#textobj#select('a')
  call g:assert.equals(mode(), 'v', 'Failed at #9-1')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1,  4, 0], 'Failed at #9-2')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 20, 0], 'Failed at #9-3')
  execute "normal! \<Esc>"

  " #10
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', '], 'immutable': ['\s*"immutable\d\?"\s*']}]
  call setline(1, 'foo, "immutable1" "immutable2" bar, baz')
  call cursor(1, 32)
  call swap#textobj#select('a')
  call g:assert.equals(mode(), 'v', 'Failed at #10-1')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1,  4, 0], 'Failed at #10-2')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 34, 0], 'Failed at #10-3')
  execute "normal! \<Esc>"

  " #11
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', '], 'immutable': ['\s*"immutable\d\?"\s*']}]
  call setline(1, 'foo, "immutable1" "immutable2" bar, baz')
  call cursor(1, 18)
  call swap#textobj#select('a')
  call g:assert.equals(mode(), 'v', 'Failed at #11-1')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1,  4, 0], 'Failed at #11-2')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 34, 0], 'Failed at #11-3')
  execute "normal! \<Esc>"

  " #12
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', ']}]
  call setline(1, ', foo, bar, baz')
  call cursor(1, 1)
  call swap#textobj#select('a')
  call g:assert.equals(mode(), 'v', 'Failed at #12-1')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 1, 0], 'Failed at #12-2')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 5, 0], 'Failed at #12-3')
  execute "normal! \<Esc>"

  " #13
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', ']}]
  call setline(1, 'foo, bar, baz, ')
  call cursor(1, 11)
  call swap#textobj#select('a')
  call g:assert.equals(mode(), 'v', 'Failed at #13-1')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1,  9, 0], 'Failed at #13-2')
  normal! o
  call g:assert.equals(getpos('.'), [0, 1, 13, 0], 'Failed at #13-3')
  execute "normal! \<Esc>"
endfunction "}}}



" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" vim:set ts=2 sts=2 sw=2:
