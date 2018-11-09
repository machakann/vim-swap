let s:suite = themis#suite('swap: ')

let s:scope = themis#helper('scope')
let s:parser = s:scope.funcs('autoload/swap/parser.vim')
let s:Lib = s:scope.funcs('autoload/swap/lib.vim')
let s:swap = s:scope.funcs('autoload/swap/swap.vim')

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
"" autoload/swap/parser.vim
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
  let l = s:Lib.buf_byte_len([0, 1, 1, 0], getpos('.'))
  call g:assert.equals(l, 0)

  call append(0, ['abc'])
  normal! 1Gl
  let l = s:Lib.buf_byte_len([0, 1, 1, 0], getpos('.'))
  call g:assert.equals(l, 1)

  call append(0, ['abc'])
  normal! 1G2l
  let l = s:Lib.buf_byte_len([0, 1, 1, 0], getpos('.'))
  call g:assert.equals(l, 2)

  call append(0, ['abc', 'def'])
  normal! 2G
  let l = s:Lib.buf_byte_len([0, 1, 1, 0], getpos('.'))
  call g:assert.equals(l, 4)

  call append(0, ['abc', 'def'])
  normal! 2Gl
  let l = s:Lib.buf_byte_len([0, 1, 1, 0], getpos('.'))
  call g:assert.equals(l, 5)

  call append(0, ['abc', 'def'])
  normal! 2G2l
  let l = s:Lib.buf_byte_len([0, 1, 1, 0], getpos('.'))
  call g:assert.equals(l, 6)

  call append(0, ['abc', 'def', 'ghi'])
  normal! 3G
  let l = s:Lib.buf_byte_len([0, 1, 1, 0], getpos('.'))
  call g:assert.equals(l, 8)

  call append(0, ['abc', 'def', 'ghi'])
  normal! 3Gl
  let l = s:Lib.buf_byte_len([0, 1, 1, 0], getpos('.'))
  call g:assert.equals(l, 9)

  call append(0, ['abc', 'def', 'ghi'])
  normal! 3G2l
  let l = s:Lib.buf_byte_len([0, 1, 1, 0], getpos('.'))
  call g:assert.equals(l, 10)

  call append(0, ['', 'def', 'ghi'])
  normal! 1G
  let l = s:Lib.buf_byte_len([0, 1, 1, 0], getpos('.'))
  call g:assert.equals(l, 0)

  call append(0, ['', 'def', 'ghi'])
  normal! 2G
  let l = s:Lib.buf_byte_len([0, 1, 1, 0], getpos('.'))
  call g:assert.equals(l, 1)

  call append(0, ['', 'def', 'ghi'])
  normal! 3G
  let l = s:Lib.buf_byte_len([0, 1, 1, 0], getpos('.'))
  call g:assert.equals(l, 5)

  call append(0, ['abc', '', 'ghi'])
  normal! 2G
  let l = s:Lib.buf_byte_len([0, 1, 1, 0], getpos('.'))
  call g:assert.equals(l, 4)

  call append(0, ['abc', '', 'ghi'])
  normal! 3G
  let l = s:Lib.buf_byte_len([0, 1, 1, 0], getpos('.'))
  call g:assert.equals(l, 5)

  call append(0, ['abc', 'def', ''])
  normal! 3G
  let l = s:Lib.buf_byte_len([0, 1, 1, 0], getpos('.'))
  call g:assert.equals(l, 8)
endfunction "}}}
function! s:suite.parse_charwise() abort  "{{{
  let rule = {'surrounds': ['(', ')', 1], 'delimiter': [',\s*'], 'braket': [['(', ')'], ['[', ']'], ['{', '}']], 'quotes': [['"', '"']], 'literal_quotes': [["'", "'"]], 'immutable': ['\%(^\s\|\n\)\s*']}

  " #1
  let stuffs = s:parser.parse_charwise('foo, bar', rule)
  call g:assert.equals(len(stuffs), 3, 'failed at #1-1')
  call g:assert.equals(stuffs[0]['attr'], 'item',      'failed at #1-2')
  call g:assert.equals(stuffs[0]['str'],  'foo',       'failed at #1-3')
  call g:assert.equals(stuffs[1]['attr'], 'delimiter', 'failed at #1-4')
  call g:assert.equals(stuffs[1]['str'],  ', ',        'failed at #1-5')
  call g:assert.equals(stuffs[2]['attr'], 'item',      'failed at #1-6')
  call g:assert.equals(stuffs[2]['str'],  'bar',       'failed at #1-7')

  " #2
  let stuffs = s:parser.parse_charwise('foo, bar, baz', rule)
  call g:assert.equals(len(stuffs), 5, 'failed at #2-1')
  call g:assert.equals(stuffs[0]['attr'], 'item',      'failed at #2-2')
  call g:assert.equals(stuffs[0]['str'],  'foo',       'failed at #2-3')
  call g:assert.equals(stuffs[1]['attr'], 'delimiter', 'failed at #2-4')
  call g:assert.equals(stuffs[1]['str'],  ', ',        'failed at #2-5')
  call g:assert.equals(stuffs[2]['attr'], 'item',      'failed at #2-6')
  call g:assert.equals(stuffs[2]['str'],  'bar',       'failed at #2-7')
  call g:assert.equals(stuffs[3]['attr'], 'delimiter', 'failed at #2-8')
  call g:assert.equals(stuffs[3]['str'],  ', ',        'failed at #2-9')
  call g:assert.equals(stuffs[4]['attr'], 'item',      'failed at #2-10')
  call g:assert.equals(stuffs[4]['str'],  'baz',       'failed at #2-11')

  " #3
  let stuffs = s:parser.parse_charwise('foo, (bar, baz)', rule)
  call g:assert.equals(len(stuffs), 3, 'failed at #3-1')
  call g:assert.equals(stuffs[0]['attr'], 'item',       'failed at #3-2')
  call g:assert.equals(stuffs[0]['str'],  'foo',        'failed at #3-3')
  call g:assert.equals(stuffs[1]['attr'], 'delimiter',  'failed at #3-4')
  call g:assert.equals(stuffs[1]['str'],  ', ',         'failed at #3-5')
  call g:assert.equals(stuffs[2]['attr'], 'item',       'failed at #3-6')
  call g:assert.equals(stuffs[2]['str'],  '(bar, baz)', 'failed at #3-7')

  " #4
  let stuffs = s:parser.parse_charwise('foo, [bar, baz]', rule)
  call g:assert.equals(len(stuffs), 3, 'failed at #4-1')
  call g:assert.equals(stuffs[0]['attr'], 'item',       'failed at #4-2')
  call g:assert.equals(stuffs[0]['str'],  'foo',        'failed at #4-3')
  call g:assert.equals(stuffs[1]['attr'], 'delimiter',  'failed at #4-4')
  call g:assert.equals(stuffs[1]['str'],  ', ',         'failed at #4-5')
  call g:assert.equals(stuffs[2]['attr'], 'item',       'failed at #4-6')
  call g:assert.equals(stuffs[2]['str'],  '[bar, baz]', 'failed at #4-7')

  " #5
  let stuffs = s:parser.parse_charwise('foo, {bar, baz}', rule)
  call g:assert.equals(len(stuffs), 3, 'failed at #5-1')
  call g:assert.equals(stuffs[0]['attr'], 'item',       'failed at #5-2')
  call g:assert.equals(stuffs[0]['str'],  'foo',        'failed at #5-3')
  call g:assert.equals(stuffs[1]['attr'], 'delimiter',  'failed at #5-4')
  call g:assert.equals(stuffs[1]['str'],  ', ',         'failed at #5-5')
  call g:assert.equals(stuffs[2]['attr'], 'item',       'failed at #5-6')
  call g:assert.equals(stuffs[2]['str'],  '{bar, baz}', 'failed at #5-7')

  " #6
  let stuffs = s:parser.parse_charwise('foo, "bar, baz"', rule)
  call g:assert.equals(len(stuffs), 3, 'failed at #6-1')
  call g:assert.equals(stuffs[0]['attr'], 'item',       'failed at #6-2')
  call g:assert.equals(stuffs[0]['str'],  'foo',        'failed at #6-3')
  call g:assert.equals(stuffs[1]['attr'], 'delimiter',  'failed at #6-4')
  call g:assert.equals(stuffs[1]['str'],  ', ',         'failed at #6-5')
  call g:assert.equals(stuffs[2]['attr'], 'item',       'failed at #6-6')
  call g:assert.equals(stuffs[2]['str'],  '"bar, baz"', 'failed at #6-7')

  " #7
  let stuffs = s:parser.parse_charwise("foo, 'bar, baz'", rule)
  call g:assert.equals(len(stuffs), 3, 'failed at #7-1')
  call g:assert.equals(stuffs[0]['attr'], 'item',       'failed at #7-2')
  call g:assert.equals(stuffs[0]['str'],  'foo',        'failed at #7-3')
  call g:assert.equals(stuffs[1]['attr'], 'delimiter',  'failed at #7-4')
  call g:assert.equals(stuffs[1]['str'],  ', ',         'failed at #7-5')
  call g:assert.equals(stuffs[2]['attr'], 'item',       'failed at #7-6')
  call g:assert.equals(stuffs[2]['str'],  "'bar, baz'", 'failed at #7-7')

  " #8
  let stuffs = s:parser.parse_charwise('(foo, bar), baz, qux', rule)
  call g:assert.equals(len(stuffs), 5, 'failed at #8-1')
  call g:assert.equals(stuffs[0]['attr'], 'item',       'failed at #8-2')
  call g:assert.equals(stuffs[0]['str'],  '(foo, bar)', 'failed at #8-3')
  call g:assert.equals(stuffs[1]['attr'], 'delimiter',  'failed at #8-4')
  call g:assert.equals(stuffs[1]['str'],  ', ',         'failed at #8-5')
  call g:assert.equals(stuffs[2]['attr'], 'item',       'failed at #8-6')
  call g:assert.equals(stuffs[2]['str'],  'baz',        'failed at #8-7')
  call g:assert.equals(stuffs[3]['attr'], 'delimiter',  'failed at #8-8')
  call g:assert.equals(stuffs[3]['str'],  ', ',         'failed at #8-9')
  call g:assert.equals(stuffs[4]['attr'], 'item',       'failed at #8-10')
  call g:assert.equals(stuffs[4]['str'],  'qux',        'failed at #8-11')

  " #9
  let stuffs = s:parser.parse_charwise('foo, (bar, baz), qux', rule)
  call g:assert.equals(len(stuffs), 5, 'failed at #9-1')
  call g:assert.equals(stuffs[0]['attr'], 'item',       'failed at #9-2')
  call g:assert.equals(stuffs[0]['str'],  'foo',        'failed at #9-3')
  call g:assert.equals(stuffs[1]['attr'], 'delimiter',  'failed at #9-4')
  call g:assert.equals(stuffs[1]['str'],  ', ',         'failed at #9-5')
  call g:assert.equals(stuffs[2]['attr'], 'item',       'failed at #9-6')
  call g:assert.equals(stuffs[2]['str'],  '(bar, baz)', 'failed at #9-7')
  call g:assert.equals(stuffs[3]['attr'], 'delimiter',  'failed at #9-8')
  call g:assert.equals(stuffs[3]['str'],  ', ',         'failed at #9-9')
  call g:assert.equals(stuffs[4]['attr'], 'item',       'failed at #9-10')
  call g:assert.equals(stuffs[4]['str'],  'qux',        'failed at #9-11')

  " #10
  let stuffs = s:parser.parse_charwise('foo, bar, (baz, qux)', rule)
  call g:assert.equals(len(stuffs), 5, 'failed at #10-1')
  call g:assert.equals(stuffs[0]['attr'], 'item',       'failed at #10-2')
  call g:assert.equals(stuffs[0]['str'],  'foo',        'failed at #10-3')
  call g:assert.equals(stuffs[1]['attr'], 'delimiter',  'failed at #10-4')
  call g:assert.equals(stuffs[1]['str'],  ', ',         'failed at #10-5')
  call g:assert.equals(stuffs[2]['attr'], 'item',       'failed at #10-6')
  call g:assert.equals(stuffs[2]['str'],  'bar',        'failed at #10-7')
  call g:assert.equals(stuffs[3]['attr'], 'delimiter',  'failed at #10-8')
  call g:assert.equals(stuffs[3]['str'],  ', ',         'failed at #10-9')
  call g:assert.equals(stuffs[4]['attr'], 'item',       'failed at #10-10')
  call g:assert.equals(stuffs[4]['str'],  '(baz, qux)', 'failed at #10-11')

  " #11
  let stuffs = s:parser.parse_charwise('"foo, bar", (baz, qux)', rule)
  call g:assert.equals(len(stuffs), 3, 'failed at #11-1')
  call g:assert.equals(stuffs[0]['attr'], 'item',       'failed at #11-2')
  call g:assert.equals(stuffs[0]['str'],  '"foo, bar"', 'failed at #11-3')
  call g:assert.equals(stuffs[1]['attr'], 'delimiter',  'failed at #11-4')
  call g:assert.equals(stuffs[1]['str'],  ', ',         'failed at #11-5')
  call g:assert.equals(stuffs[2]['attr'], 'item',       'failed at #11-6')
  call g:assert.equals(stuffs[2]['str'],  '(baz, qux)', 'failed at #11-7')

  " #12
  let stuffs = s:parser.parse_charwise('"foo, (bar, baz)", qux', rule)
  call g:assert.equals(len(stuffs), 3, 'failed at #12-1')
  call g:assert.equals(stuffs[0]['attr'], 'item',       'failed at #12-2')
  call g:assert.equals(stuffs[0]['str'],  '"foo, (bar, baz)"', 'failed at #12-3')
  call g:assert.equals(stuffs[1]['attr'], 'delimiter',  'failed at #12-4')
  call g:assert.equals(stuffs[1]['str'],  ', ',         'failed at #12-5')
  call g:assert.equals(stuffs[2]['attr'], 'item',       'failed at #12-6')
  call g:assert.equals(stuffs[2]['str'],  'qux',        'failed at #12-7')

  " #13
  let stuffs = s:parser.parse_charwise('(foo, "bar, baz"), qux', rule)
  call g:assert.equals(len(stuffs), 3, 'failed at #13-1')
  call g:assert.equals(stuffs[0]['attr'], 'item',       'failed at #13-2')
  call g:assert.equals(stuffs[0]['str'],  '(foo, "bar, baz")', 'failed at #13-3')
  call g:assert.equals(stuffs[1]['attr'], 'delimiter',  'failed at #13-4')
  call g:assert.equals(stuffs[1]['str'],  ', ',         'failed at #13-5')
  call g:assert.equals(stuffs[2]['attr'], 'item',       'failed at #13-6')
  call g:assert.equals(stuffs[2]['str'],  'qux',        'failed at #13-7')

  " #14
  let stuffs = s:parser.parse_charwise("foo, bar,\n baz, qux", rule)
  call g:assert.equals(len(stuffs), 8, 'failed at #14-1')
  call g:assert.equals(stuffs[0]['attr'], 'item',       'failed at #14-2')
  call g:assert.equals(stuffs[0]['str'],  'foo',        'failed at #14-3')
  call g:assert.equals(stuffs[1]['attr'], 'delimiter',  'failed at #14-4')
  call g:assert.equals(stuffs[1]['str'],  ', ',         'failed at #14-5')
  call g:assert.equals(stuffs[2]['attr'], 'item',       'failed at #14-6')
  call g:assert.equals(stuffs[2]['str'],  'bar',        'failed at #14-7')
  call g:assert.equals(stuffs[3]['attr'], 'delimiter',  'failed at #14-8')
  call g:assert.equals(stuffs[3]['str'],  ',',          'failed at #14-9')
  call g:assert.equals(stuffs[4]['attr'], 'immutable',  'failed at #14-10')
  call g:assert.equals(stuffs[4]['str'],  "\n ",        'failed at #14-11')
  call g:assert.equals(stuffs[5]['attr'], 'item',       'failed at #14-12')
  call g:assert.equals(stuffs[5]['str'],  'baz',        'failed at #14-13')
  call g:assert.equals(stuffs[6]['attr'], 'delimiter',  'failed at #14-14')
  call g:assert.equals(stuffs[6]['str'],  ', ',         'failed at #14-15')
  call g:assert.equals(stuffs[7]['attr'], 'item',       'failed at #14-16')
  call g:assert.equals(stuffs[7]['str'],  'qux',        'failed at #14-17')

  " #15
  let stuffs = s:parser.parse_charwise("foo, bar\n    , baz, qux", rule)
  call g:assert.equals(len(stuffs), 8, 'failed at #14-1')
  call g:assert.equals(stuffs[0]['attr'], 'item',       'failed at #15-2')
  call g:assert.equals(stuffs[0]['str'],  'foo',        'failed at #15-3')
  call g:assert.equals(stuffs[1]['attr'], 'delimiter',  'failed at #15-4')
  call g:assert.equals(stuffs[1]['str'],  ', ',         'failed at #15-5')
  call g:assert.equals(stuffs[2]['attr'], 'item',       'failed at #15-6')
  call g:assert.equals(stuffs[2]['str'],  'bar',        'failed at #15-7')
  call g:assert.equals(stuffs[3]['attr'], 'immutable',  'failed at #15-8')
  call g:assert.equals(stuffs[3]['str'],  "\n    ",     'failed at #15-9')
  call g:assert.equals(stuffs[4]['attr'], 'delimiter',  'failed at #15-10')
  call g:assert.equals(stuffs[4]['str'],  ', ',         'failed at #15-11')
  call g:assert.equals(stuffs[5]['attr'], 'item',       'failed at #15-12')
  call g:assert.equals(stuffs[5]['str'],  'baz',        'failed at #15-13')
  call g:assert.equals(stuffs[6]['attr'], 'delimiter',  'failed at #15-14')
  call g:assert.equals(stuffs[6]['str'],  ', ',         'failed at #15-15')
  call g:assert.equals(stuffs[7]['attr'], 'item',       'failed at #15-16')
  call g:assert.equals(stuffs[7]['str'],  'qux',        'failed at #15-17')

  " #16
  let stuffs = s:parser.parse_charwise("foo, bar, , baz", rule)
  call g:assert.equals(len(stuffs), 7, 'failed at #14-1')
  call g:assert.equals(stuffs[0]['attr'], 'item',       'failed at #16-2')
  call g:assert.equals(stuffs[0]['str'],  'foo',        'failed at #16-3')
  call g:assert.equals(stuffs[1]['attr'], 'delimiter',  'failed at #16-4')
  call g:assert.equals(stuffs[1]['str'],  ', ',         'failed at #16-5')
  call g:assert.equals(stuffs[2]['attr'], 'item',       'failed at #16-6')
  call g:assert.equals(stuffs[2]['str'],  'bar',        'failed at #16-7')
  call g:assert.equals(stuffs[3]['attr'], 'delimiter',  'failed at #16-8')
  call g:assert.equals(stuffs[3]['str'],  ', ',         'failed at #16-9')
  call g:assert.equals(stuffs[4]['attr'], 'item',       'failed at #16-10')
  call g:assert.equals(stuffs[4]['str'],  '',           'failed at #16-11')
  call g:assert.equals(stuffs[5]['attr'], 'delimiter',  'failed at #16-12')
  call g:assert.equals(stuffs[5]['str'],  ', ',         'failed at #16-13')
  call g:assert.equals(stuffs[6]['attr'], 'item',       'failed at #16-14')
  call g:assert.equals(stuffs[6]['str'],  'baz',        'failed at #16-15')

  " #17
  let stuffs = s:parser.parse_charwise("foo, bar,", rule)
  call g:assert.equals(len(stuffs), 5, 'failed at #14-1')
  call g:assert.equals(stuffs[0]['attr'], 'item',       'failed at #17-2')
  call g:assert.equals(stuffs[0]['str'],  'foo',        'failed at #17-3')
  call g:assert.equals(stuffs[1]['attr'], 'delimiter',  'failed at #17-4')
  call g:assert.equals(stuffs[1]['str'],  ', ',         'failed at #17-5')
  call g:assert.equals(stuffs[2]['attr'], 'item',       'failed at #17-6')
  call g:assert.equals(stuffs[2]['str'],  'bar',        'failed at #17-7')
  call g:assert.equals(stuffs[3]['attr'], 'delimiter',  'failed at #17-8')
  call g:assert.equals(stuffs[3]['str'],  ',',          'failed at #17-9')
  call g:assert.equals(stuffs[4]['attr'], 'item',       'failed at #17-10')
  call g:assert.equals(stuffs[4]['str'],  '',           'failed at #17-11')

  " #18
  let stuffs = s:parser.parse_charwise(", foo, bar", rule)
  call g:assert.equals(len(stuffs), 5, 'failed at #14-1')
  call g:assert.equals(stuffs[0]['attr'], 'item',       'failed at #18-2')
  call g:assert.equals(stuffs[0]['str'],  '',           'failed at #18-3')
  call g:assert.equals(stuffs[1]['attr'], 'delimiter',  'failed at #18-4')
  call g:assert.equals(stuffs[1]['str'],  ', ',         'failed at #18-5')
  call g:assert.equals(stuffs[2]['attr'], 'item',       'failed at #18-6')
  call g:assert.equals(stuffs[2]['str'],  'foo',        'failed at #18-7')
  call g:assert.equals(stuffs[3]['attr'], 'delimiter',  'failed at #18-8')
  call g:assert.equals(stuffs[3]['str'],  ', ',         'failed at #18-9')
  call g:assert.equals(stuffs[4]['attr'], 'item',       'failed at #18-10')
  call g:assert.equals(stuffs[4]['str'],  'bar',        'failed at #18-11')

  " #19
  " zero-width delimiter
  let rule = {'body': '\a\+', 'delimiter': ['\C\ze[A-Z]'],}
  let stuffs = s:parser.parse_charwise('FooBarBaz', rule)
  call g:assert.equals(len(stuffs), 5, 'failed at #14-1')
  call g:assert.equals(stuffs[0]['attr'], 'item',       'failed at #18-2')
  call g:assert.equals(stuffs[0]['str'],  'Foo',        'failed at #18-3')
  call g:assert.equals(stuffs[1]['attr'], 'delimiter',  'failed at #18-4')
  call g:assert.equals(stuffs[1]['str'],  '',           'failed at #18-5')
  call g:assert.equals(stuffs[2]['attr'], 'item',       'failed at #18-6')
  call g:assert.equals(stuffs[2]['str'],  'Bar',        'failed at #18-7')
  call g:assert.equals(stuffs[3]['attr'], 'delimiter',  'failed at #18-8')
  call g:assert.equals(stuffs[3]['str'],  '',           'failed at #18-9')
  call g:assert.equals(stuffs[4]['attr'], 'item',       'failed at #18-10')
  call g:assert.equals(stuffs[4]['str'],  'Baz',        'failed at #18-11')
endfunction "}}}

" autoload/swap/swap.vim
function! s:suite.sort() abort "{{{
  let rule = {'delimiter': [',\s*']}
  let buf = {}
  let buf.all = s:parser.parse_charwise('dd, aa, bb, cc', rule)
  let buf.items = filter(copy(buf.all), 'v:val.attr is# "item"')

  " #1
  let newbuf = s:swap.sort(buf, [s:Lib.compare_ascend])
  let newstr = s:swap.string(newbuf)
  call g:assert.equals(newstr, 'aa, bb, cc, dd', 'failed at #1')

  " #2
  let newbuf = s:swap.sort(buf, [s:Lib.compare_descend])
  let newstr = s:swap.string(newbuf)
  call g:assert.equals(newstr, 'dd, cc, bb, aa', 'failed at #2')
endfunction "}}}
function! s:suite.get_rules() abort "{{{
  " #1
  let rules = [{'body': 'a,b', 'delimiter': ','}]
  let got = s:swap.get_rules(rules, '', 'n')
  call g:assert.length_of(got, 1, 'failed at #1')

  " #2
  " Filter the rule which does not have neither 'body' nor 'surrounds'
  let rules = [{'delimiter': ','}]
  let got = s:swap.get_rules(rules, '', 'n')
  call g:assert.length_of(got, 0, 'failed at #2')

  " #3
  " Do not filter the rule which does not have neither 'body' nor 'surrounds'
  let rules = [{'delimiter': ','}]
  let got = s:swap.get_rules(rules, '', 'x')
  call g:assert.length_of(got, 1, 'failed at #3')

  " #4
  " test filetype filter
  let rules = [
  \   {'body': 'a,b', 'delimiter': ',', 'filetype': ['foo']},
  \   {'body': 'c,d', 'delimiter': ',', 'filetype': ['foo']},
  \   {'body': 'e,f', 'delimiter': ',', 'filetype': ['bar']},
  \ ]
  let got = s:swap.get_rules(rules, 'foo', 'n')
  call g:assert.length_of(got, 2, 'failed at #4')

  " #5
  " test mode filter
  let rules = [
  \   {'body': 'a,b', 'delimiter': ',', 'mode': 'n'},
  \   {'body': 'c,d', 'delimiter': ',', 'mode': 'n'},
  \   {'body': 'e,f', 'delimiter': ',', 'mode': 'x'},
  \ ]
  let got = s:swap.get_rules(rules, '', 'n')
  call g:assert.length_of(got, 2, 'failed at #5')

  " #6
  " test filters
  let rules = [
  \   {'body': 'a,b', 'delimiter': ',', 'filetype': ['foo'], 'mode': 'n'},
  \   {'body': 'c,d', 'delimiter': ',', 'filetype': ['bar'], 'mode': 'n'},
  \   {'body': 'e,f', 'delimiter': ',', 'filetype': ['foo'], 'mode': 'x'},
  \ ]
  let got = s:swap.get_rules(rules, 'foo', 'n')
  call g:assert.length_of(got, 1, 'failed at #6')

  " #7
  " Remove duplicates
  let rules = [
  \   {'body': 'a,b', 'delimiter': ','},
  \   {'body': 'a,b', 'delimiter': ';'},
  \   {'surrounds': ['c', 'd'], 'delimiter': ','},
  \   {'surrounds': ['c', 'd'], 'delimiter': ';'},
  \ ]
  let got = s:swap.get_rules(rules, '', 'n')
  call g:assert.length_of(got, 2, 'failed at #7')
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

  " #28
  call append(0, ['(', 'foo, bar, baz)'])
  execute "normal 2G6lg<"
  call g:assert.equals(getline('.'), 'bar, foo, baz)', 'failed at #28')
  %delete

  " #29
  call setline(1, '(dd, bb, cc, aa)')
  execute "normal 1Glgss\<Esc>"
  call g:assert.equals(getline('.'), '(aa, bb, cc, dd)', 'failed at #29')

  " #30
  call setline(1, '(dd, bb, cc, aa)')
  execute "normal 1GlgsS\<Esc>"
  call g:assert.equals(getline('.'), '(dd, cc, bb, aa)', 'failed at #30')

  " #31
  call setline(1, '(dd, bb, cc, aa)')
  let saved = g:swap#mode#sortfunc
  let g:swap#mode#sortfunc = [s:Lib.compare_descend]
  execute "normal 1Glgss\<Esc>"
  call g:assert.equals(getline('.'), '(dd, cc, bb, aa)', 'failed at #31')
  let g:swap#mode#sortfunc = saved

  " #32
  call setline(1, '(dd, bb, cc, aa)')
  let saved = g:swap#mode#SORTFUNC
  let g:swap#mode#SORTFUNC = [s:Lib.compare_ascend]
  execute "normal 1GlgsS\<Esc>"
  call g:assert.equals(getline('.'), '(aa, bb, cc, dd)', 'failed at #32')
  let g:swap#mode#SORTFUNC = saved

  " #33
  call setline(1, '(dd, bb, cc, aa)')
  execute "normal 1Glgss12\<Esc>"
  call g:assert.equals(getline('.'), '(bb, aa, cc, dd)', 'failed at #33')
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

  " #4
  call setline(1, 'dd, bb, cc, aa')
  execute "normal ggv$gss\<Esc>"
  call g:assert.equals(getline('.'), 'aa, bb, cc, dd', 'failed at #4')

  " #5
  call setline(1, 'dd, bb, cc, aa')
  execute "normal ggv$gsS\<Esc>"
  call g:assert.equals(getline('.'), 'dd, cc, bb, aa', 'failed at #5')
endfunction "}}}
function! s:suite.integration_textobj_i() abort "{{{
  " #1
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', ']}]
  call setline(1, 'foo, bar, baz')
  call cursor(1, 1)
  call swap#textobj#select('i')
  normal! ""y
  call g:assert.equals(@@, 'foo', 'Failed at #1')

  " #2
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', ']}]
  call setline(1, 'foo, bar, baz')
  call cursor(1, 6)
  call swap#textobj#select('i')
  normal! ""y
  call g:assert.equals(@@, 'bar', 'Failed at #2')

  " #3
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', ']}]
  call setline(1, 'foo, bar, baz')
  call cursor(1, 11)
  call swap#textobj#select('i')
  normal! ""y
  call g:assert.equals(@@, 'baz', 'Failed at #3')

  " #4
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', ']}]
  call setline(1, 'foo, bar, baz')
  call cursor(1, 4)
  call swap#textobj#select('i')
  normal! ""y
  call g:assert.equals(@@, 'bar', 'Failed at #4')

  " #5
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', ']}]
  call setline(1, 'foo, bar, baz')
  call cursor(1, 9)
  call swap#textobj#select('i')
  normal! ""y
  call g:assert.equals(@@, 'baz', 'Failed at #5')

  " #6
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', ']}]
  call setline(1, 'foo, bar, baz')
  call cursor(1, 1)
  execute "normal! 2:\<C-u>call swap#textobj#select('i')\<CR>"
  normal! ""y
  call g:assert.equals(@@, 'foo, bar', 'Failed at #6')

  " #7
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', ']}]
  call setline(1, 'foo, bar, baz')
  call cursor(1, 1)
  execute "normal! 3:\<C-u>call swap#textobj#select('i')\<CR>"
  normal! ""y
  call g:assert.equals(@@, 'foo, bar, baz', 'Failed at #7')

  " #8
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', ']}]
  call setline(1, 'foo, bar, baz')
  call cursor(1, 6)
  execute "normal! 2:\<C-u>call swap#textobj#select('i')\<CR>"
  normal! ""y
  call g:assert.equals(@@, 'bar, baz', 'Failed at #8')

  " #9
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', '], 'immutable': ['\s*"immutable\d\?"\s*']}]
  call setline(1, 'foo, "immutable" bar, baz')
  call cursor(1, 16)
  call swap#textobj#select('i')
  normal! ""y
  call g:assert.equals(@@, 'bar', 'Failed at #9')

  " #10
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', '], 'immutable': ['\s*"immutable\d\?"\s*']}]
  call setline(1, 'foo, "immutable1" "immutable2" bar, baz')
  call cursor(1, 32)
  call swap#textobj#select('i')
  normal! ""y
  call g:assert.equals(@@, 'bar', 'Failed at #10')

  " #11
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', '], 'immutable': ['\s*"immutable\d\?"\s*']}]
  call setline(1, 'foo, "immutable1" "immutable2" bar, baz')
  call cursor(1, 18)
  call swap#textobj#select('i')
  normal! ""y
  call g:assert.equals(@@, 'bar', 'Failed at #11')

  " #12
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', ']}]
  call setline(1, ', foo, bar, baz')
  call cursor(1, 1)
  call swap#textobj#select('i')
  normal! ""y
  call g:assert.equals(@@, 'foo', 'Failed at #12')

  " #13
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', ']}]
  call setline(1, 'foo, bar, baz, ')
  call cursor(1, 11)
  call swap#textobj#select('i')
  normal! ""y
  call g:assert.equals(@@, 'baz', 'Failed at #13')

  " #14
  let g:swap#rules = [{'surrounds': ['(', ')'], 'delimiter': [', ']}]
  call setline(1, '(((foo), bar), baz)')
  call cursor(1, 4)
  call swap#textobj#select('i')
  normal! ""y
  call g:assert.equals(@@, 'foo', 'Failed at #14')
endfunction "}}}
function! s:suite.integration_textobj_a() abort "{{{
  " #1
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', ']}]
  call setline(1, 'foo, bar, baz')
  call cursor(1, 1)
  call swap#textobj#select('a')
  normal! ""y
  call g:assert.equals(@@, 'foo, ', 'Failed at #1')

  " #2
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', ']}]
  call setline(1, 'foo, bar, baz')
  call cursor(1, 6)
  call swap#textobj#select('a')
  normal! ""y
  call g:assert.equals(@@, ', bar', 'Failed at #2')

  " #3
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', ']}]
  call setline(1, 'foo, bar, baz')
  call cursor(1, 11)
  call swap#textobj#select('a')
  normal! ""y
  call g:assert.equals(@@, ', baz', 'Failed at #3')

  " #4
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', ']}]
  call setline(1, 'foo, bar, baz')
  call cursor(1, 4)
  call swap#textobj#select('a')
  normal! ""y
  call g:assert.equals(@@, ', bar', 'Failed at #4')

  " #5
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', ']}]
  call setline(1, 'foo, bar, baz')
  call cursor(1, 9)
  call swap#textobj#select('a')
  normal! ""y
  call g:assert.equals(@@, ', baz', 'Failed at #5')

  " #6
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', ']}]
  call setline(1, 'foo, bar, baz')
  call cursor(1, 1)
  execute "normal! 2:\<C-u>call swap#textobj#select('a')\<CR>"
  normal! ""y
  call g:assert.equals(@@, 'foo, bar, ', 'Failed at #6')

  " #7
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', ']}]
  call setline(1, 'foo, bar, baz')
  call cursor(1, 1)
  execute "normal! 3:\<C-u>call swap#textobj#select('a')\<CR>"
  normal! ""y
  call g:assert.equals(@@, 'foo, bar, baz', 'Failed at #7')

  " #8
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', ']}]
  call setline(1, 'foo, bar, baz')
  call cursor(1, 6)
  execute "normal! 2:\<C-u>call swap#textobj#select('a')\<CR>"
  normal! ""y
  call g:assert.equals(@@, ', bar, baz', 'Failed at #8')

  " #9
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', '], 'immutable': ['\s*"immutable\d\?"\s*']}]
  call setline(1, 'foo, "immutable" bar, baz')
  call cursor(1, 16)
  call swap#textobj#select('a')
  normal! ""y
  call g:assert.equals(@@, ', "immutable" bar', 'Failed at #9')

  " #10
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', '], 'immutable': ['\s*"immutable\d\?"\s*']}]
  call setline(1, 'foo, "immutable1" "immutable2" bar, baz')
  call cursor(1, 32)
  call swap#textobj#select('a')
  normal! ""y
  call g:assert.equals(@@, ', "immutable1" "immutable2" bar', 'Failed at #10')

  " #11
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', '], 'immutable': ['\s*"immutable\d\?"\s*']}]
  call setline(1, 'foo, "immutable1" "immutable2" bar, baz')
  call cursor(1, 18)
  call swap#textobj#select('a')
  normal! ""y
  call g:assert.equals(@@, ', "immutable1" "immutable2" bar', 'Failed at #11')

  " #12
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', ']}]
  call setline(1, ', foo, bar, baz')
  call cursor(1, 1)
  call swap#textobj#select('a')
  normal! ""y
  call g:assert.equals(@@, ', foo', 'Failed at #12')

  " #13
  let g:swap#rules = [{'body': '^.\+$', 'delimiter': [', ']}]
  call setline(1, 'foo, bar, baz, ')
  call cursor(1, 11)
  call swap#textobj#select('a')
  normal! ""y
  call g:assert.equals(@@, ', baz', 'Failed at #13')

  " #14
  let g:swap#rules = [{'surrounds': ['(', ')'], 'delimiter': [', ']}]
  call setline(1, '(((foo), bar), baz)')
  call cursor(1, 4)
  call swap#textobj#select('i')
  normal! ""y
  call g:assert.equals(@@, 'foo', 'Failed at #14')
endfunction "}}}
function! s:suite.integration_textobj_i_exclusive() abort "{{{
  set selection=exclusive
  call self.integration_textobj_i()
endfunction "}}}
function! s:suite.integration_textobj_a_exclusive() abort "{{{
  set selection=exclusive
  call self.integration_textobj_a()
endfunction "}}}


" functions
function! s:suite.swap_region() abort "{{{
  " #1
  call setline(1, '(foo, bar, baz)')
  let start = [0, 1, 2, 0]
  let end = [0, 1, 14, 0]
  let type = 'char'
  call swap#region(start, end, type, [[1, 2]])
  call g:assert.equals(getline('.'), '(bar, foo, baz)', 'failed at #1')

  " #2
  call setline(1, '(foo, bar, baz)')
  call setpos("'a", [0, 1, 2, 0])
  call setpos("'b", [0, 1, 14, 0])
  call swap#region("'a", "'b", 'v', [[1, 2]])
  call g:assert.equals(getline('.'), '(bar, foo, baz)', 'failed at #2')

  " #3
  call setline(1, '(foo, bar; baz)')
  let start = [0, 1, 2, 0]
  let end = [0, 1, 14, 0]
  let type = 'char'
  let g:swap#rules = [{
  \     'description': 'Reorder the selected comma-delimited word in visual mode.',
  \     'mode': 'x',
  \     'delimiter': ['\s*,\s*'],
  \   }]
  let rules = [{
  \     'description': 'Reorder the selected semicolon-delimited word in visual mode.',
  \     'mode': 'x',
  \     'delimiter': ['\s*;\s*'],
  \   }]
  call swap#region(start, end, type, [[1, 2]], rules)
  call g:assert.equals(getline('.'), '(baz; foo, bar)', 'failed at #3')
  unlet! g:swap#rules
endfunction "}}}
function! s:suite.swap_region_interactively() abort "{{{
  " #1
  call setline(1, '(foo, bar, baz)')
  let start = [0, 1, 2, 0]
  let end = [0, 1, 14, 0]
  let type = 'char'
  execute "normal! :\<C-u>call swap#region_interactively(start, end, type)\<CR>12\<Esc>"
  call g:assert.equals(getline('.'), '(bar, foo, baz)', 'failed at #1')

  " #2
  call setline(1, '(foo, bar, baz)')
  call setpos("'a", [0, 1, 2, 0])
  call setpos("'b", [0, 1, 14, 0])
  execute "normal! :\<C-u>call swap#region_interactively(\"'a\", \"'b\", 'v')\<CR>12\<Esc>"
  call g:assert.equals(getline('.'), '(bar, foo, baz)', 'failed at #2')

  " #3
  call setline(1, '(foo, bar; baz)')
  let start = [0, 1, 2, 0]
  let end = [0, 1, 14, 0]
  let type = 'char'
  let g:swap#rules = [{
  \     'description': 'Reorder the selected comma-delimited word in visual mode.',
  \     'mode': 'x',
  \     'delimiter': ['\s*,\s*'],
  \   }]
  let rules = [{
  \     'description': 'Reorder the selected semicolon-delimited word in visual mode.',
  \     'mode': 'x',
  \     'delimiter': ['\s*;\s*'],
  \   }]
  execute "normal! :\<C-u>call swap#region_interactively(start, end, type, rules)\<CR>12\<Esc>"
  call g:assert.equals(getline('.'), '(baz; foo, bar)', 'failed at #3')
  unlet! g:swap#rules
endfunction "}}}
function! s:suite.swap_around_pos() abort "{{{
  " #1
  call setline(1, '(foo, bar, baz)')
  let pos = [0, 1, 2, 0]
  call swap#around_pos(pos, [[1, 2]])
  call g:assert.equals(getline('.'), '(bar, foo, baz)', 'failed at #1')

  " #2
  call setline(1, '(foo, bar, baz)')
  call setpos("'a", [0, 1, 2, 0])
  call swap#around_pos("'a", [[1, 2]])
  call g:assert.equals(getline('.'), '(bar, foo, baz)', 'failed at #2')

  " #3
  call setline(1, '(foo, bar; baz)')
  let pos = [0, 1, 2, 0]
  let g:swap#rules = [{
  \     'description': 'Reorder the selected comma-delimited word in visual mode.',
  \     'mode': 'n',
  \     'surrounds': ['(', ')'],
  \     'delimiter': ['\s*,\s*'],
  \   }]
  let rules = [{
  \     'description': 'Reorder the selected semicolon-delimited word in visual mode.',
  \     'mode': 'n',
  \     'surrounds': ['(', ')'],
  \     'delimiter': ['\s*;\s*'],
  \   }]
  call swap#around_pos(pos, [[1, 2]], rules)
  call g:assert.equals(getline('.'), '(baz; foo, bar)', 'failed at #3')
  unlet! g:swap#rules
endfunction "}}}
function! s:suite.swap_around_pos_interactively() abort "{{{
  " #1
  call setline(1, '(foo, bar, baz)')
  let pos = [0, 1, 2, 0]
  execute "normal! :\<C-u>call swap#around_pos_interactively(pos)\<CR>12\<Esc>"
  call g:assert.equals(getline('.'), '(bar, foo, baz)', 'failed at #1')

  " #2
  call setline(1, '(foo, bar, baz)')
  call setpos("'a", [0, 1, 2, 0])
  execute "normal! :\<C-u>call swap#around_pos_interactively(\"'a\")\<CR>12\<Esc>"
  call g:assert.equals(getline('.'), '(bar, foo, baz)', 'failed at #2')

  " #3
  call setline(1, '(foo, bar; baz)')
  let pos = [0, 1, 2, 0]
  let g:swap#rules = [{
  \     'description': 'Reorder the selected comma-delimited word in visual mode.',
  \     'mode': 'n',
  \     'surrounds': ['(', ')'],
  \     'delimiter': ['\s*,\s*'],
  \   }]
  let rules = [{
  \     'description': 'Reorder the selected semicolon-delimited word in visual mode.',
  \     'mode': 'n',
  \     'surrounds': ['(', ')'],
  \     'delimiter': ['\s*;\s*'],
  \   }]
  execute "normal! :\<C-u>call swap#around_pos_interactively(pos, rules)\<CR>12\<Esc>"
  call g:assert.equals(getline('.'), '(baz; foo, bar)', 'failed at #3')
  unlet! g:swap#rules
endfunction "}}}



" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" vim:set ts=2 sts=2 sw=2:
