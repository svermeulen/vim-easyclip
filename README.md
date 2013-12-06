vim-easyclip
=============
### Simplified clipboard functionality for Vim.###

Author:  [Steve Vermeulen] (https://github.com/svermeulen), based on work by [Max Brunsfeld] (http://www.github.com/maxbrunsfeld)

[EasyClip](https://github.com/svermeulen/vim-easyclip) is a plugin for Vim which contains a collection of clipboard related functionality with the goal of making using Vim simpler and more intuitive without losing any of its power.

### Installation ###

I recommend loading your plugins with [neobundle](https://github.com/Shougo/neobundle.vim) or [vundle](https://github.com/gmarik/vundle) or [pathogen](https://github.com/tpope/vim-pathogen)

This plugin also requires that you have Tim Pope's [repeat.vim](https://github.com/tpope/vim-repeat) plugin installed.

### Black Hole Redirection ###

By default, Vim's built-in delete operator will yank the deleted text in addition to just deleting it.  This works great when you want to cut text and paste it somewhere else, but in many other cases it can make things more difficult.  For example, if you want to make some tiny edit to fix formatting after cutting some text, you either have to have had the foresight to use a named register, or specify the black hole register explicitly to do your formatting.  This plugin solves that problem by redirecting all change and delete operations to the black hole register and introducing a new operator, 'cut' (by default this is mapped to the `m` key).

There is simply no need to clutter up the yank history with every single edit, when you almost always know at the time you are deleting text whether it's something that is worth keeping around or not.

### Substitution Operator ###

Because replacing text is such a common operation, EasyClip includes a motion for it.  It is essentially equivalent to doing a change operation then pasting using the specified register.  For example, assuming you have mapped this motion to the `s` key, to paste over the word under the cursor you would type `siw`, or to paste inside brackets, `si(`, etc.

It can also take a register to use for the substitution (eg. `"asip`), and is fully repeatable using the `.` key.

**NOTE** This feature is off by default.  To use, you have to either enable the option `g:EasyClipUseSubstituteDefaults` (in which case it will be mapped to the `s` key) or map the key/keys of your choice to the `<plug>` mappings found in substitute.vim.

### Yank Buffer ###

Easyclip allows you to yank and cut things without worrying about losing text that you copied previously.  It achieves this by storing all yanks into a buffer, which you can cycle through forward or backwards to choose the yank that you want

This works very similar to the way [YankRing](https://github.com/vim-scripts/YankRing.vim) and [YankStack](https://github.com/maxbrunsfeld/vim-yankstack) work, in that you can use a key binding to toggle between different yanks immediately after triggering a paste or substitute.  (Most of the functionality is actually taken and adapted from Yankstack, with changes to make it work with substitute)

By default, the keys to toggle the paste are mapped to `<c-n>` and `<c-p>` (similar to yankring).  For example, executing `p<c-p>` will paste, then toggle it to the most recent yank before that.  You can continue toggling forwards/backwards in the yank history to replace the most recent paste as much as you want.  Note that the toggle action will of course not be included in the undo history.  That is, pressing undo after any number of swaps will undo the paste and not each swap.

This method of toggling the chosen yank after paste will probably be your primary method of digging back into the yank buffer.  Note that in this case the yank buffer is unchanged.  What this means for example is that you can toggle a given paste back using `<c-p>` 10 times, then if you perform a new paste in a different location it will still use the most recent yank (and not the final yank you arrived at after 10 swaps).

Alternatively, you can execute (by default) keys `[y` or `]y` to navigate the yank buffer 'head' forwards or backwards.  In this case the change will be permanent.  That is, pressing `[y[yp` will paste the third most recent yank.  Subsequent pastes will use the same yank, until you go forwards again using `]y`.

You can view the full list of yanks at any time by running the command `:Yanks`

Note that you can swap substitution operations in the same way as paste.

Another difference worth noting is that the cursor position does not change when a yank occurs.

### Paste ###

By default EasyClip preserves the default vim paste behaviour, which is the following:

*  `p` (lowercase) pastes text after the current line if the pasted text is multiline (or after the current character if non-multiline)
*  `P` (uppercase) behaves the same except acts before the current line (or before the current character if non-multiline)

When the text is multi-line, the cursor is placed at the start of the new text.  When the paste is non-multiline, the cursor is placed at the end.

Alternatively, you can enable the option `g:EasyClipAlwaysMoveCursorToEndOfPaste` to have the cursor positioned at the end in both cases (off by default).  Note that when this option is enabled, the beginning of the multi-line text is added to the jumplist, so you can still return to the start of the paste by pressing `<c-o>` (and this applies to multi-line substitutions as well)

Another non-standard option is `g:EasyClipAutoFormat` (off by default), which will, as the name implies, automatically format text immediately after it is pasted.  This can be useful when pasting text from one indent level to another.

Easy Clip also includes a mapping for insert mode paste, which automatically turns on 'paste' mode for the duration of the paste.  Using 'paste' mode will work much more intuitively when pasting text with multiple lines while in insert mode.  You can enable this by including something similar to the following in your .vimrc:

    imap <c-v> <plug>EasyClipInsertModePaste

### System Clipboard Sync ###

EasyClip will also automatically sync with your system clipboard.

Every time you leave and return to vim, easy clip will check whether you copied anything from outside Vim and add it to the yank history.

### Options ###

EasyClip can be easily customized to whatever mapping you wish, using the following options:

`g:EasyClipAutoFormat` - Default: 0.  Set this to 1 to enable auto-formatting pasting text

`g:EasyClipYankHistorySize` - Default: 50. Change this to limit yank history

`g:EasyClipDoSystemSync` - Default: 1. Set this to zero to disable system clipboard sync.

`g:EasyClipRemapCapitals` - Default: 1. Set this to 0 to disable mappings for `C`, `D`, and `Y` 

You can also disable the default mappings by setting one or more of the following to zero.  By default they are set to 1 (ie. enabled)

    `g:EasyClipUseYankDefaults`

    `g:EasyClipUseCutDefaults`

    `g:EasyClipUsePasteDefaults`

    `g:EasyClipEnableBlackHoleRedirect`

    `g:EasyClipUsePasteToggleDefaults`

One exception to the above is substitute, which is 0 by default (ie. disabled)

    `g:EasyClipUseSubstituteDefaults`

You can then map to the specific `<plug>` mappings to define whatever mappings you want.  For example, to change the mapping for cut (by default set to `m`) to `x`, include the following in your vimrc:`

    let g:EasyClipUseCutDefaults = 0

    nmap x <Plug>MoveMotionPlug
    xmap x <Plug>MoveMotionXPlug
    nmap xx <Plug>MoveMotionLinePlug

Or to change the bindings for toggling paste from `<c-n>` and `<c-p>` to `<c-d>` and `<c-f>` include the following:

    let g:EasyClipUsePasteToggleDefaults = 0

    nmap <c-f> <plug>EasyClipSwapPasteForward
    nmap <c-d> <plug>EasyClipSwapPasteBackwards

Or to use `gs` for substitute include the following:

    nmap <silent> gs <plug>SubstituteOverMotionMap
    nmap gss <plug>SubstituteLine
    xmap gs p

For reference, or other kinds of mappings, see the bottom of the file with the name of the operation you wish to remap (vim-easy-clip/autoload/substitute.vim / move.vim / yank.vim /etc.)

### Default Key Mappings ###

`d<motion>` - Delete over the given motion and *do not* change clipboard

`dd` - Delete the line and *do not* change clipboard

`D` - Delete from cursor to the end of the line and *do not* change clipboard

`dD` - Delete the contents of line except the newline character (that is, make it blank) and *do not* change clipboard

`x` - Delete the character under cursor and *do not* change clipboard

`c<motion>` - Enter insert mode over top the given area and *do not* change clipboard

`cc` - Enter insert mode over top the current line and *do not* change clipboard

`C` - Enter insert mode from cursor to the end of the line and *do not* change clipboard

`s<motion>` - Substitute over the given motion with specified register (or default register if unspecified).  Note that this only applies if the `g:EasyClipUseSubstituteDefaults` option is set.

`ss` - Substitute over the current line with specified register (or default register if unspecified). Note that this only applies if the `g:EasyClipUseSubstituteDefaults` option is set.

`gs` - Same as s but preserves the current cursor position. Note that this only applies if the `g:EasyClipUseSubstituteDefaults` option is set.

`p` - Paste from specified register. Inserts after current line if text is multiline, after current character if text is non-multiline.  Leaves cursor at end of pasted text.

`P` - Same as p except inserts text before current line/character

`<leader>p` - Same as `p` except does not auto-format text

`<leader>P` - Same as `P` except does not auto-format text

`gp` - Same as p but preserves the current cursor position

`gP` - Same as P but preserves the current cursor position

`g<leader>P` - Same as `<leader>P` but preserves the current cursor position

`g<leader>p` - Same as `<leader>p` but preserves the current cursor position

`m<motion>` - Delete over the given motion and copy text to clipboard

`mm` - Delete the current line and copy text to clipboard

`<c-p>` - Rotate the previous paste forward in yank buffer.  Note that this binding will only work if executed immediately after a paste

`<c-n>` - Rotate the previous paste backward in yank buffer.  Note that this binding will only work if executed immediately after a paste

`[y` - Go backward in the yank buffer.  This can be executed at any time to modify order of yanks in the yank buffer (though I would recommend just using `<c-p>` instead)

`]y` - Go forward in the yank buffer. This can be executed at any time to modify order of yanks in the yank buffer (though I would recommend just using `<c-n>` instead)

`Y` - Copy text from cursor position to the end of line to the clipboard

### Custom Yanks ###

If you have custom yanks that occur in your vimrc or elsewhere and would like them to be included in the yank history, you can either call easyclip#Yank() to record the string or call the command `EasyClipBeforeYank` before the yank occurs.  For example, to yank the current file name you could do either of the following:

`nnoremap <leader>yfn :EasyClipBeforeYank<cr>:let @*=expand('%')<cr>`

`nnoremap <leader>yfn :call easyclip#Yank(expand('%'))<cr>`

### Todo ###

- `:Yanks` command should maybe open up the list of yanks in a scratch buffer so that it is searchable

### Changelog ###

2.0 (2013-09-22)
    - Many bug fixes
    - Yankring/Yankstack style post-paste swap
    - RSPEC unit tests added for stability

1.2 (2013-09-22)
  - More bug fixes

1.1 (2013-09-03)
  - Bunch of bug fixes

1.0 (2013-07-08)
  - Initial release

### License ###

Distributed under the same terms as Vim itself.  See the vim license.


[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/svermeulen/vim-easyclip/trend.png)](https://bitdeli.com/free "Bitdeli Badge")


