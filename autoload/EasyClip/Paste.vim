
"""""""""""""""""""""""
" Variables
"""""""""""""""""""""""
let s:pasteOverrideRegister = ''
let s:lastPasteRegister =''
let s:lastPasteChangedtick = -1
let s:offsetSum = 0
let s:isSwapping = 0
let s:lastPasteWasAutoFormatted = 0

"""""""""""""""""""""""
" Plugs
"""""""""""""""""""""""

" Always toggle to 'paste mode' before pasting in insert mode
" We have two methods of doing this here, both with different advantages/disadvantages
" The first modifies the global value for pastetoggle, which may be undesirable if you want to bind
" pastetoggle to something yourself
" The second avoids the need to set the global pastetoggle but leaves insert mode briefly, which can
" cause the indentation level to change sometimes (for eg. when hitting 'o' then immediately doing CTRL+V to paste something)
if get(g:, 'EasyClipUseGlobalPasteToggle', 1)
    set pastetoggle=<plug>PasteToggle
    imap <expr> <plug>EasyClipInsertModePaste '<plug>PasteToggle<C-r>' . EasyClip#GetDefaultReg() . '<plug>PasteToggle'
else
    inoremap <expr> <plug>EasyClipInsertModePaste '<c-o>:setl paste<cr><c-r>' . EasyClip#GetDefaultReg() . '<c-o>:setl nopaste<cr>'
endif

cnoremap <expr> <plug>EasyClipCommandModePaste '<c-r>' . EasyClip#GetDefaultReg()

nnoremap <silent> <plug>EasyClipSwapPasteForward :call EasyClip#Paste#SwapPaste(1)<cr>
nnoremap <silent> <plug>EasyClipSwapPasteBackwards :call EasyClip#Paste#SwapPaste(0)<cr>

nnoremap <silent> <plug>EasyClipPasteAfter :<c-u>call EasyClip#Paste#PasteText(v:register, v:count, 'p', 1, "EasyClipPasteAfter")<cr>
nnoremap <silent> <plug>EasyClipPasteBefore :<c-u>call EasyClip#Paste#PasteText(v:register, v:count, 'P', 1, "EasyClipPasteBefore")<cr>

xnoremap <silent> <expr> <plug>XEasyClipPaste ':<c-u>call EasyClip#Paste#PasteTextVisualMode(''' . v:register . ''',' . v:count . ')<cr>'

nnoremap <silent> <plug>G_EasyClipPasteAfter :<c-u>call EasyClip#Paste#PasteText(v:register, v:count, 'gp', 1, "G_EasyClipPasteAfter")<cr>
nnoremap <silent> <plug>G_EasyClipPasteBefore :<c-u>call EasyClip#Paste#PasteText(v:register, v:count, 'gP', 1, "G_EasyClipPasteBefore")<cr>
xnoremap <silent> <plug>XG_EasyClipPaste "_d:<c-u>call EasyClip#Paste#PasteText(v:register, v:count, 'gP', 1, "G_EasyClipPasteBefore")<cr>

nnoremap <silent> <plug>EasyClipPasteUnformattedAfter :<c-u>call EasyClip#Paste#PasteText(v:register, v:count, 'p', 0, "EasyClipPasteUnformattedAfter")<cr>
nnoremap <silent> <plug>EasyClipPasteUnformattedBefore :<c-u>call EasyClip#Paste#PasteText(v:register, v:count, 'P', 0, "EasyClipPasteUnformattedBefore")<cr>

nnoremap <silent> <plug>G_EasyClipPasteUnformattedAfter :<c-u>call EasyClip#Paste#PasteText(v:register, v:count, 'gp', 0, "G_EasyClipPasteUnformattedAfter")<cr>
nnoremap <silent> <plug>G_EasyClipPasteUnformattedBefore :<c-u>call EasyClip#Paste#PasteText(v:register, v:count, 'gP', 0, "G_EasyClipPasteUnformattedBefore")<cr>

nnoremap <silent> <plug>XEasyClipPasteUnformatted "_d:<c-u>call EasyClip#Paste#PasteText(v:register, v:count, 'P', 0, "EasyClipPasteUnformattedBefore")<cr>

xnoremap <silent> <plug>XG_EasyClipPasteUnformatted "_d:<c-u>call EasyClip#Paste#PasteText(v:register, v:count, 'gP', 0, "G_EasyClipPasteUnformattedBefore")<cr>

nnoremap <silent> <plug>EasyClipToggleFormattedPaste :call EasyClip#Paste#ToggleFormattedPaste()<cr>

"""""""""""""""""""""""
" Functions
"""""""""""""""""""""""

" Adds the following functionality to paste:
" - add position of cursor before pasting to jumplist
" - optionally auto format, preserving the marks `[ and `] in the process
" - always position the cursor directly after the text for P and p versions
" - do not move the cursor for gp and gP versions
"
" op = either P or p
" format = 1 if we should autoformat
" inline = 1 if we should paste multiline text inline.
" That is, add the newline wherever the cursor is rather than above/below the current line
function! EasyClip#Paste#Paste(op, format, reg, inline)
    if !&modifiable && &buftype != 'terminal'
        return
    endif

    " This shouldn't be necessary since we calling this on FocusGained but
    " we call it here anyway since some console vims don't fire FocusGained
    call EasyClip#Shared#LoadFileIfChanged()

    let reg = empty(s:pasteOverrideRegister) ? a:reg : s:pasteOverrideRegister

    let text = getreg(reg)
    let textType = getregtype(reg)

    if text ==# ''
        " Necessary to avoid error
        return
    endif

    let s:lastPasteRegister = reg
    let isMultiLine = (text =~# "\n")
    let line = getline('.')
    let isEmptyLine = (line =~# '^\s*$')
    let oldPos = getpos('.')

    if a:inline
        " Do not save to jumplist when pasting inline
        exec 'normal! ' . (a:op ==# 'p' ? 'a' : 'i') . "\<c-r>" . reg . "\<right>"
    else
        let hasMoreThanOneLine = (text =~# "\n.*\n")
        " Save their old position to jumplist
        " Except for gp since the cursor pos shouldn't change
        " in that case
        if hasMoreThanOneLine && g:EasyClipAlwaysMoveCursorToEndOfPaste
            if a:op ==# 'P'
                " just doing m` doesn't work in this case so do it one line above
                exec "normal! km`j"
            elseif a:op ==# 'p'
                exec "normal! m`"
            endif
        endif

        exec "normal! \"".reg.a:op
    endif

    let shouldAutoFormat = 0

    " Only auto-format if it's multiline or pasting into an empty line
    if (isMultiLine || isEmptyLine)
        if exists('s:ForceAutoFormat')
            let shouldAutoFormat = s:ForceAutoFormat
        else
            let shouldAutoFormat = a:format && g:EasyClipAutoFormat && get(b:, 'EasyClipAutoFormat', 1)
        endif
    endif

    if (shouldAutoFormat)
        let s:lastPasteWasAutoFormatted = 1
        keepjumps normal! `]
        let startPos = getpos('.')
        normal! ^
        let numFromStart = startPos[2] - col('.')

        " Suppress 'x lines indented' message
        silent exec "keepjumps normal! `[=`]"
        call setpos('.', startPos)
        normal! ^

        if numFromStart > 0
            " Preserve cursor position so that it is placed at the last pasted character
            exec 'normal! ' . numFromStart . 'l'
        endif

        normal! m]
    else
        let s:lastPasteWasAutoFormatted = 0
    endif

    if a:op ==# 'gp'
        call setpos('.', oldPos)

        " This is necessary to avoid the bug where going up or down
        " does not use the right column number
        if col('.') == col('$') - 1
            normal! hl
        else
            normal! lh
        endif

    elseif a:op ==# 'gP'
        exec "keepjumps normal! `["

    else
        if isMultiLine
            if g:EasyClipAlwaysMoveCursorToEndOfPaste
                exec "keepjumps normal! `]"
            else
                exec "keepjumps normal! `["
            endif

            " We do not want to always go to the beginning of the line when pasting
            " visual block mode text.  Default behaviour is to retain the column position
            " Otherwise, we do want to go to the beginning of the line
            if len(textType) > 0 && textType[0] !=# ''
                normal! ^
            endif
        else
            exec "keepjumps normal! `]"
        endif
    endif

endfunction

function! s:EndSwapPaste()

    if !s:isSwapping
        " Should never happen
        throw 'Unknown Error detected during EasyClip paste'
    endif

    let s:isSwapping = 0

    augroup SwapPasteMoveDetect
        autocmd!
    augroup END

    " Return yank positions to their original state before we started swapping
    call EasyClip#Yank#Rotate(-s:offsetSum)
endfunction

function! EasyClip#Paste#WasLastChangePaste()
    return b:changedtick == s:lastPasteChangedtick || b:changedtick == g:lastSubChangedtick
endfunction

function! EasyClip#Paste#PasteTextVisualMode(reg, count)
    normal! gv

    let vmode = mode()
    " If we're pasting a single line yank in visual block mode then repeat paste for each line
    if vmode ==# '' && getreg(a:reg) !~# '\n'
        call EasyClip#Shared#LoadFileIfChanged()
        exec "normal! \"_c\<C-R>\<C-O>" . EasyClip#GetDefaultReg()
    else
        let lnum = line('''>')
        let cnum = col('''>')
        let cols = col([lnum, '$'])

        " See here for an explanation of this code:
        " https://github.com/svermeulen/vim-easyclip/wiki/Details-of-Visual-mode-paste
        if vmode ==# 'v'
            let shouldPasteBefore =
                \ (cnum != cols - 1 && (lnum != line('$') || cnum != cols)) &&
                \ (cnum != cols || col([lnum + 1, '$']) != 1)
        elseif vmode ==# 'V'
            let shouldPasteBefore = (lnum != line('$'))
        elseif vmode ==# ''
            let lnum = min([lnum, line('''<')])
            let cnum = max([cnum, col('''<')])
            let cols = col([lnum, '$'])

            let shouldPasteBefore = (cnum <= cols - 2 || cols <= 2)
        else
            " Should never happen
            throw 'Unknown error occurred during EasyClip paste'
        endif

        let [op, plugName] = shouldPasteBefore ? ['P', 'EasyClipPasteBefore'] : ['p', 'EasyClipPasteAfter']
        let l:save_selection = [getpos('''<'), getpos('''>')]

        normal! "_d

        " Don't add blank line when pasting linewise to an empty buffer.
        let l:isEmptyBuffer = (vmode ==# 'V') && (line('$') == 1) && empty(getline(1))
        if l:isEmptyBuffer | execute 'normal! gv' | endif

        call EasyClip#Paste#PasteText(a:reg, a:count, op, 1, plugName)

        call setpos('''<', l:save_selection[0])
        call setpos('''>', l:save_selection[1])
    endif
endfunction

function! EasyClip#Paste#PasteText(reg, count, op, format, plugName)

    let reg = a:reg

    " This is necessary to get around a bug in vim where the active register persists to
    " the next command. Repro by doing "_d and then a command that uses v:register
    if reg ==# '_'
        let reg = EasyClip#GetDefaultReg()
    end

    let i = 0
    let cnt = a:count > 0 ? a:count : 1

    while i < cnt
        call EasyClip#Paste#Paste(a:op, a:format, reg, 0)
        let i += 1
    endwhile

    let s:lastPasteChangedtick = b:changedtick

    if !empty(a:plugName)
        let fullPlugName = "\<plug>" . a:plugName
        silent! call repeat#setreg(fullPlugName, reg)
        silent! call repeat#set(fullPlugName, a:count)
    endif
endfunction

function! EasyClip#Paste#ToggleFormattedPaste()

    if !EasyClip#Paste#WasLastChangePaste()
        echo 'Last action was not paste, toggle unformat command ignored'
        return
    endif

    let s:ForceAutoFormat = !s:lastPasteWasAutoFormatted
    let s:pasteOverrideRegister = s:lastPasteRegister
    exec "normal \<Plug>(RepeatUndo)\<Plug>(RepeatDot)"
    let s:pasteOverrideRegister = ''
    echo (s:ForceAutoFormat ? 'Formatted' : 'Unformatted')
    unlet s:ForceAutoFormat

endfunction

function! EasyClip#Paste#SwapPaste(forward)
    if !EasyClip#Paste#WasLastChangePaste()
        if (a:forward) && exists('g:EasyClipSwapPasteForwardFallback')
            exec g:EasyClipSwapPasteForwardFallback
        elseif (!a:forward) && exists('g:EasyClipSwapPasteBackwardsFallback')
            exec g:EasyClipSwapPasteBackwardsFallback
        else
            echo 'Last action was not paste, swap ignored'
        endif
        return
    endif

    if s:isSwapping
        " Stop checking to end the swap session
        augroup SwapPasteMoveDetect
            autocmd!
        augroup END
    else
        let s:isSwapping = 1
        let s:offsetSum = 0
    endif

    if s:lastPasteRegister == EasyClip#GetDefaultReg()
        let offset = (a:forward ? 1 : -1)

        call EasyClip#Yank#Rotate(offset)
        let s:offsetSum += offset
    endif

    let s:pasteOverrideRegister = EasyClip#GetDefaultReg()
    exec 'normal u.'
    let s:pasteOverrideRegister = ''

    augroup SwapPasteMoveDetect
        autocmd!
        " Wait an extra CursorMoved event since there always seems to be one fired after this function ends
        autocmd CursorMoved <buffer> autocmd SwapPasteMoveDetect CursorMoved <buffer> call <sid>EndSwapPaste()
    augroup END
endfunction

" Default Paste Behaviour is:
" p - paste after newline if multiline, paste after character if non-multiline
" P - paste before newline if multiline, paste before character if non-multiline
" gp - same as p but keep old cursor position
" gP - same as P but keep old cursor position
" <c-p> - same as p but does not auto-format
" <c-s-p> - same as P but does not auto-format
" g<c-p> - same as c-p but keeps cursor position
" g<c-P> - same as c-p but keeps cursor position
function! EasyClip#Paste#SetDefaultMappings()

    let bindings =
    \ [
    \   ['p',  '<plug>XEasyClipPaste',  'x',  1],
    \   ['P',  '<plug>XEasyClipPaste',  'x',  1],
    \   ['gp',  '<plug>XG_EasyClipPaste',  'x',  1],
    \   ['gP',  '<plug>XG_EasyClipPaste',  'x',  1],
    \   ['<leader>p',  '<plug>XEasyClipPasteUnformatted',  'x',  1],
    \   ['<leader>P',  '<plug>XEasyClipPasteUnformatted',  'x',  1],
    \   ['P',  '<plug>EasyClipPasteBefore',  'n',  1],
    \   ['p',  '<plug>EasyClipPasteAfter',  'n',  1],
    \   ['gp',  '<plug>G_EasyClipPasteAfter',  'n',  1],
    \   ['gP',  '<plug>G_EasyClipPasteBefore',  'n',  1],
    \   ['<leader>p',  '<plug>EasyClipPasteUnformattedAfter',  'n',  1],
    \   ['<leader>P',  '<plug>EasyClipPasteUnformattedBefore',  'n',  1],
    \   ['g<leader>p',  '<plug>G_EasyClipPasteUnformattedAfter',  'n',  1],
    \   ['g<leader>P',  '<plug>G_EasyClipPasteUnformattedBefore',  'n',  1],
    \ ]

    if g:EasyClipUsePasteToggleDefaults
      let bindings += [
            \   ['<c-p>',  '<plug>EasyClipSwapPasteForward',  'n',  1],
            \   ['<c-n>',  '<plug>EasyClipSwapPasteBackwards',  'n',  1],
            \ ]
    endif

    for binding in bindings
        call call('EasyClip#AddWeakMapping', binding)
    endfor
endfunction

function! EasyClip#Paste#Init()

    if g:EasyClipUsePasteDefaults
        call EasyClip#Paste#SetDefaultMappings()
    endif
endfunction
