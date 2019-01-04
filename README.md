vim-easyclip
=============

### NOTE

This plugin is considered more or less "done".  Minor bug fixes will be applied but otherwise it will just remain stable.  For modern versions of vim (Vim 8+ or Neovim) it has been split up into three different plugins instead:  [vim-cutlass](https://github.com/svermeulen/vim-cutlass), [vim-yoink](https://github.com/svermeulen/vim-yoink), and [vim-subversive](https://github.com/svermeulen/vim-subversive)

### Simplified clipboard functionality for Vim.

Author:  [Steve Vermeulen](https://github.com/svermeulen), based on work by [Max Brunsfeld](http://www.github.com/maxbrunsfeld)

EasyClip is a plugin for Vim which contains a collection of clipboard related
functionality with the goal of making using the clipboard in Vim simpler and more intuitive
without losing any of its power.

A good starting point for the motivation behind this Vim plugin can be found in Drew Neil's post [Registers: The Good, the Bad, and the Ugly Parts](http://vimcasts.org/blog/2013/11/registers-the-good-the-bad-and-the-ugly-parts/)

## Table Of Contents

* <a href="#installation">Installation</a>
* <a href="#black-hole-redirection">Black Hole Redirection</a>
* <a href="#substitution-operator">Substitution Operator</a>
* <a href="#yank-buffer">Yank Buffer</a>
* <a href="#paste">Paste</a>
* <a href="#persistent-yank-history-and-sharing-clipboard-between-concurrent-vim-instances">Persistent yank history and sharing clipboard between concurrent Vim instances</a>
* <a href="#clipboard-setting">Clipboard setting</a>
* <a href="#options">Options</a>
* <a href="#default-key-mappings">Default Key Mappings</a>
* <a href="#custom-yanks">Custom Yanks</a>
* <a href="#feedback">Feedback</a>
* <a href="#changelog">Changelog</a>
* <a href="#license">License</a>

### Installation ###

I recommend loading your plugins with [neobundle](https://github.com/Shougo/neobundle.vim) or [vundle](https://github.com/gmarik/vundle) or [pathogen](https://github.com/tpope/vim-pathogen)

This plugin also requires that you have Tim Pope's [repeat.vim](https://github.com/tpope/vim-repeat) plugin installed

### Black Hole Redirection ###

By default, Vim's built-in delete operator will yank the deleted text in addition to just deleting it.  This works great when you want to cut text and paste it somewhere else, but in many other cases it can make things more difficult.  For example, if you want to make some tiny edit to fix formatting after cutting some text, you either have to have had the foresight to use a named register, or specify the black hole register explicitly to do your formatting.  This plugin solves that problem by redirecting all change and delete operations to the black hole register and introducing a new operator, 'cut' (by default this is mapped to the `m` key for 'move').

There is simply no need to clutter up the yank history with every single edit, when you almost always know at the time you are deleting text whether it's something that is worth keeping around or not.

**NOTE** As a result of the above, by default easyclip will shadow an important vim function: The Add Mark key (`m`).  Therefore either you will want to use a different key for the 'cut' operator (see options section below for this) or remap something else to 'add mark'.  For example, to use `gm` for 'add mark' instead of `m`, include the following in your vimrc:

    nnoremap gm m

### Substitution Operator ###

Because replacing text is such a common operation, EasyClip includes a motion for it.  It is essentially equivalent to doing a change operation then pasting using the specified register.  For example, assuming you have mapped this motion to the `s` key, to paste over the word under the cursor you would type `siw`, or to paste inside brackets, `si(`, etc.

It can also take a register to use for the substitution (eg. `"asip`), and is fully repeatable using the `.` key.

**NOTE** This feature is off by default.  To use, you have to either enable the option `g:EasyClipUseSubstituteDefaults` (in which case it will be mapped to the `s` key) or map the key/keys of your choice to the `<plug>` mappings found in substitute.vim.

### Yank Buffer ###

EasyClip allows you to yank and cut things without worrying about losing text that you copied previously.  It achieves this by storing all yanks into a buffer, which you can cycle through forward or backwards to choose the yank that you want

This works very similar to the way [YankRing](https://github.com/vim-scripts/YankRing.vim) and [YankStack](https://github.com/maxbrunsfeld/vim-yankstack) work, in that you can use a key binding to toggle between different yanks immediately after triggering a paste or substitute.  (Most of the functionality is actually taken and adapted from Yankstack, with changes to make it work with substitute)

By default, the keys to toggle the paste are mapped to `<CTRL-N>` and `<CTRL-P>` (similar to yankring).  For example, executing `p<CTRL-P>` will paste, then toggle it to the most recent yank before that.  You can continue toggling forwards/backwards in the yank history to replace the most recent paste as much as you want.  Note that the toggle action will of course not be included in the undo history.  That is, pressing undo after any number of swaps will undo the paste and not each swap.

This method of toggling the chosen yank after paste will probably be your primary method of digging back into the yank buffer.  Note that in this case the yank buffer is unchanged.  What this means for example is that you can toggle a given paste back using `<CTRL-P>` 10 times, then if you perform a new paste in a different location it will still use the most recent yank (and not the final yank you arrived at after 10 swaps).

Alternatively, you can execute keys `[y` or `]y` to navigate the yank buffer 'head' forwards or backwards.  In this case the change will be permanent.  That is, pressing `[y[yp` will paste the third most recent yank. Subsequent pastes will use the same yank, until you go forwards again using `]y`.

NOTE: The [y and ]y mappings are not on by default (map them manually).

You can view the full list of yanks at any time by running the command `:Yanks`

Note that you can swap substitution operations in the same way as paste.

Every time the yank buffer changes, it also populates all the numbered registers.  `"1` is therefore the previous yank, `"2` is the yank before that, etc.  This is similar to how the numbered registers work by default (but a bit more sane).  (Credit to Drew Neil for the suggestion)

Also, see `g:EasyClipPreserveCursorPositionAfterYank` option below for an optional non standard customization to yank

### Paste ###

By default EasyClip preserves the default vim paste behaviour, which is the following:

*  `p` (lowercase) pastes text after the current line if the pasted text is multiline (or after the current character if non-multiline)
*  `P` (uppercase) behaves the same except acts before the current line (or before the current character if non-multiline)

When the text is multi-line, the cursor is placed at the start of the new text.  When the paste is non-multiline, the cursor is placed at the end.

Alternatively, you can enable the option `g:EasyClipAlwaysMoveCursorToEndOfPaste` to have the cursor positioned at the end in both cases (off by default).  Note that when this option is enabled, the beginning of the multi-line text is added to the jumplist, so you can still return to the start of the paste by pressing `<CTRL-O>` (and this applies to multi-line substitutions as well)

Another non-standard option is `g:EasyClipAutoFormat` (off by default), which will automatically format text immediately after it is pasted.  This can be useful when pasting text from one indent level to another.

When auto-format is enabled, you can also map a key to toggle between the formatted paste and unformatted paste.  For example, you might include something like the following in your .vimrc:

    nmap <leader>cf <plug>EasyClipToggleFormattedPaste

Then anytime you want to view the original formatting you can type `<leader>cf` directly after paste.  You can also continuing hitting `<leader>cf` again to toggle between format/unformatted.  I find that in most cases I want to always auto-format, and for every other case I can cancel the auto-format immediately afterwards using this plug mapping.

Easy Clip also includes a mapping for insert mode paste, which automatically turns on 'paste' mode for the duration of the paste.  Using 'paste' mode will work much more intuitively when pasting text with multiple lines while in insert mode.  You can enable this by including something similar to the following in your .vimrc:

    imap <c-v> <plug>EasyClipInsertModePaste

Note:  If you have a custom mapping for `pastetoggle`, this may cause conflicts.   To preserve the functionality of your existing custom map, you may want to enable the option `g:EasyClipUseGlobalPasteToggle`.  See the comment at the top of `Paste.vim` for a more detailed explanation.

For convenience, there is also a plug for command mode paste, which you can enable with the following

    cmap <c-v> <plug>EasyClipCommandModePaste

There is also the `:IPaste` command (aka interactive paste) which allows you to enter the yank index buffer you want to paste from.  This can be useful if you are looking for an old yank and don't want to cycle back many times to find it.  In these cases, execute `:IPaste`, then the entire yank buffer will be printed, then enter the index of the row in the printed table you want to paste from.

### Persistent yank history and sharing clipboard between concurrent Vim instances ###

EasyClip can automatically store the yank history to file, so that it can be restored the next time you start Vim.  Storing it to file also allows other active Vim instances to seamlessly share the same clipboard and yank history.

You can enable this feature by enabling the option `g:EasyClipShareYanks` (NOTE: off by default).  You can also customize where the yank history file gets stored (see options section below)

Note that this feature can be [slow](https://github.com/svermeulen/vim-easyclip/issues/87) in some cases and this is why it is off by default.

### Clipboard setting ###

Vim's built-in setting for `clipboard` can be set to one of the following:

1. set clipboard=
1. set clipboard=unnamed
1. set clipboard=unnamedplus
1. set clipboard=unnamed,unnamedplus

Leaving it as (1) which is Vim's default, will cause all yank/delete/paste operations to use the `"` register.  The only drawback here is that whenever you want to copy/paste something from another application, you have to explicitly access the system clipboard, which is represented by the `*` register.  For example, to copy the current line to the system clipboard, you would type `"*yy`.  And to paste some text copied from another window, you would type `"*p`

To avoid this extra work, you can use option (2) and set it to `unnamed`.  This will cause all yank/delete/paste operations to use the system register `*`.  This way, you can copy something in Vim then immediately paste it into another application.  And vice versa when returning to vim.

I recommend using one of these two options.  I personally use option (2).

When option (3) is enabled, both Vim and EasyClip will use the `+` register as its default.

Option (4) is the same as option (3), except Vim will also automatically copy the contents of the `+` register to the `*` register.

### Options ###

EasyClip can be easily customized to whatever mappings you wish, using the following options:

`g:EasyClipAutoFormat` - Default: 0.  Set this to 1 to enable auto-formatting pasting text

`g:EasyClipYankHistorySize` - Default: 50. Change this to limit yank history

`g:EasyClipCopyExplicitRegisterToDefault` - Default: 0.  When set to 0, easy-clip will not change the default register clipboard when an explicit register is given.  For example, when set to 0, if you type `"ayip` it will copy the current paragraph to the `a` register, but it will not affect the default register, so typing `p` will work the same as it did before the above command.  When set to 1, typing `"ayip` will copy the paragraph to both.

`g:EasyClipAlwaysMoveCursorToEndOfPaste` - Default: 0.  Set this to 1 to always position cursor at the end of the pasted text for both multi-line and non-multiline pastes.

`g:EasyClipPreserveCursorPositionAfterYank` - Default 0 (ie. disabled).  Vim's default behaviour is to position the cursor at the beginning of the yanked text, which is consistent with other motions.  However if you prefer the cursor position to remain unchanged when performing yanks, enable this option.

`g:EasyClipShareYanks` - Default: 0 (ie. disabled). When enabled, yank history is saved to file, which allows other concurrent Vim instances to automatically share the yank history, and also allows yank history to be automatically restored when restarting vim.

`g:EasyClipShareYanksFile` - Default: '.easyclip'. The name of the file to save the yank history to when `g:EasyClipShareYanks` is enabled.

`g:EasyClipShareYanksDirectory` - Default: '$HOME'. The directory to use to store the file with name given by `g:EasyClipShareYanksFile` setting.  Only applicable when `g:EasyClipShareYanks` option is enabled.

`g:EasyClipShowYanksWidth` - Default: 80 - The width to display for each line when the `Yanks` command is executed

You can also disable the default mappings by setting one or more of the following to zero.  By default they are set to 1 (ie. enabled)

    `g:EasyClipUseYankDefaults`

    `g:EasyClipUseCutDefaults`

    `g:EasyClipUsePasteDefaults`

    `g:EasyClipEnableBlackHoleRedirect`

    `g:EasyClipUsePasteToggleDefaults`

One exception to the above is substitute, which is 0 by default (ie. disabled)

    `g:EasyClipUseSubstituteDefaults`

To change from the default mappings, you can disable one of the options above and then map to the specific `<plug>` mappings of your choice.  For example, to change the mapping for cut (by default set to `m`) to `x`, include the following in your vimrc:`

    let g:EasyClipUseCutDefaults = 0

    nmap x <Plug>MoveMotionPlug
    xmap x <Plug>MoveMotionXPlug
    nmap xx <Plug>MoveMotionLinePlug

Or to change the bindings for toggling paste from `<CTRL-N>` and `<CTRL-P>` to `<CTRL-D>` and `<CTRL-F>` include the following:

    let g:EasyClipUsePasteToggleDefaults = 0

    nmap <c-f> <plug>EasyClipSwapPasteForward
    nmap <c-d> <plug>EasyClipSwapPasteBackwards

Or to use `gs` for substitute include the following:  (in this case you don't need to turn off the default since the default is already disabled)

    nmap <silent> gs <plug>SubstituteOverMotionMap
    nmap gss <plug>SubstituteLine
    xmap gs <plug>XEasyClipPaste

For reference, or other kinds of mappings, see the Plugs section of the file with the name of the operation you wish to remap (vim-easy-clip/autoload/substitute.vim / move.vim / yank.vim /etc.)

Note that EasyClip will only enable a default mapping if it hasn't already been mapped to something in your .vimrc.

### Default Key Mappings ###

`d<motion>` - Delete over the given motion and *do not* change clipboard

`dd` - Delete the line and *do not* change clipboard

`D` - Delete from cursor to the end of the line and *do not* change clipboard

`dD` - Delete the contents of line except the newline character (that is, make it blank) and *do not* change clipboard

`x` - Delete the character under cursor and *do not* change clipboard

`s` - Delete the character under cursor then enter insert mode and *do not* change clipboard

`S` - Delete the line under cursor then enter insert mode and *do not* change clipboard

`c<motion>` - Enter insert mode over top the given area and *do not* change clipboard

`cc` - Enter insert mode over top the current line and *do not* change clipboard

`C` - Enter insert mode from cursor to the end of the line and *do not* change clipboard

`p` - Paste from specified register. Inserts after current line if text is multiline, after current character if text is non-multiline.  Leaves cursor at end of pasted text.

`P` - Same as p except inserts text before current line/character

`<leader>p` - Same as `p` except does not auto-format text.  This is only relevant if the auto-format option is enabled

`<leader>P` - Same as `P` except does not auto-format text. This is only relevant if the auto-format option is enabled

`gp` - Same as p but preserves the current cursor position

`gP` - Same as P but preserves the current cursor position

`g<leader>P` - Same as `<leader>P` but preserves the current cursor position

`g<leader>p` - Same as `<leader>p` but preserves the current cursor position

`m<motion>` - Delete over the given motion and copy text to clipboard

`mm` - Delete the current line and copy text to clipboard

*NOTE*: `M` is NOT mapped by default.  If you want it, include the following in your .vimrc:

`nmap M <Plug>MoveMotionEndOfLinePlug`

`<CTRL-P>` - Rotate the previous paste forward in yank buffer.  Note that this binding will only work if executed immediately after a paste

`<CTRL-N>` - Rotate the previous paste backward in yank buffer.  Note that this binding will only work if executed immediately after a paste

`[y` - Go backward in the yank buffer.  This can be executed at any time to modify order of yanks in the yank buffer (though I would recommend just using `<CTRL-P>` instead)

`]y` - Go forward in the yank buffer. This can be executed at any time to modify order of yanks in the yank buffer (though I would recommend just using `<CTRL-N>` instead)

`Y` - Copy text from cursor position to the end of line to the clipboard

**When the option `g:EasyClipUseSubstituteDefaults` is enabled, the following mappings are added:**

`s<motion>` - Substitute over the given motion with specified register (or default register if unspecified).  Note that this only applies if the `g:EasyClipUseSubstituteDefaults` option is set.

`ss` - Substitute over the current line with specified register (or default register if unspecified). Note that this only applies if the `g:EasyClipUseSubstituteDefaults` option is set.

`gs` - Same as s but preserves the current cursor position.

### Custom Yanks ###

If you have custom yanks that occur in your vimrc or elsewhere and would like them to be included in the yank history, you should call the EasyClip#Yank().  For example, to add a binding to yank the current file name you could add the following to your .vimrc:

`nnoremap <leader>yf :call EasyClip#Yank(expand('%'))<cr>`

Another way to do the above (which is necessary if you don't control the yank yourself), is to do the following:

`nnoremap <leader>yf :EasyClipBeforeYank<cr>:let @*=expand('%')<cr>:EasyClipOnYanksChanged<cr>`

Also, worth noting is the `Paste` command which takes an index and pastes the yank at that index.  For example, executing `:Paste 0` is equivalent to `p`, `:Paste 1` is equivalent to `"1p`, etc.  For use within scripting, there is also the corresponding method `EasyClip#PasteIndex` which like the command takes an index as parameter.  For the `P` equivalent, there is also a `PasteBefore` command and `EasyClip#PasteIndexBefore` method.

Another method worth noting is `EasyClip#GetYankAtIndex` which returns the text for the yank at a given index.

### Feedback ###

Feel free to email all feedback/criticism/suggestions to sfvermeulen@gmail.com.  Or, feel free to create a github issue.

### Changelog ###

2.4 (2015-11-19)
  - Added interactive paste by executing command `:PasteI`
  - Added `:Paste` and `:PasteBefore` commands, and also the corresponding methods `EasyClip#PasteIndex` and `EasyClip#PasteIndexBefore`

2.3 (2015-03-14)
  - Bug fixes to visual mode paste
  - Added plug mapping to toggle paste between format/unformatted

2.2 (2015-01-27)
  - Bug fixes
  - Removed the 'system sync' option since using unnamed register is sufficient for this
  - Added support for persistent/shared yanks

2.1 (2013-12-06)
  - Bug fixes
  - Disabled substitution operator by default
  - Added numbered registers

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

