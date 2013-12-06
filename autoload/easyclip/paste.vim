"""""""""""""""""""""""
" Variables
"""""""""""""""""""""""
let s:pasteOverrideRegister = ''
let s:lastPasteRegister =''
let s:lastPasteChangedtick = -1
let s:offsetSum = 0
let s:isSwapping = 0

"""""""""""""""""""""""
" Plugs
"""""""""""""""""""""""

set pastetoggle=<plug>PasteToggle

" Always toggle to 'paste mode' before pasting in insert mode
exec "imap <plug>EasyClipInsertModePaste <plug>PasteToggle<C-r>" . easyclip#GetDefaultReg() . "<plug>PasteToggle"

nnoremap <silent> <plug>EasyClipSwapPasteForward :call easyclip#paste#SwapPaste(1)<cr>
nnoremap <silent> <plug>EasyClipSwapPasteBackwards :call easyclip#paste#SwapPaste(0)<cr>

nnoremap <silent> <plug>EasyClipPasteAfter :<c-u>call easyclip#paste#PasteText(v:register, v:count, 'p', 1, "EasyClipPasteAfter")<cr>
nnoremap <silent> <plug>EasyClipPasteBefore :<c-u>call easyclip#paste#PasteText(v:register, v:count, 'P', 1, "EasyClipPasteBefore")<cr>
xnoremap <silent> <expr> <plug>XEasyClipPaste '"_d:<c-u>call easyclip#paste#PasteText("' . v:register . '",' . v:count . ', "P", 1, "EasyClipPasteBefore")<cr>'

nnoremap <silent> <plug>G_EasyClipPasteAfter :<c-u>call easyclip#paste#PasteText(v:register, v:count, 'gp', 1, "G_EasyClipPasteAfter")<cr>
nnoremap <silent> <plug>G_EasyClipPasteBefore :<c-u>call easyclip#paste#PasteText(v:register, v:count, 'gP', 1, "G_EasyClipPasteBefore")<cr>
xnoremap <silent> <plug>XG_EasyClipPaste "_d:<c-u>call easyclip#paste#PasteText(v:register, v:count, 'gP', 1, "G_EasyClipPasteBefore")<cr>

nnoremap <silent> <plug>EasyClipPasteUnformattedAfter :<c-u>call easyclip#paste#PasteText(v:register, v:count, 'p', 0, "EasyClipPasteUnformattedAfter")<cr>
nnoremap <silent> <plug>EasyClipPasteUnformattedBefore :<c-u>call easyclip#paste#PasteText(v:register, v:count, 'P', 0, "EasyClipPasteUnformattedBefore")<cr>

nnoremap <silent> <plug>G_EasyClipPasteUnformattedAfter :<c-u>call easyclip#paste#PasteText(v:register, v:count, 'gp', 0, "G_EasyClipPasteUnformattedAfter")<cr>
nnoremap <silent> <plug>G_EasyClipPasteUnformattedBefore :<c-u>call easyclip#paste#PasteText(v:register, v:count, 'gP', 0, "G_EasyClipPasteUnformattedBefore")<cr>

nnoremap <silent> <plug>XEasyClipPasteUnformatted "_d:<c-u>call easyclip#paste#PasteText(v:register, v:count, 'P', 0, "EasyClipPasteUnformattedBefore")<cr>

xnoremap <silent> <plug>XG_EasyClipPasteUnformatted "_d:<c-u>call easyclip#paste#PasteText(v:register, v:count, 'gP', 0, "G_EasyClipPasteUnformattedBefore")<cr>

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
function! easyclip#paste#Paste(op, format, reg, inline)

    let reg = empty(s:pasteOverrideRegister) ? a:reg : s:pasteOverrideRegister

    let text = getreg(reg)

    if text ==# ''
        " Necessary to avoid error
        return
    endif

    let s:lastPasteRegister = reg
    let isMultiLine = (text =~# "\n")
    let line = getline(".")
    let isEmptyLine = (line =~# '^\s*$')
    let oldPos = getpos('.')

    if a:inline
        " Do not save to jumplist when pasting inline
        exec "normal! ". (a:op ==# 'p' ? 'a' : 'i') . "\<c-r>". reg . "\<right>"
    else
        " Save their old position to jumplist
        " Except for gp since the cursor pos shouldn't change
        " in that case
        if isMultiLine && g:EasyClipAlwaysMoveCursorToEndOfPaste
            if a:op ==# 'P'
                " just doing m` doesn't work in this case so do it one line above
                exec "normal! km`j"
            elseif a:op == 'p'
                exec "normal! m`"
            endif
        endif

        exec "normal! \"".reg.a:op
    endif

    if (isMultiLine || isEmptyLine) && a:format && g:EasyClipAutoFormat
        " Only auto-format if it's multiline or pasting into an empty line

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
            exec "normal! ". numFromStart . "l"
        endif

        normal! m]
    endif

    if a:op ==# 'gp'
        call setpos('.', oldPos)

    elseif a:op ==# 'gP'
        exec "keepjumps normal! `["

    else
        if !isMultiLine || g:EasyClipAlwaysMoveCursorToEndOfPaste
            exec "keepjumps normal! `]"
        else
            exec "keepjumps normal! `["
            normal! ^
        endif
    endif

endfunction

function! s:EndSwapPaste()

    if !s:isSwapping
        " Should never happen
        throw "Unknown Error detected during EasyClip paste"
    endif

    let s:isSwapping = 0

    augroup SwapPasteMoveDetect
        autocmd!
    augroup END

    " Return yank positions to their original state before we started swapping
    call easyclip#yank#Rotate(-s:offsetSum)
endfunction

function! easyclip#paste#WasLastChangePaste()
    return b:changedtick == s:lastPasteChangedtick || b:changedtick == g:lastSubChangedtick
endfunction

function! easyclip#paste#PasteText(reg, count, op, format, plugName)
    let reg = a:reg

    " This is necessary to get around a bug in vim where the active register persists to
    " the next command. Repro by doing "_d and then a command that uses v:register
    if reg == "_"
        let reg = easyclip#GetDefaultReg()
    end

    let i = 0
    let cnt = a:count > 0 ? a:count : 1 

    while i < cnt
        call easyclip#paste#Paste(a:op, a:format, reg, 0)
        let i = i + 1
    endwhile

    let s:lastPasteChangedtick = b:changedtick

    if !empty(a:plugName)
        let fullPlugName = "\<plug>". a:plugName
        silent! call repeat#setreg(fullPlugName, reg)
        silent! call repeat#set(fullPlugName, a:count)
    endif
endfunction

function! easyclip#paste#SwapPaste(forward)
    if easyclip#paste#WasLastChangePaste()

        if s:isSwapping
            " Stop checking to end the swap session
            augroup SwapPasteMoveDetect
                autocmd!
            augroup END
        else
            let s:isSwapping = 1
            let s:offsetSum = 0
        endif

        if s:lastPasteRegister == easyclip#GetDefaultReg()
            let offset = (a:forward ? 1 : -1)

            call easyclip#yank#Rotate(offset)
            let s:offsetSum += offset
        endif

        let s:pasteOverrideRegister = easyclip#GetDefaultReg()
        exec "normal u."
        let s:pasteOverrideRegister = ''

        " Wait until the cursor moves and then reset the yank stack 
        augroup SwapPasteMoveDetect
            autocmd!
            " Wait an extra CursorMoved event since there always seems to be one fired after this function ends
            autocmd CursorMoved <buffer> autocmd SwapPasteMoveDetect CursorMoved <buffer> call <sid>EndSwapPaste()
        augroup END
    else
        echo 'Last action was not paste, swap ignored'
        "echo  b:changedtick . ' != '. s:lastPasteChangedtick
    endif
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
function! easyclip#paste#SetDefaultMappings()

    xmap p <plug>XEasyClipPaste
    xmap P <plug>XEasyClipPaste

    xmap gp <plug>XG_EasyClipPaste
    xmap gP <plug>XG_EasyClipPaste

    xmap <leader>p <plug>XEasyClipPasteUnformatted
    xmap <leader>P <plug>XEasyClipPasteUnformatted

    nmap P <plug>EasyClipPasteBefore
    nmap p <plug>EasyClipPasteAfter

    nmap gp <plug>G_EasyClipPasteAfter
    nmap gP <plug>G_EasyClipPasteBefore

    nmap <leader>p <plug>EasyClipPasteUnformattedAfter
    nmap <leader>P <plug>EasyClipPasteUnformattedBefore

    nmap g<leader>p <plug>G_EasyClipPasteUnformattedAfter
    nmap g<leader>P <plug>G_EasyClipPasteUnformattedBefore

    if g:EasyClipUsePasteToggleDefaults
        nmap <c-p> <plug>EasyClipSwapPasteForward
        nmap <c-n> <plug>EasyClipSwapPasteBackwards
    endif
endfunction

function! easyclip#paste#Init()

    if g:EasyClipUsePasteDefaults
        call easyclip#paste#SetDefaultMappings()
    endif
endfunction
