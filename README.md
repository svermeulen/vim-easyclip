vim-easyclip
=============
### Simplified clipboard functionality for Vim.###

Author:  [Steve Vermeulen] (https://github.com/svermeulen), based on work by [Max Brunsfeld] (http://www.github.com/maxbrunsfeld)

[EasyClip](https://github.com/svermeulen/vim-easyclip) is a collection of clipboard related functionality with the goal of making using vim simpler without losing any of its power.

### Installation ###

I recommend loading your plugins with [neobundle](https://github.com/Shougo/neobundle.vim) or [vundle](https://github.com/gmarik/vundle) or [pathogen](https://github.com/tpope/vim-pathogen)

This plugin also requires that you have Tim Pope's [repeat.vim](https://github.com/tpope/vim-repeat) plugin installed.

### Black Hole Redirection ###

By default, Vim's built-in delete operator will yank the deleted text in addition to just deleting it.  This works great when you want to cut text and paste it somewhere else, but in many other cases it can make things more difficult.  For example, if you want to make some tiny edit to fix formatting after cutting some text, you either have to have had the foresight to use a named register, or specify the black hole register explicitly to do your formatting.  This plugin solves that problem by redirecting all change and delete operations to the black hole register and introducing a new operator, 'cut' (by default mapped to 'm' for 'move' but can be redefined to your liking)

There is simply no need to clutter up the yank history with every single edit, when you almost always know at the time you are deleting text whether it's something that is worth keeping around or not.

### Substitution Operator ###

Because replacing text is such a common operation, this plugin includes a motion for it (by default mapped to `s` key, for 'substitute' but again this can be redefined).  It is essentially equivalent to doing a change operation then pasting using the specified register.  For example, to paste over the word under the cursor you would type `siw`, or to paste inside brackets, `si(`, etc.

It can also take a register to use for the substitution (eg. `"asip`), and is fully repeatable using the `.` key.

### What about the default s and m keys?!? ###

One implication of the default Easyclip mapping is that we shadow two of vim's defaults: `s` (substitute character) and `m` (set mark).  Both keys just happen to be perfect mnemonic's for EasyClip (`s` for substitute and `m` for move text) and they are among the easier keys to remap. However, they are both useful so will require alternatives:

`s` can be substituted for `cl` and `S` can be substituted for `cc`

`m` or 'set mark' does not have as easy an alternative so will require a remapping.  Good alternatives might be `gm`, `!`, or `\`, which you can apply by including the following in your vimrc:

`nnoremap gm m`

Of course, you can pick and choose which parts of EasyClip you want to use (see options section below), and redefine these operations however you want.  I do believe substitution and cut are common enough operations to justify a dedicated key but your opinion may differ.

### Yank Buffer ###

Easyclip allows you to yank and cut things without worrying about losing text that you copied previously.  It achieves this by storing all yanks into a buffer, which you can cycle through forward or backwards to choose the yank that you want.  (By default, cycle backward using `[y` and cycle forward using `]y`).

The first line of the currently selected yank will be displayed in the status line.

You can view the full list of yanks at any time by running the command `:Yanks`

Note: Most of the yank functionality is shamelessly stolen and adapted from another plugin, yankstack, which can be found [here](https://github.com/maxbrunsfeld/vim-yankstack)

One difference you'll find with yankstack is that it does not replace the most recent paste, and instead just moves the current register forward or backwards in the yank buffer.  In many cases you can remember the order of pastes (since you don't have it cluttered with deletes) so this is usually sufficient, but I do admit that yankring/yankstack-style swapping post-paste had it's uses, so I hope to look into adding this at some point (see todo below)

Another difference worth noting is that the cursor position does not change when a yank occurs.

### Paste ###

Easy clip makes the following changes to Vim's default paste
- Adds previously position to jump list
    - This allows you to easily return to the position the cursor was before pasting by pressing `<c-o>`
    - Note that the substitute operator also adds previous position to the jumplist, so you can hit `<c-o>` in that case as well
- Auto formats pasted text (including text pasted in insert mode using `<c-r>`)
    - Also automatically corrects the `[` and `]` marks according to the formatted text
- `p` and `P` behaviour
    - Always positions the cursor directly after the pasted text
    - `p` (lowercase) pastes text after the current line if multiline (or after the current character if non-multiline)
    - `P` (uppercase) behaves the same except acts before the current line (or before the current character)
- `gp` and `gP` behaviour
    - Same as `p` and `P` except the cursor does not move
    - Note there is a similar operator (`gs` / `gS`) for the substitute operator
- `<c-p>` behaviour
    - When the autoformat option is on, `<c-p>` can be used in place of `p` to paste without any formatting applied

### System Clipboard Sync ###

Easyclip will also automatically sync with your system clipboard.

Every time you leave and return to vim, easy clip will check whether you copied anything from outside Vim and add it to the yank history.

### Options ###

`g:EasyClipAutoFormat` - Set this to 0 to disable auto-formatting pasting text

`g:EasyClipYankHistorySize` - Change this to limit yank history, defaults to 30

`g:EasyClipDoSystemSync` - Set this to zero to disable system clipboard sync. Defaults to on.

You can also disable the default mappings by setting one or more of the following to zero:

    `g:EasyClipUseYankDefaults`
    
    `g:EasyClipUseCutDefaults`
    
    `g:EasyClipUsePasteDefaults`
    
    `g:EasyClipUseSubstituteDefaults`

You can then map to the specific `<plug>` mappings to define whatever mappings you want.  For example, to change the mapping for cut (by default set to `m`) to `yd`, include the following in your vimrc:`

    let g:EasyClipUseCutDefaults = 0

    nmap yd <Plug>MoveMotionPlug
    xmap yd <Plug>MoveMotionXPlug
    nmap ydd <Plug>MoveMotionLinePlug

### Key Mappings ###


`s<motion>`       Substitute specified text with specified register. 

`ss`              Substitute current line with specified register

`S`               Substitute to end of line, similar to C/D/Y

`gs/gS`           Same as s/S but preserves the current cursor position

`sS`              Substitute current line with specified register, except the newline character

`p`               Paste from specified register. Inserts after current line if text is multiline, after current character if text is non-multiline.  Leaves cursor at end of pasted text.

`P`               Same as p except inserts text before current line/character

`gp/gP`           Same as p/P but preserves the current cursor position

`m<motion>`       Cut operator

`mm`              Cut line

`[y`              Go backward in the yank buffer

`]y`              Go forward in the yank buffer

`Y`               Yank to end of line

### Custom Yanks ###

If you have custom yanks that occur in your vimrc or elsewhere and would like them to be included in the yank history, simply call the command `EasyClipBeforeYank` before the yank occurs.  For example, I have the following line in my vimrc to yank the current file name:

`nnoremap <leader>yfn :EasyClipBeforeYank<cr>:let @*=expand('%')<cr>`

### Disclaimer ###

This plugin is very new and as such may contain bugs.  Feedback and contributions welcome!

### Todo ###

- `:Yanks` command should maybe open up the list of yanks in a scratch buffer so that it is searchable
- Improve yank navigation, maybe using something like yankstack where you can toggle after paste rather than before

### Changelog ###

0.2 (2013-09-03)
  - Bunch of bug fixes

0.1 (2013-07-08)
  - Initial release

### License ###

Distributed under the same terms as Vim itself.  See the vim license.
