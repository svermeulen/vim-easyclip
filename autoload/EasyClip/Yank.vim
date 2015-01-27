scriptencoding utf-8

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
let s:preYankWinView = {}

"""""""""""""""""""""""
" Commands
"""""""""""""""""""""""
command! EasyClipBeforeYank :call EasyClip#Yank#OnBeforeYank()
command! EasyClipOnYanksChanged :call EasyClip#Yank#OnYanksChanged()
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
        EasyClipOnYanksChanged
    else
        let oldDefault = EasyClip#GetCurrentYank()
        " If register is specified explicitly then do not change default register
        " or add to yank history
        exec "normal! gv\"" . a:reg . "y"
        call EasyClip#SetCurrentYank(oldDefault)
    endif
endfunction

function! EasyClip#Yank#OnBeforeYank()
    call EasyClip#Shared#LoadFileIfChanged()

    if s:isFirstYank
        let s:isFirstYank = 0
        return
    endif

    let head = EasyClip#Yank#GetYankstackHead()
    call s:AddToTail(head)
endfunction

function! s:AddToTail(entry)
    if !empty(a:entry.text) && (empty(s:yankstackTail) || (a:entry != s:yankstackTail[0]))
        call insert(s:yankstackTail, a:entry)
        let s:yankstackTail = s:yankstackTail[: g:EasyClipYankHistorySize-1]
    endif
endfunction

function! EasyClip#Yank#SyncNumberedRegisters()
    for i in range(1, min([len(s:yankstackTail), 9]))
        let entry = s:yankstackTail[i-1]

        call setreg(i, entry.text, entry.type)
    endfor
endfunction

function! EasyClip#Yank#OnYanksChanged()

    call EasyClip#Yank#SyncNumberedRegisters()
    call EasyClip#Shared#SaveToFileIfDirty()
endfunction

function! EasyClip#Yank#Rotate(offset)

    call EasyClip#Shared#LoadFileIfChanged()

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

    EasyClipOnYanksChanged
endfunction

function! EasyClip#Yank#ClearYanks()
    call EasyClip#Shared#LoadFileIfChanged()

    let l:size = len(s:yankstackTail)

    let s:yankstackTail = []
    let s:isFirstYank = 1
    EasyClipOnYanksChanged

    echo "Cleared yank history of " . l:size . " entries"
endfunction

function! EasyClip#Yank#GetYankstackHead()
    let reg = EasyClip#GetDefaultReg()
    return { 'text': getreg(reg), 'type': getregtype(reg) }
endfunction

function! EasyClip#Yank#GetYankstackTail()
    return s:yankstackTail
endfunction

function! EasyClip#Yank#SetYankStackHead(entry)
    let reg = EasyClip#GetDefaultReg()
    call setreg(reg, a:entry.text, a:entry.type)
endfunction

function! EasyClip#Yank#SetYankStackTail(tail)
    let s:yankstackTail = a:tail
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

    if len(line) > g:EasyClipShowYanksWidth
        let line = line[: g:EasyClipShowYanksWidth] . '…'
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
    let s:preYankWinView = winsaveview()
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
    if a:reg ==# EasyClip#GetDefaultReg()
        EasyClipOnYanksChanged
    else
        call EasyClip#SetCurrentYank(oldDefaultReg)
    endif
endfunction

function! EasyClip#Yank#YankMotion(type)

    let oldVisualStart = getpos("'<")
    let oldVisualEnd = getpos("'>")

    call EasyClip#Yank#_YankLastChangedText(a:type, s:activeRegister)

    call setpos("'<", oldVisualStart)
    call setpos("'>", oldVisualEnd)

    if g:EasyClipPreserveCursorPositionAfterYank && !empty(s:preYankWinView)

        call winrestview(s:preYankWinView)
        let s:preYankWinView = {}

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
    EasyClipOnYanksChanged
endfunction

function! EasyClip#Yank#EasyClipGetAllYanks()
    call EasyClip#Shared#LoadFileIfChanged()
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
    \   ['Y',  ':EasyClipBeforeYank<cr>y$:EasyClipOnYanksChanged<cr>',  'n',  0],
    \   ['y',  '<Plug>YankPreserveCursorPosition',  'n',  1],
    \   ['yy',  '<Plug>YankLinePreserveCursorPosition',  'n',  1],
    \   ['y',  '<Plug>VisualModeYank',  'x',  1],
    \ ]

    for binding in bindings
        call call("EasyClip#AddWeakMapping", binding)
    endfor
endfunction

function! EasyClip#Yank#OnFocusLost()
    " It is tempting to call EasyClip#Shared#SaveToFileIfDirty here instead of every time the yank buffer
    " changes but we can't do this since this event doesn't fire quick enough (and often fires after OnFocusGained
    " has already fired on the other vim instance)

    if EasyClip#GetDefaultReg() ==# '*'
        let s:yankHeadBeforeFocusLost = EasyClip#Yank#GetYankstackHead()
    endif
endfunction

function! EasyClip#Yank#OnFocusGained()
    let didLoad = EasyClip#Shared#LoadFileIfChanged()

    " If we are using the system register as our yank head,
    " then we have to make sure that it doesn't get clobbered
    " when the user leaves and then returns to vim
    " To do this, we check if the yank head before leaving is
    " the same as when it returns, and if not add a new entry properly
    " for the previous yank head
    if EasyClip#GetDefaultReg() ==# '*' && exists("s:yankHeadBeforeFocusLost")

        " Ignore the system clipboard if we just replaced the entire clipboard above
        " since our cached yank stack head is no longer valid
        if !didLoad
            let newYankHead = @*

            " If the clipboard contains binary information then 'newYankHead' will be empty
            " Restore old yank in this case
            if s:yankHeadBeforeFocusLost.text !=# newYankHead
                " User copied something externally
                call s:AddToTail(s:yankHeadBeforeFocusLost)
                EasyClipOnYanksChanged
            endif
        endif

        unlet s:yankHeadBeforeFocusLost
    endif
endfunction

function! EasyClip#Yank#Init()

    if g:EasyClipUseYankDefaults
        call EasyClip#Yank#SetDefaultMappings()
    endif

    " Watch focus to keep the shared clipboard in sync for use by other
    " vim sessions
    augroup _easyclip_focuswatch
        au!
        autocmd FocusGained * call EasyClip#Yank#OnFocusGained()
        autocmd FocusLost * call EasyClip#Yank#OnFocusLost()
    augroup END
endfunction

