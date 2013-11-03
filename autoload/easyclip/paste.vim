"""""""""""""""""""""""
" Variables
"""""""""""""""""""""""
let s:pasteOverrideRegister = ''
let s:lastPasteRegister =''
let s:insertModePasteRegister=''
let s:swapPasteFromInsertModeStarted = 0
let s:oldCompleteFunc = ''
let s:waitingToExitInsertModePaste = 0
let s:lastPasteChangedtick = -1
let s:commandModeColPosStart = 0
let s:commandModeColPosEnd = 0

"""""""""""""""""""""""
" Plugs
"""""""""""""""""""""""

inoremap <plug>EasyClipInsertModeSwapPasteForward <c-r>=easyclip#paste#PreInsertModeSwapPaste()<cr><c-o>:call easyclip#paste#SwapPaste(1)<cr><right>
inoremap <plug>EasyClipInsertModeSwapPasteBackwards <c-r>=easyclip#paste#PreInsertModeSwapPaste()<cr><c-o>:call easyclip#paste#SwapPaste(0)<cr><right>

nnoremap <plug>InsertModePaste :call easyclip#paste#InsertModePaste()<cr>

inoremap <expr> <plug>EasyClipInsertModePaste easyclip#paste#FakeUserExitingAndThenPasting(easyclip#GetDefaultReg())

cnoremap <plug>EasyClipCommandModePaste <c-f>:call easyclip#paste#CommandModePaste()<cr><right>
cnoremap <plug>EasyClipCommandModeSwapPasteForward <c-f>:call easyclip#paste#CommandModeSwapPaste(1)<cr><right>
cnoremap <plug>EasyClipCommandModeSwapPasteBackward <c-f>:call easyclip#paste#CommandModeSwapPaste(-1)<cr><right>

nnoremap <silent> <plug>EasyClipSwapPasteForward :call easyclip#paste#SwapPaste(1)<cr>
nnoremap <silent> <plug>EasyClipSwapPasteBackwards :call easyclip#paste#SwapPaste(0)<cr>

" Our Paste options are:
" p - paste after newline if multiline, paste after character if non-multiline
" P - paste before newline if multiline, paste before character if non-multiline
" gp - same as p but keep old cursor position
" gP - same as P but keep old cursor position
" <c-p> - same as p but does not auto-format
" <c-s-p> - same as P but does not auto-format
" g<c-p> - same as c-p but keeps cursor position
" g<c-P> - same as c-p but keeps cursor position
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
        if isMultiLine
            if a:op ==# 'P'
                " just doing m` doesn't work in this case so do it one line above
                exec "normal! km`j"
            elseif a:op == 'p'
                exec "normal! m`"
            endif
        endif

        exec "normal! \"".reg.a:op
    endif

    if g:EasyClipAutoFormat
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
        " a:op ==# 'P' || a:op ==# 'p'
        exec "keepjumps normal! `]"
    endif
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

function! easyclip#paste#InsertLeaveCheckEndInsertModePaste()
    call ave#Assert(s:waitingToExitInsertModePaste)

    if s:swapPasteFromInsertModeStarted
        " We leave insert mode briefly when swapping pastes, so we don't 
        " want to re-enable completion just yet
        let s:swapPasteFromInsertModeStarted = 0
    else
        call easyclip#paste#EndWaitInsertMode()
    endif
endfunction

function! easyclip#paste#CheckEndInsertModePaste()

    call ave#Assert(s:waitingToExitInsertModePaste)

    if !easyclip#paste#WasLastChangePaste()
        call easyclip#paste#EndWaitInsertMode()

        if !empty(&completefunc)
            " This is necessary to trigger YCM completion
            " Otherwise we have to wait until the next character is typed
            call feedkeys( "\<C-X>\<C-U>\<C-P>", 'n' )
        endif
    endif
endfunction

function! easyclip#paste#EndWaitInsertMode()

    augroup _tempDisableCompleteFunc
        autocmd!
    augroup END

    exec "set completefunc=" . s:oldCompleteFunc

    let s:waitingToExitInsertModePaste = 0
endfunction

function! easyclip#paste#InsertModePaste()

    " In order to get insert mode swap-paste to work we need to temporarily 
    " disable the current completion function
    " This is necessary for YouCompleteMe to work alongside insert mode swap-paste 
    " since YouCompleteMe causes a change in b:changedtick when it brings up
    " the menu, and since we use undo to swap pastes, it wouldn't work

    let s:waitingToExitInsertModePaste = 1
    let s:oldCompleteFunc = &completefunc
    set completefunc=

    let s:pasteOverrideRegister=s:insertModePasteRegister
    exec "normal \<plug>EasyClipPasteAfter"
    let s:pasteOverrideRegister=''

    augroup _tempDisableCompleteFunc
        autocmd!
        autocmd InsertCharPre * call easyclip#paste#CheckEndInsertModePaste()
        autocmd CursorMovedI * call easyclip#paste#CheckEndInsertModePaste()
        autocmd CursorMoved * call easyclip#paste#CheckEndInsertModePaste()
        autocmd CursorHold,CursorHoldI * call easyclip#paste#CheckEndInsertModePaste()
        autocmd InsertLeave * call easyclip#paste#InsertLeaveCheckEndInsertModePaste()
    augroup END
endfunction

function! easyclip#paste#PreInsertModeSwapPaste()
    let s:swapPasteFromInsertModeStarted = 1
    return ""
endfunction

function! easyclip#paste#FakeUserExitingAndThenPasting(reg)
    let s:insertModePasteRegister = a:reg

    " This is a hack but the only way to accomplish what I want as far as I can tell
    " We need the paste during insert mode to be a seperate 'undo' action
    " So that swap paste will work correctly
    " So we need to use feedkeys to pretend as if the user exitted insert mode,
    " pasted text, then returned to insert mode for this to work
    call feedkeys("\<esc>\<plug>InsertModePastea", 't')
    return ""
endfunction

" Make sure paste works the same in insert mode
function! easyclip#paste#FixInsertModePaste()

    " Note that we don't include the '.' register because
    " this will not work as expected since we leave insert mode to paste
    let registers = '"1234567890abcdefghijklmnopqrstuvwxyz*'

    for i in range(strlen(registers))
        let chr = strpart(registers, i, 1)

        " Note: This doesn't work when completion is enabled
        " As far as I can tell it's impossible to remap <c-r>[key] once completion is started
        exec "inoremap <expr> <c-r>". chr . " easyclip#paste#FakeUserExitingAndThenPasting('". chr ."')"
    endfor
endfunction

function! easyclip#paste#SwapPaste(forward)
    if easyclip#paste#WasLastChangePaste()

        if s:lastPasteRegister == easyclip#GetDefaultReg()
            if a:forward
                call easyclip#yank#Rotate(1)
            else
                call easyclip#yank#Rotate(-1)
            endif
        endif

        let s:pasteOverrideRegister = easyclip#GetDefaultReg()
        exec "normal u."
        let s:pasteOverrideRegister = ''
    else
        echo 'was not last paste, ' . b:changedtick . ' != '. s:lastPasteChangedtick
    endif
endfunction 

function! easyclip#paste#CommandModePaste()

    if getreg(easyclip#GetDefaultReg()) =~ '\n'
        " Multi-line, ignore
        exec "normal! \<c-c>"
        return
    endif

    let s:commandModeColPosStart = getpos('.')[2]
    let oldVirtualEdit=&virtualedit
    set virtualedit=onemore
    exec "normal P"
    let s:commandModeColPosEnd = getpos('.')[2]
    exec "normal! \<c-c>"
    exec 'set virtualedit=' . oldVirtualEdit
endfunction

function! easyclip#paste#CommandModeSwapPaste(offset)

    if getpos('.')[2] != (s:commandModeColPosEnd+1)
        " Cursor was moved since last paste, ignore
        exec "normal! \<c-c>"
        return
    endif

    let curPos = getpos('.')
    let curPos[2] = s:commandModeColPosStart
    call setpos('.', curPos)

    call easyclip#yank#Rotate(a:offset)

    let cnt = 0
    let foundYank = 1

    " Swapping paste in command mode only works for non-multiline yanks
    " So keep rotating yanks until you find one or give up if there is none
    while getreg(easyclip#GetDefaultReg()) =~ '\n'

        if cnt == easyclip#yank#EasyClipGetNumYanks()
            let foundYank = 0
            break
        endif

        call easyclip#yank#Rotate(a:offset)
        let cnt = cnt + 1
    endwhile

    if foundYank
        exec "normal! \"_d$"
        exec "normal p"
        let s:commandModeColPosEnd = getpos('.')[2]
    endif

    exec "normal! A\<c-c>"
endfunction

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

    call easyclip#paste#FixInsertModePaste()

    if g:EasyClipUsePasteDefaults
        call easyclip#paste#SetDefaultMappings()
    endif
endfunction
