" Clock object - Measuring time.

" features
let s:has_reltime_and_float = has('reltime') && has('float')


let s:Clock = {
\   'started' : 0,
\   'paused'  : 0,
\   'losstime': 0,
\   'zerotime': reltime(),
\   'pause_at': reltime(),
\ }


function! s:Clock.start() abort  "{{{
  if self.started
    if self.paused
      let self.losstime += str2float(reltimestr(reltime(self.pause_at)))
      let self.paused = 0
    endif
  else
    if s:has_reltime_and_float
      let self.zerotime = reltime()
      let self.started  = 1
    endif
  endif
endfunction "}}}


function! s:Clock.pause() abort "{{{
  let self.pause_at = reltime()
  let self.paused   = 1
endfunction "}}}


function! s:Clock.elapsed() abort "{{{
  if self.started
    let total = str2float(reltimestr(reltime(self.zerotime)))
    return floor((total - self.losstime)*1000)
  endif
  return 0
endfunction "}}}


function! s:Clock.stop() abort  "{{{
  let self.started  = 0
  let self.paused   = 0
  let self.losstime = 0
endfunction "}}}


let s:Clocks = {}


function! s:Clocks.Clock() abort "{{{
  return deepcopy(s:Clock)
endfunction "}}}


function! swap#clock#import() abort  "{{{
  return s:Clocks
endfunction "}}}


" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" vim:set ts=2 sts=2 sw=2:
