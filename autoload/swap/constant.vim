" Constant object - Hold constants

unlet! s:Const
let s:Const = {}
let s:Const.NULLCOORD = [0, 0]
let s:Const.NULLPOS = [0, 0, 0, 0]
let s:Const.NULLREGION = {
\   'head': copy(s:Const.NULLPOS),
\   'tail': copy(s:Const.NULLPOS),
\   'len': -1,
\   'type': '',
\ }

if exists('v:t_number')
  let s:Const.TYPESTR = v:t_string
  let s:Const.TYPENUM = v:t_number
  let s:Const.TYPELIST = v:t_list
  let s:Const.TYPEDICT = v:t_dict
  let s:Const.TYPEFLOAT = v:t_float
  let s:Const.TYPEFUNC = v:t_func
else
  let s:Const.TYPESTR = type('')
  let s:Const.TYPENUM = type(0)
  let s:Const.TYPELIST = type([])
  let s:Const.TYPEDICT = type({})
  let s:Const.TYPEFLOAT = type(0.0)
  let s:Const.TYPEFUNC = type(function('tr'))
endif
lockvar! s:Const


function! swap#constant#import() abort "{{{
  return s:Const
endfunction "}}}

" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" vim:set ts=2 sts=2 sw=2:
