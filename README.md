easyclip
=============
### Simplified clipboard functionality for Vim.###

Author:  [Steve Vermeulen] (https://github.com/svermeulen), based on work by [Max Brunsfeld] (http://www.github.com/maxbrunsfeld)

[EasyClip](https://github.com/svermeulen/vim-easyclip) is a collection of clipboard related functionality with the goal of making using vim simpler without losing any of its power.

### Installation ###

I recommend loading your plugins with [vundle](https://github.com/gmarik/vundle) or [pathogen](https://github.com/tpope/vim-pathogen) (I personally prefer Vundle).

### Black Hole Redirection ###

By default, Vim's built-in delete operator will yank the deleted text in addition to just deleting it.  This works great when you want to cut text and paste it somewhere else, but in many other cases it can make things more difficult.  For example, if you want to make some tiny edit to fix formatting after cutting some text, you either have to have had the foresight to use a named register, or specify the black hole register explicitly to do your formatting, both of which seem overly cumbersome.  This plugin solves that problem by redirecting all change and delete operations to the black hole register and introducing a new operator, cut (by default mapped to the `m` key, for 'move', eg: `miw` to cut word under cursor)

There is simply no need to clutter up the yank history with every single edit, when you almost always know at the time you are deleting text whether it's something that is worth keeping around or not.

### Substitution Operator ###

Because replacing text is such a common operation, this plugin includes a motion for it (by default mapped to `s` key, for 'substitute').  It is essentially equivalent to doing a change operation then pasting using the specified register.  For example, to paste over the word under the cursor you would type `siw`.

### Yank Buffer ###

Easyclip allows you to yank and cut things without worrying about losing text that you copied previously.  It achieves this by storing all yanks into a buffer, which you can cycle through forward or backwards to choose the yank that you want.  (By default, cycle backward using `[y` and cycle forward using `]y`).  

The first line of the currently selected yank will be displayed in the status line.

Note: Most of the yank functionality is shamelessly stolen and adapted from the great yankstack plugin, which can be found [here](https://github.com/maxbrunsfeld/vim-yankstack)

### Paste ###

Easy clip makes the following changes to Vim's default paste
- Adds previously position to jump list
    - This allows you to easily return to the position the cursor was before pasting by pressing `<c-o>`
    - Note that the substitute operator also adds previous position to the jumplist, so you can hit `<c-o>` in that case to return to previous position as well
- Auto formats pasted text
    - Also automatically corrects the `[` and `]` marks according to the formatted text
- `p` and `P` behaviour
    - Always positions the cursor directly after the pasted text
    - `P` pastes text after the current line if multiline (or after the current character if non-multiline)
    - `P` behaves the same except acts before the current line (or before the current character)
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

`g:EasyClipUseDefaults` - If you want to load easyclip without defining any of the default key mappings, just set this to zero in your vimrc.  You can then pick and choose what to use from EasyVim by binding to the `<plug>` mappings yourself.

### Key Mappings ###


`s<motion>`       Substitute specified text with specified register

`ss`              Substitute current line with specified register

`S`               Substitute to end of line, similar to C/D/Y

`gs/gS`           Same as s/S but preserves the current cursor position

`sS`              Substitute current line with specified register, except the newline character

`p`               Paste from specified register. Inserts after current line if text is multiline, after current character if text is non-multiline.  Leaves cursor at end of pasted text.

`P`               Same as p except inserts text before current line/character

`gp/gP`           Same as p/P but preserves the current cursor position

`m<motion>`       Cut operator

`M`               Cut to end of line

`mm`              Cut line

`mM`              Cut line except newline

`[y`              Go backward in the yank buffer

`]y`              Go forward in the yank buffer

`yd`              Display contents of yank buffer

`Y`               Yank to end of line

### Custom Yanks ###

If you have custom yanks that occur in your vimrc or elsewhere and would like them to be included in the yank history, simply call the command `EasyClipBeforeYank` before the yank occurs.  For example, I have the following line in my vimrc to yank the current file name:

`nnoremap <leader>yfn :EasyClipBeforeYank<cr>:let @*=expand('%')<cr>`

### Disclaimer ###

This plugin is very new and as such most certainly contains bugs.  Feedback and contributions welcome!

### Todo ###

- Add back ability to toggle most recent paste between pastes after pasting, similar to yankstack/yankring 
- yd should open up the list of yanks in a scratch buffer so that it is searchable

### Changelog ###

0.1 (2013-07-08)
  - Initial release

### License ###

Distributed under the same terms as Vim itself.  See the vim license.
