vim-swap
============
[![Build Status](https://travis-ci.org/machakann/vim-swap.svg?branch=master)](https://travis-ci.org/machakann/vim-swap)
[![Build status](https://ci.appveyor.com/api/projects/status/iirgmyseg2f9xam9/branch/master?svg=true)](https://ci.appveyor.com/project/machakann/vim-swap/branch/master)

A Vim text editor plugin to swap delimited items.

# What for?
Sometimes I want to reorder arguments of a function:

```
call func(arg1, arg2, arg3)
```

Indeed, it is not difficult to swap `arg2` and `arg3`. Just cutting `, arg2` and pasting it following `arg3`. However it is annoying to swap `arg1` and `arg3` because no way to avoid repeating cut&paste. Anyway I feel bothering in both cases. It should be automated such an boring processes!

# How to use
This plugin defines three key mappings in default, **g<**, **g>**, **gs**. These all functions can be repeated by dot command.

## g<
**g<** swaps the item under the cursor with the former item. Moving cursor on the `arg2` and pressing **g<**, then it swaps `arg2` and the former one, `arg1`, to get:

```
call foo(arg2, arg1, arg3)
```

## g>
**g>** swaps the item under the cursor with the latter item. Moving cursor on the `arg2` and pressing **g>**, then it swaps `arg2` and the latter one, `arg3`, to get:
```
call foo(arg1, arg3, arg2)
```

## gs
**gs** works more interactive. It starts "swap mode", as if there was the sub-mode of vim editor. In the mode, use **h**/**l** to swap items, **j**/**k** to choose item, numbers **1** ~ **9** to select **n**th item, **u**/**\<C-r\>** to undo/redo, **g**/**G** to [group/ungroup items](https://imgur.com/kPJui7J.gif), **s**/**S** to [sort](https://imgur.com/TuzzV7d.gif), **r** to [reverse](https://imgur.com/WXOOPCW.gif), and as you know **\<Esc\>** to exit "swap mode". **gs** function can be used also in visual mode.  In linewise-visual and blockwise-visual mode, this plugin always swaps in each line. For example, assume that the three lines were in a buffer:


```
foo
bar
baz
```

Select the three lines and press **gsl\<Esc\>**, then swaps the first line and the second line.

```
bar
foo
baz
```


# textobject

The following lines enables to use textobjects to select "swappable" items.

```vim
omap i, <Plug>(swap-textobject-i)
xmap i, <Plug>(swap-textobject-i)
omap a, <Plug>(swap-textobject-a)
xmap a, <Plug>(swap-textobject-a)
```

Those textobjects work well with `[count]` assignment.


# Demo
![swap.vim](http://art9.photozou.jp/pub/986/3080986/photo/232868997_org.v1453815504.gif)
