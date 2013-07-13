
" Most of this is based on yankstack by Max Brunsfeld
" See originally code here: https://github.com/maxbrunsfeld/vim-yankstack

let g:EasyClipYankHistorySize = get(g:, 'EasyClipYankHistorySize', 30)

let s:activeRegister = easyclip#GetDefaultReg()
let s:yankstackTail = []

function! s:OnBeforeYank()
    let head = s:GetYankstackHead()
    if !empty(head.text) && (empty(s:yankstackTail) || (head != s:yankstackTail[0]))
        call insert(s:yankstackTail, head)
        let s:yankstackTail = s:yankstackTail[: g:EasyClipYankHistorySize-1]
    endif
endfunction

function! s:RotateYanks(offset)
    if empty(s:yankstackTail) | return | endif
    let offset_left = a:offset
    while offset_left != 0
        let head = s:GetYankstackHead()
        if offset_left > 0
            let entry = remove(s:yankstackTail, 0)
            call add(s:yankstackTail, head)
            let offset_left -= 1
        elseif offset_left < 0
            let entry = remove(s:yankstackTail, -1)
            call insert(s:yankstackTail, head)
            let offset_left += 1
        endif
        call s:SetYankStackHead(entry)
    endwhile

    echo "Current Yank: " . split(s:GetYankstackHead().text, '\n')[0] . "..."
endfunction

function! s:GetYankstackHead()
    let reg = easyclip#GetDefaultReg()
    return { 'text': getreg(reg), 'type': getregtype(reg) }
endfunction

function! s:SetYankStackHead(entry)
    let reg = easyclip#GetDefaultReg()
    call setreg(reg, a:entry.text, a:entry.type)
endfunction

function! s:ShowYanks()
    echohl WarningMsg | echo "--- Yanks ---" | echohl None
    let i = 0
    for yank in g:EasyClipGetAllYanks()
        call s:ShowYank(yank, i)
        let i += 1
    endfor
endfunction

function! s:ShowYank(yank, index)
    let index = printf("%-4d", a:index)
    let lines = split(a:yank.text, '\n')
    let line = empty(lines) ? '' : lines[0]
    let line = substitute(line, '\t', repeat(' ', &tabstop), 'g')
    if len(line) > 80 || len(lines) > 1
        let line = line[: 80] . '…'
    endif

    echohl Directory | echo  index
    echohl None      | echon line
    echohl None
endfunction

let s:preYankPos = []

function! s:PreYankMotion()
    let s:activeRegister = v:register

    " This is necessary to get around a bug in vim where the active register persists to
    " the next command. Repro by doing "_d and then a command that uses v:register
    if s:activeRegister ==# "_"
        let s:activeRegister = easyclip#GetDefaultReg()
    endif

    let s:preYankPos = getpos('.')
endfunction

function! s:YankMotion(type)
    let oldValue = getreg(s:activeRegister)
    if &selection ==# 'exclusive'
      let excl_right = "\<right>"
    else
      let excl_right = ""
    endif

    EasyClipBeforeYank
    if a:type ==# 'line'
        exe "keepjumps normal! `[V`]".excl_right."\"".s:activeRegister."y"
    elseif a:type ==# 'char'
        exe "keepjumps normal! `[v`]".excl_right."\"".s:activeRegister."y"
    else
        echom "Unexpected selection type"
        return
    endif

    call setpos('.', s:preYankPos)
endfunction

function! s:YankLine()
    EasyClipBeforeYank
    exec 'normal! "'. s:activeRegister .'yy'
endfunction

function! g:EasyClipGetAllYanks()
    return [s:GetYankstackHead()] + s:yankstackTail
endfunction

nnoremap <plug>EasyClipRotateYanksForward :call <sid>RotateYanks(1)<cr>
nnoremap <plug>EasyClipRotateYanksBackward :call <sid>RotateYanks(-1)<cr>

nnoremap <silent> <plug>YankLinePreserveCursorPosition :call <sid>PreYankMotion()<cr>:call <sid>YankLine()<cr>
nnoremap <silent> <plug>YankPreserveCursorPosition :call <sid>PreYankMotion()<cr>:set opfunc=<sid>YankMotion<cr>g@

command! EasyClipBeforeYank :call <sid>OnBeforeYank()
command! -nargs=0 Yanks call s:ShowYanks()

if !exists('g:EasyClipUseYankDefaults') || g:EasyClipUseYankDefaults

    nmap [y <plug>EasyClipRotateYanksForward
    nmap ]y <plug>EasyClipRotateYanksBackward

    if !exists('g:EasyClipRemapCapitals') || g:EasyClipRemapCapitals
        " Make Y more consistent with C and D
        " you can do yy if you want the whole line
        nnoremap <silent> Y :EasyClipBeforeYank<cr>y$
    endif

    " Change all yanks to preserve the cursor position
    " Otherwise any yanks using T or backwards sentence/paragraph will move the cursor for some reason
    nmap y <Plug>YankPreserveCursorPosition
    nmap yy <Plug>YankLinePreserveCursorPosition

    xnoremap <silent> y :<c-u>EasyClipBeforeYank<cr>gvy
endif

