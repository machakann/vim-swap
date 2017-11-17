" constant object - Hold constants

function! swap#constant#import(...) abort "{{{
  if a:0 >= 1
    let const = s:const
    if a:0 >= 2
      let const = filter(deepcopy(s:const), 'count(a:2, v:key) > 0')
      lockvar! const
    endif
    call extend(a:1, const)
  endif
  return s:const
endfunction "}}}

unlet! s:const
let s:const = {}
let s:const.NULLCOORD = [0, 0]
let s:const.NULLPOS = [0, 0, 0, 0]
let s:const.NULLREGION = {'head': copy(s:const.NULLPOS), 'tail': copy(s:const.NULLPOS), 'len': -1, 'type': '', 'visualkey': ''}

if exists('v:t_number')
  let s:const.TYPESTR = v:t_string
  let s:const.TYPENUM = v:t_number
  let s:const.TYPELIST = v:t_list
  let s:const.TYPEDICT = v:t_dict
  let s:const.TYPEFLOAT = v:t_float
  let s:const.TYPEFUNC = v:t_func
else
  let s:const.TYPESTR = type('')
  let s:const.TYPENUM = type(0)
  let s:const.TYPELIST = type([])
  let s:const.TYPEDICT = type({})
  let s:const.TYPEFLOAT = type(0.0)
  let s:const.TYPEFUNC = type(function('tr'))
endif
lockvar! s:const

" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" vim:set ts=2 sts=2 sw=2:
