" A lot of this is based on yankstack by Max Brunsfeld
" See originally code here: https://github.com/maxbrunsfeld/vim-yankstack

"""""""""""""""""""""""
" Variables
"""""""""""""""""""""""
let s:activeRegister = EasyClip#GetDefaultReg()
let s:yankstackTail = []
let s:isFirstYank = 1
let s:preYankPos = []
let s:yankCount = 0
let s:lastSystemClipboard = ''

"""""""""""""""""""""""
" Commands
"""""""""""""""""""""""
command! EasyClipBeforeYank :call EasyClip#Yank#OnBeforeYank()
command! -nargs=0 Yanks call EasyClip#Yank#ShowYanks()
command! -nargs=0 ClearYanks call EasyClip#Yank#ClearYanks()

"""""""""""""""""""""""
" Plugs
"""""""""""""""""""""""
nnoremap <plug>EasyClipRotateYanksForward :<c-u>call EasyClip#Yank#ManuallyRotateYanks(1)<cr>
nnoremap <plug>EasyClipRotateYanksBackward :<c-u>call EasyClip#Yank#ManuallyRotateYanks(-1)<cr>

nnoremap <silent> <plug>YankLinePreserveCursorPosition :<c-u>call EasyClip#Yank#PreYankMotion()<cr>:call EasyClip#Yank#YankLine()<cr>
nnoremap <silent> <plug>YankPreserveCursorPosition :<c-u>call EasyClip#Yank#PreYankMotion()<cr>:set opfunc=EasyClip#Yank#YankMotion<cr>g@

xnoremap <silent> <plug>VisualModeYank :<c-u>call <sid>VisualModeYank(v:register)<cr>

"""""""""""""""""""""""
" Functions
"""""""""""""""""""""""
function! s:VisualModeYank(reg)
    if a:reg == EasyClip#GetDefaultReg()
        EasyClipBeforeYank
        normal! gvy
    else
        let oldDefault = EasyClip#GetCurrentYank()
        " If register is specified explicitly then do not change default register
        " or add to yank history
        exec "normal! gv\"" . a:reg . "y"
        call EasyClip#SetCurrentYank(oldDefault)
    endif

    call EasyClip#Yank#SaveSharedYanks()
endfunction

function! EasyClip#Yank#OnBeforeYank()
    if s:isFirstYank
        let s:isFirstYank = 0
        return
    endif

    let head = EasyClip#Yank#GetYankstackHead()

    if !empty(head.text) && (empty(s:yankstackTail) || (head != s:yankstackTail[0]))
        call insert(s:yankstackTail, head)
        let s:yankstackTail = s:yankstackTail[: g:EasyClipYankHistorySize-1]
    endif

    call s:OnYankBufferChanged()
endfunction

function! s:OnYankBufferChanged()

    for i in range(1, min([len(s:yankstackTail), 9]))
        let entry = s:yankstackTail[i-1]

        call setreg(i, entry.text, entry.type)
    endfor
endfunction

function! EasyClip#Yank#Rotate(offset)

    if empty(s:yankstackTail)
        return
    endif

    let offset_left = a:offset
    while offset_left != 0

        let head = EasyClip#Yank#GetYankstackHead()

        if offset_left > 0
            let l:entry = remove(s:yankstackTail, 0)
            call add(s:yankstackTail, head)
            let offset_left -= 1
        elseif offset_left < 0
            let l:entry = remove(s:yankstackTail, -1)
            call insert(s:yankstackTail, head)
            let offset_left += 1
        endif

        call EasyClip#Yank#SetYankStackHead(l:entry)
    endwhile

    call s:OnYankBufferChanged()

    call EasyClip#Yank#SaveSharedYanks()
endfunction

function! EasyClip#Yank#ClearYanks()
    let s:yankstackTail = []
    let s:isFirstYank = 1
    call EasyClip#Yank#SaveSharedYanks()
endfunction

function! EasyClip#Yank#GetYankstackHead()
    let reg = EasyClip#GetDefaultReg()

    return { 'text': getreg(reg), 'type': getregtype(reg) }
endfunction

function! EasyClip#Yank#SetYankStackHead(entry)
    let reg = EasyClip#GetDefaultReg()
    call setreg(reg, a:entry.text, a:entry.type)
endfunction

function! EasyClip#Yank#ShowYanks()
    echohl WarningMsg | echo "--- Yanks ---" | echohl None
    let i = 0
    for yank in EasyClip#Yank#EasyClipGetAllYanks()
        call EasyClip#Yank#ShowYank(yank, i)
        let i += 1
    endfor
endfunction

function! EasyClip#Yank#ShowYank(yank, index)
    let index = printf("%-4d", a:index)
    let line = substitute(a:yank.text, '\V\n', '^M', 'g')

    if len(line) > 80
        let line = line[: 80] . '…'
    endif

    echohl Directory | echo  index
    echohl None      | echon line
    echohl None
endfunction

function! EasyClip#Yank#PreYankMotion()
    let s:yankCount = v:count > 0 ? v:count : 1
    let s:activeRegister = v:register

    " This is necessary to get around a bug in vim where the active register persists to
    " the next command. Repro by doing "_d and then a command that uses v:register
    if s:activeRegister ==# "_"
        let s:activeRegister = EasyClip#GetDefaultReg()
    endif

    let s:preYankPos = getpos('.')
    call EasyClip#Yank#SaveSharedYanks()
endfunction

function! EasyClip#Yank#_YankLastChangedText(type, reg)

    if &selection ==# 'exclusive'
        let excl_right = "\<right>"
    else
        let excl_right = ""
    endif

    let oldDefaultReg = ''

    if a:reg ==# EasyClip#GetDefaultReg()
        " If register is declared explicitly then don't add it to yank history
        EasyClipBeforeYank
    else
        let oldDefaultReg = EasyClip#GetCurrentYank()
    endif

    if a:type !=# 'line' && a:type !=# 'char'
        echoerr "Unexpected selection type '" . a:type . "'"
        return
    endif

    exe "keepjumps normal! `[" . (a:type ==# 'line' ? 'V' : 'v')
    \ . "`]".excl_right."\"".a:reg."y"

    " When an explict register is specified it also clobbers the default register, so
    " restore that
    if a:reg !=# EasyClip#GetDefaultReg()
        call EasyClip#SetCurrentYank(oldDefaultReg)
    endif
endfunction

function! EasyClip#Yank#YankMotion(type)

    let oldVisualStart = getpos("'<")
    let oldVisualEnd = getpos("'>")

    call EasyClip#Yank#_YankLastChangedText(a:type, s:activeRegister)

    call setpos("'<", oldVisualStart)
    call setpos("'>", oldVisualEnd)

    if g:EasyClipPreserveCursorPositionAfterYank && !empty(s:preYankPos)
        call setpos('.', s:preYankPos)
        let s:preYankPos = []
        " This is necessary for some reason otherwise if you go down a line it will
        " jump to the column where the yank normally positions the cursor by default
        " To repro just remove this line, run yiq inside quotes, then go down a line
        if col('.') == col('$')-1
            normal! hl
        else
            normal! lh
        endif
    endif
endfunction

function! EasyClip#Yank#YankLine()
    EasyClipBeforeYank
    exec 'normal! '. s:yankCount . '"'. s:activeRegister .'yy'

    call setpos('.', s:preYankPos)
    call EasyClip#Yank#SaveSharedYanks()
endfunction

function! EasyClip#Yank#EasyClipGetAllYanks()
    if g:EasyClipShareYanks
        call EasyClip#Yank#LoadSharedYanks()
    endif

    return [EasyClip#Yank#GetYankstackHead()] + s:yankstackTail
endfunction

function! EasyClip#Yank#ManuallyRotateYanks(offset)

    call EasyClip#Yank#Rotate(a:offset)
    echo "Current Yank: " . split(EasyClip#Yank#GetYankstackHead().text, '\n')[0] . "..."
endfunction

function! EasyClip#Yank#SetDefaultMappings()

    let bindings =
    \ [
    \   ['[y',  '<plug>EasyClipRotateYanksForward',  'n',  1],
    \   [']y',  '<plug>EasyClipRotateYanksBackward',  'n',  1],
    \   ['Y',  ':EasyClipBeforeYank<cr>y$',  'n',  0],
    \   ['y',  '<Plug>YankPreserveCursorPosition',  'n',  1],
    \   ['yy',  '<Plug>YankLinePreserveCursorPosition',  'n',  1],
    \   ['y',  '<Plug>VisualModeYank',  'x',  1],
    \ ]

    for binding in bindings
        call call("EasyClip#AddWeakMapping", binding)
    endfor
endfunction

function! EasyClip#Yank#OnFocusLost()
    if EasyClip#GetDefaultReg() ==# '"'
        call setreg('*', EasyClip#GetCurrentYank())
    endif

    let s:lastSystemClipboard = @*
endfunction

" Just automatically copy system clipboard to the default
" register
function! EasyClip#Yank#OnFocusGained()
    let newClipboardValue = @*

    " If the clipboard contains binary information then 'newClipboardValue' will be empty
    if newClipboardValue !=# '' && s:lastSystemClipboard !=# newClipboardValue
        EasyClipBeforeYank
        let s:lastSystemClipboard = newClipboardValue
        exec 'let @'. EasyClip#GetDefaultReg() .' = newClipboardValue'
    endif
endfunction

function! EasyClip#Yank#InitSystemSync()

    " Check whether the system clipboard changed while focus was lost and
    " add it to our yank buffer
    augroup _sync_clipboard
        au!
        autocmd FocusGained * call EasyClip#Yank#OnFocusGained()
        autocmd FocusLost * call EasyClip#Yank#OnFocusLost()
    augroup END
endfunction

function! EasyClip#Yank#SaveSharedYanks()
    if !g:EasyClipShareYanks
        return
    endif

    let l:yankstackStrings = []

    for yankStackItem in [EasyClip#Yank#GetYankstackHead()] + s:yankstackTail
        let l:yankstackItemCopy = yankStackItem
        let l:yankstackItemCopy.text = substitute(yankStackItem.text, "\n", '\\n', 'g')
        call add(l:yankstackStrings, string(l:yankstackItemCopy))
    endfor

    " Thanks https://github.com/xolox/vim-misc/blob/master/autoload/xolox/misc/list.vim
    " Remove duplicate values from the given list in-place (preserves order).
    call reverse(l:yankstackStrings)
    call filter(l:yankstackStrings, 'count(l:yankstackStrings, v:val) == 1')
    let l:yankstackStrings = reverse(l:yankstackStrings)

    let fileWriteStatus = writefile(l:yankstackStrings, s:shareYanksFile)
    if fileWriteStatus != 0
        echohl ErrorMsg
        echo 'Failed to save EasyClip stack'
        echohl None
    endif
endfunction

function! EasyClip#Yank#LoadSharedYanks()
    if !g:EasyClipShareYanks
        return
    endif

    for dir in split(g:EasyClipShareYanksDirectory, ",")
        if isdirectory(expand(dir))
            let g:EasyClipShareYanksDirectory = expand(dir)
            break
        endif
    endfor
    let s:shareYanksFile = g:EasyClipShareYanksDirectory . '/' . g:EasyClipShareYanksFile

    if filereadable(s:shareYanksFile)
        let l:allYanksFileContent = readfile(s:shareYanksFile)
        let l:allYanks = []
        for allYanksFileContentLine in l:allYanksFileContent
            let l:allYanksItem = eval(allYanksFileContentLine)
            let l:allYanksItem.text = substitute(l:allYanksItem.text, '\\n', "\n", 'g')
            call add(l:allYanks, l:allYanksItem)
        endfor

        if len(l:allYanks)
            call EasyClip#Yank#SetYankStackHead(remove(l:allYanks, 0))
            let s:yankstackTail = l:allYanks
        endif
    endif
endfunction

function! EasyClip#Yank#InitSharedYanks()
    call EasyClip#Yank#LoadSharedYanks()
endfunction

function! EasyClip#Yank#Init()

    if g:EasyClipUseYankDefaults
        call EasyClip#Yank#SetDefaultMappings()
    endif

    if g:EasyClipDoSystemSync
        call EasyClip#Yank#InitSystemSync()
    endif

    if g:EasyClipShareYanks
        call EasyClip#Yank#InitSharedYanks()
    endif
endfunction

