" A lot of this is based on yankstack by Max Brunsfeld
" See originally code here: https://github.com/maxbrunsfeld/vim-yankstack

"""""""""""""""""""""""
" Variables
"""""""""""""""""""""""
let s:activeRegister = easyclip#GetDefaultReg()
let s:yankstackTail = []
let s:isFirstYank = 1
let s:preYankPos = []
let s:yankCount = 0
let s:lastSystemClipboard = ''

"""""""""""""""""""""""
" Commands
"""""""""""""""""""""""
command! EasyClipBeforeYank :call easyclip#yank#OnBeforeYank()
command! -nargs=0 Yanks call easyclip#yank#ShowYanks()
command! -nargs=0 ClearYanks call easyclip#yank#ClearYanks()

"""""""""""""""""""""""
" Plugs
"""""""""""""""""""""""
nnoremap <plug>EasyClipRotateYanksForward :<c-u>call easyclip#yank#ManuallyRotateYanks(1)<cr>
nnoremap <plug>EasyClipRotateYanksBackward :<c-u>call easyclip#yank#ManuallyRotateYanks(-1)<cr>

nnoremap <silent> <plug>YankLinePreserveCursorPosition :<c-u>call easyclip#yank#PreYankMotion()<cr>:call easyclip#yank#YankLine()<cr>
nnoremap <silent> <plug>YankPreserveCursorPosition :<c-u>call easyclip#yank#PreYankMotion()<cr>:set opfunc=easyclip#yank#YankMotion<cr>g@

"""""""""""""""""""""""
" Functions
"""""""""""""""""""""""
function! easyclip#yank#EasyClipGetNumYanks()
    return len(s:yankstackTail) + 1
endfunction

function! easyclip#yank#OnBeforeYank()
    if s:isFirstYank
        let s:isFirstYank = 0
        return
    endif
    let head = easyclip#yank#GetYankstackHead()
    if !empty(head.text) && (empty(s:yankstackTail) || (head != s:yankstackTail[0]))
        call insert(s:yankstackTail, head)
        let s:yankstackTail = s:yankstackTail[: g:EasyClipYankHistorySize-1]
    endif
endfunction

function! easyclip#yank#Rotate(offset)
    if empty(s:yankstackTail) | return | endif
    let offset_left = a:offset
    while offset_left != 0
        let head = easyclip#yank#GetYankstackHead()
        if offset_left > 0
            let entry = remove(s:yankstackTail, 0)
            call add(s:yankstackTail, head)
            let offset_left -= 1
        elseif offset_left < 0
            let entry = remove(s:yankstackTail, -1)
            call insert(s:yankstackTail, head)
            let offset_left += 1
        endif
        call easyclip#yank#SetYankStackHead(entry)
    endwhile
endfunction

function! easyclip#yank#ClearYanks()
    let s:yankstackTail = []
    let s:isFirstYank = 1
endfunction

function! easyclip#yank#GetYankstackHead()
    let reg = easyclip#GetDefaultReg()
    return { 'text': getreg(reg), 'type': getregtype(reg) }
endfunction

function! easyclip#yank#SetYankStackHead(entry)
    let reg = easyclip#GetDefaultReg()
    call setreg(reg, a:entry.text, a:entry.type)
endfunction

function! easyclip#yank#ShowYanks()
    echohl WarningMsg | echo "--- Yanks ---" | echohl None
    let i = 0
    for yank in easyclip#yank#EasyClipGetAllYanks()
        call easyclip#yank#ShowYank(yank, i)
        let i += 1
    endfor
endfunction

function! easyclip#yank#ShowYank(yank, index)
    let index = printf("%-4d", a:index)
    let line = substitute(a:yank.text, '\V\n', '^M', 'g')

    if len(line) > 80
        let line = line[: 80] . '…'
    endif

    echohl Directory | echo  index
    echohl None      | echon line
    echohl None
endfunction

function! easyclip#yank#PreYankMotion()
    let s:yankCount = v:count > 0 ? v:count : 1
    let s:activeRegister = v:register

    " This is necessary to get around a bug in vim where the active register persists to
    " the next command. Repro by doing "_d and then a command that uses v:register
    if s:activeRegister ==# "_"
        let s:activeRegister = easyclip#GetDefaultReg()
    endif

    let s:preYankPos = getpos('.')
endfunction

function! easyclip#yank#YankMotion(type)
    if &selection ==# 'exclusive'
      let excl_right = "\<right>"
    else
      let excl_right = ""
    endif

    EasyClipBeforeYank

    let oldVisualStart = getpos("'<")
    let oldVisualEnd = getpos("'>")

    if a:type ==# 'line'
        exe "keepjumps normal! `[V`]".excl_right."\"".s:activeRegister."y"
    elseif a:type ==# 'char'
        exe "keepjumps normal! `[v`]".excl_right."\"".s:activeRegister."y"
    else
        echom "Unexpected selection type"
        return
    endif

    call setpos("'<", oldVisualStart)
    call setpos("'>", oldVisualEnd)

    if !empty(s:preYankPos)
        call setpos('.', s:preYankPos)
        let s:preYankPos = []
    endif
endfunction

function! easyclip#yank#YankLine()
    EasyClipBeforeYank
    exec 'normal! '. s:yankCount . '"'. s:activeRegister .'yy'

    call setpos('.', s:preYankPos)
endfunction

function! easyclip#yank#EasyClipGetAllYanks()
    return [easyclip#yank#GetYankstackHead()] + s:yankstackTail
endfunction

function! easyclip#yank#ManuallyRotateYanks(offset)

    call easyclip#yank#Rotate(a:offset)
    echo "Current Yank: " . split(easyclip#yank#GetYankstackHead().text, '\n')[0] . "..."
endfunction

function! easyclip#yank#SetDefaultMappings()

    nmap [y <plug>EasyClipRotateYanksForward
    nmap ]y <plug>EasyClipRotateYanksBackward

    if g:EasyClipRemapCapitals
        " Make Y more consistent with C and D
        nnoremap <silent> Y :EasyClipBeforeYank<cr>y$
    endif

    nmap y <Plug>YankPreserveCursorPosition
    nmap yy <Plug>YankLinePreserveCursorPosition

    xnoremap <silent> <expr> y ':<c-u>EasyClipBeforeYank<cr>gv"'. v:register . 'y'
endfunction

function! easyclip#yank#OnFocusLost()
    let s:lastSystemClipboard = @*
endfunction

" Just automatically copy system clipboard to the default
" register
function! easyclip#yank#OnFocusGained()
    if s:lastSystemClipboard !=# @*
        EasyClipBeforeYank
        let s:lastSystemClipboard = @*
        exec 'let @'. easyclip#GetDefaultReg() .' = @*'
    endif
endfunction

function! easyclip#yank#InitSystemSync()

    " Check whether the system clipboard changed while focus was lost and 
    " add it to our yank buffer
    augroup _sync_clipboard
        au!
        autocmd FocusGained * call easyclip#yank#OnFocusGained()
        autocmd FocusLost * call easyclip#yank#OnFocusLost()
    augroup END
endfunction

function! easyclip#yank#Init()

    if g:EasyClipUseYankDefaults
        call easyclip#yank#SetDefaultMappings()
    endif

    if g:EasyClipDoSystemSync
        call easyclip#yank#InitSystemSync()
    endif
endfunction

