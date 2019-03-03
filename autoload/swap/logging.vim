" Logging Module
" USAGE: Make a logger for each script. This should be done outside of functions.
"           let s:Logging = swap#logging#import()
"           let s:logger = s:Logging.Logger(expand('<sfile>'))
"        Call logger.debug() to store a log message. This is done in a function.
"           call s:logger.debug('A log message')

" USAGE: Output log via the Logging module
"           let g:Log = swap#logging#import()
"
"           call g:Log.echo()
"               or
"           call g:Log.echomsg()
"               or
"           call g:Log.writefile('path/to/logfile')

let s:Const = swap#constant#import()

let s:TRUE = 1
let s:FALSE = 0
let s:ROOT = expand('<sfile>:h:h:h:p')
let s:TYPESTR = s:Const.TYPESTR
let s:TYPENUM = s:Const.TYPENUM

" Log level
let s:ERROR    = {'kind': 'ERROR',    'level': 40, 'hl': 'ErrorMsg'}
let s:WARNING  = {'kind': 'WARNING',  'level': 30, 'hl': 'WarningMsg'}
let s:INFO     = {'kind': 'INFO',     'level': 20, 'hl': 'NONE'}
let s:DEBUG    = {'kind': 'DEBUG',    'level': 10, 'hl': 'NONE'}

" Logger object {{{
let s:Logger = {
\   'file': '',
\ }

function! s:Logger(file, ...) abort "{{{
  let option = get(a:000, 0, {})
  let logger = deepcopy(s:Logger)
  let logger.file = a:file[strlen(s:ROOT) + 1 :]
  return logger
endfunction "}}}


function! s:Logger.log(identifier, text, ...) dict abort "{{{
  if a:identifier.level < s:Logging.level || s:Logging.n < 1
    return
  endif

  let time = strftime('%Y-%m-%d %H:%M:%S %Z')
  if a:0 > 0
    let text = call('printf', [a:text] + map(copy(a:000), 's:string(v:val)'))
  else
    let text = s:string(a:text)
  endif
  let stacktrace = split(expand('<sfile>'), '\.\.')[: -2]
  let entry = {
  \   'time': time,
  \   'kind': a:identifier.kind,
  \   'level': a:identifier.level,
  \   'hl': a:identifier.hl,
  \   'file': self.file,
  \   'text': text,
  \   'stacktrace': stacktrace,
  \ }
  call s:Logging._add(entry)
endfunction "}}}


" Store a log message
"   call s:logger.info('A log message')
" If more than two arguments are assigned, this function works like printf()
"   call s:logger.info('Line %d', line('.'))
" It will be converted to a string expression other than a string or a number
function! s:Logger.error(text, ...) abort "{{{
  call call(self.log, [s:ERROR, a:text] + a:000, self)
endfunction "}}}


function! s:Logger.warning(text, ...) abort "{{{
  call call(self.log, [s:WARNING, a:text] + a:000, self)
endfunction "}}}


function! s:Logger.info(text, ...) abort "{{{
  call call(self.log, [s:INFO, a:text] + a:000, self)
endfunction "}}}


function! s:Logger.debug(text, ...) abort "{{{
  call call(self.log, [s:DEBUG, a:text] + a:000, self)
endfunction "}}}


function! s:string(expr) abort "{{{
  let type_expr = type(a:expr)
  if type_expr is# s:TYPESTR || type_expr is# s:TYPENUM
    return a:expr
  endif
  if exists('*PrettyPrint')
    return PrettyPrint(a:expr)
  endif
  return string(a:expr)
endfunction "}}}
"}}}


" Logging Module {{{
let s:Logging = {
\   'n': 100,
\   'log': [],
\   'loggers': {},
\   'Logger': function('s:Logger'),
\   'level': s:WARNING.level,
\   'ERROR': s:ERROR,
\   'WARNING': s:WARNING,
\   'INFO': s:INFO,
\   'DEBUG': s:DEBUG,
\   'outputfile': '',
\   'option': {},
\ }


function! s:Logging.Logger(file) abort "{{{
  if !has_key(self.loggers, a:file)
    let self.loggers[a:file] = s:Logger(a:file)
  endif
  return self.loggers[a:file]
endfunction "}}}


function! s:Logging._add(entry) abort "{{{
  if len(self.log) >= self.n
    call filter(self.log, 'v:key < self.n - 1')
  endif
  call add(self.log, a:entry)
  call self._writefile(a:entry)
endfunction "}}}


function! s:Logging._writefile(entry) abort "{{{
  if self.outputfile is# ''
    return
  endif
  let option = self.option
  let pathshorten = get(option, 'pathshorten', s:TRUE)
  let stacktrace = get(option, 'stacktrace', s:FALSE)
  let lines = s:buildlines(a:entry, pathshorten, stacktrace)
  call writefile(lines, self.outputfile, 'a')
endfunction "}}}


function! s:Logging.clear() abort "{{{
  call filter(self.log, 0)
endfunction "}}}


function! s:Logging.setlevel(log) abort "{{{
  let self.level = a:log.level
endfunction "}}}


function! s:Logging.setfile(filename) abort "{{{
  let self.outputfile = fnamemodify(a:filename, ':p')
endfunction "}}}


function! s:Logging.setoptions(option) abort "{{{
  let self.option = a:option
endfunction "}}}


function! s:Logging.getlog(...) abort "{{{
  let option = get(a:000, 0, self.option)
  let log = deepcopy(self.log)
  if has_key(option, 'filter')
    let log = filter(deepcopy(log), option.filter)
  endif
  return log
endfunction "}}}


function! s:Logging.getlines(...) abort "{{{
  let option = get(a:000, 0, self.option)
  let pathshorten = get(option, 'pathshorten', s:TRUE)
  let stacktrace = get(option, 'stacktrace', s:FALSE)
  let log = self.getlog(option)
  let lines = map(log, 's:buildlines(v:val, pathshorten, stacktrace)')
  call s:flatten(lines)
  return lines
endfunction "}}}


function! s:Logging.string(...) abort "{{{
  let option = get(a:000, 0, self.option)
  let lines = self.getlines(option)
  return join(lines, "\n")
endfunction "}}}


function! s:Logging.echo(...) abort "{{{
  let option = get(a:000, 0, self.option)
  let pathshorten = get(option, 'pathshorten', s:TRUE)
  let stacktrace = get(option, 'stacktrace', s:FALSE)
  let log = self.getlog(option)
  call map(log, 's:buildmessage(v:val, pathshorten, stacktrace)')
  call s:flatten(log)
  for [msg, higroup] in log
    execute 'echohl' higroup
    echon msg
  endfor
  echohl NONE
endfunction "}}}


function! s:Logging.echomsg(...) abort "{{{
  let option = get(a:000, 0, self.option)
  let pathshorten = get(option, 'pathshorten', s:TRUE)
  let stacktrace = get(option, 'stacktrace', s:FALSE)
  let log = self.getlog(option)
  call map(log, 's:buildlines(v:val, pathshorten, stacktrace)')
  call s:flatten(log)
  for line in log
    echomsg line
  endfor
endfunction "}}}


function! s:Logging.writefile(fname, ...) abort "{{{
  let option = get(a:000, 0, self.option)
  let pathshorten = get(option, 'pathshorten', s:TRUE)
  let stacktrace = get(option, 'stacktrace', s:FALSE)
  let flags = get(option, 'flags', '')
  let log = self.getlog(option)
  let lines = map(log, 's:buildlines(v:val, pathshorten, stacktrace)')
  call s:flatten(lines)
  return writefile(lines, a:fname, flags)
endfunction "}}}


function! s:buildlines(entry, pathshorten, stacktrace) abort "{{{
  let file = a:pathshorten ? pathshorten(a:entry.file) : a:entry.file
  let time = a:entry.time
  let kind = a:entry.kind
  let text = split(a:entry.text, "\n")
  let msg = [printf('%s %s:%s: %s', time, file, kind, text[0])]
  let msg += text[1:]
  if a:stacktrace
    let stacktracestr = join(a:entry.stacktrace, '..')
    let msg .= ':' . matchstr(stacktracestr, '^\s*function\s\+\zs.*')
  endif
  return msg
endfunction "}}}


function! s:buildmessage(entry, pathshorten, stacktrace) abort "{{{
  let file = a:pathshorten ? pathshorten(a:entry.file) : a:entry.file
  let msg = [
  \   [a:entry.time, 'Title'],
  \   [' ', 'Special'],
  \   [file, 'Directory'],
  \   [':', 'Special'],
  \   [a:entry.kind, a:entry.hl],
  \   [':', 'Special'],
  \   [a:entry.text, 'NONE'],
  \ ]
  if a:stacktrace
    let stacktracestr = join(a:entry.stacktrace, '..')
    let msg += [
    \   [':', 'Special'],
    \   [matchstr(stacktracestr, '^\s*function\s\+\zs.*'), 'NONE'],
    \ ]
  endif
  let msg += [["\n", 'NONE']]
  return msg
endfunction "}}}


function! s:flatten(list) abort "{{{
  let saved = copy(a:list)
  call filter(a:list, 0)
  for item in saved
    call extend(a:list, item)
  endfor
  return a:list
endfunction "}}}
"}}}


function! swap#logging#import() abort "{{{
  return s:Logging
endfunction "}}}

" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" vim:set ts=2 sts=2 sw=2:
