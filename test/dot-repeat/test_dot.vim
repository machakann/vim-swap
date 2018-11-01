if has('win16') || has('win32') || has('win64') || has('win95')
  set shellslash
endif
execute 'set runtimepath+=' . expand('<sfile>:p:h:h:h')
source <sfile>:p:h:h:h/plugin/swap.vim

function! s:assert(a1, a2, kind) abort
  if type(a:a1) == type(a:a2) && string(a:a1) is# string(a:a2)
    return
  endif

  %delete
  call append(0, ['Got:', string(a:a1)])
  call append(0, [printf('Failured at "%s"', a:kind), '', 'Expect:', string(a:a2)])
  $delete
  execute printf('1,%dprint', line('$'))
  cquit
endfunction



" test
call setline(1, '(foo, bar, baz)')
execute "normal gglgsll\<Esc>"
normal .
call s:assert(getline('.'), '(baz, foo, bar)', 'swap-interacive #1')

call setline(1, '(foo, bar, baz)')
execute "normal gglgsll\<Esc>"
normal gg6l.
call s:assert(getline('.'), '(baz, foo, bar)', 'swap-interacive #2')

call setline(1, '(foo, bar, baz)')
execute "normal gglg>"
normal .
call s:assert(getline('.'), '(bar, baz, foo)', 'swap-next #1')

call setline(1, '(foo, bar, baz)')
execute "normal gg6lg>"
normal ggl.
call s:assert(getline('.'), '(baz, foo, bar)', 'swap-next #2')

call setline(1, '(foo, bar, baz)')
execute "normal gg6lg<"
normal .
call s:assert(getline('.'), '(bar, foo, baz)', 'swap-prev #1')

call setline(1, '(foo, bar, baz)')
execute "normal gg6lg<"
normal gg11l.
call s:assert(getline('.'), '(bar, baz, foo)', 'swap-prev #2')

qall!
