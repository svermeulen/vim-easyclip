
"""""""""""""""""""""""
" Global Options
"""""""""""""""""""""""
let g:EasyClipYankHistorySize = get(g:, 'EasyClipYankHistorySize', 50)
let g:EasyClipShowYanksWidth = get(g:, 'EasyClipShowYanksWidth', 80)
let g:EasyClipAutoFormat = get(g:, 'EasyClipAutoFormat', 0)
let g:EasyClipEnableBlackHoleRedirect = get(g:, 'EasyClipEnableBlackHoleRedirect', 1)
let g:EasyClipUseCutDefaults = get(g:, 'EasyClipUseCutDefaults', 1)
let g:EasyClipUseSubstituteDefaults = get(g:, 'EasyClipUseSubstituteDefaults', 0)
let g:EasyClipUsePasteToggleDefaults = get(g:, 'EasyClipUsePasteToggleDefaults', 1)
let g:EasyClipUsePasteDefaults = get(g:, 'EasyClipUsePasteDefaults', 1)
let g:EasyClipAlwaysMoveCursorToEndOfPaste = get(g:, 'EasyClipAlwaysMoveCursorToEndOfPaste', 0)
let g:EasyClipUseYankDefaults = get(g:, 'EasyClipUseYankDefaults', 1)
let g:EasyClipPreserveCursorPositionAfterYank = get(g:, 'EasyClipPreserveCursorPositionAfterYank', 0)
let g:EasyClipShareYanks = get(g:, 'EasyClipShareYanks', 0)
let g:EasyClipShareYanksFile = get(g:, 'EasyClipShareYanksFile', '.easyclip')
let g:EasyClipShareYanksDirectory = get(g:, 'EasyClipShareYanksDirectory', '$HOME')
let g:EasyClipCopyExplicitRegisterToDefault = get(g:, 'EasyClipCopyExplicitRegisterToDefault', 0)

let g:EasyClipEnableBlackHoleRedirectForChangeOperator = get(g:, 'EasyClipEnableBlackHoleRedirectForChangeOperator', 1)
let g:EasyClipEnableBlackHoleRedirectForDeleteOperator = get(g:, 'EasyClipEnableBlackHoleRedirectForDeleteOperator', 1)
let g:EasyClipEnableBlackHoleRedirectForSelectOperator = get(g:, 'EasyClipEnableBlackHoleRedirectForSelectOperator', 1)

"""""""""""""""""""""""
" Commands
"""""""""""""""""""""""
command! -nargs=0 IPaste call EasyClip#InteractivePaste(0)
command! -nargs=0 IPasteBefore call EasyClip#InteractivePaste(1)
command! -nargs=1 Paste call EasyClip#PasteIndex(<q-args>)
command! -nargs=1 PasteBefore call EasyClip#PasteIndexBefore(<q-args>)
command! EasyClipBeforeYank :call EasyClip#Yank#OnBeforeYank()
command! EasyClipOnYanksChanged :call EasyClip#Yank#OnYanksChanged()
command! -nargs=0 Yanks call EasyClip#Yank#ShowYanks()
command! -nargs=0 ClearYanks call EasyClip#Yank#ClearYanks()

"""""""""""""""""""""""
" Functions
"""""""""""""""""""""""
function! EasyClip#GetDefaultReg()
    let clipboard_flags = split(&clipboard, ',')
    if index(clipboard_flags, 'unnamedplus') >= 0
        return "+"
    elseif index(clipboard_flags, 'unnamed') >= 0
        return "*"
    else
        return "\""
    endif
endfunction

" Only add the given mapping if it doesn't already exist
function! EasyClip#AddWeakMapping(left, right, modes, ...)
    let recursive = a:0 > 0 ? a:1 : 0

    for mode in split(a:modes, '\zs')
        if !EasyClip#HasMapping(a:left, mode)
            exec mode . (recursive ? "map" : "noremap") . " <silent> " . a:left . " " . a:right
        endif
    endfor
endfunction

function! EasyClip#HasMapping(mapping, mode)
    return maparg(a:mapping, a:mode) != ''
endfunction

function! EasyClip#GetCurrentYank()
    return getreg(EasyClip#GetDefaultReg())
endfunction

function! EasyClip#SetCurrentYank(yank)
    call setreg(EasyClip#GetDefaultReg(), a:yank)
    EasyClipOnYanksChanged
endfunction

function! EasyClip#Yank(str)
    EasyClipBeforeYank
    exec "let @". EasyClip#GetDefaultReg() . "='". a:str . "'"
    EasyClipOnYanksChanged
endfunction

function! EasyClip#GetYankAtIndex(index)
    return EasyClip#Yank#GetYankInfoForIndex(a:index).text
endfunction

function! EasyClip#InteractivePaste(pasteBefore)
    echohl WarningMsg | echo "--- Interactive Paste ---" | echohl None
    let i = 0
    for yank in EasyClip#Yank#EasyClipGetAllYanks()
        call EasyClip#Yank#ShowYank(yank, i)
        let i += 1
    endfor

    let indexStr = input('Index: ')

    if indexStr =~ '\v^\s*$'
        return
    endif

    if indexStr !~ '\v^\s*\d+\s*'
        echo "\n"
        echoerr "Invalid yank index given"
    else
        let index = str2nr(indexStr)

        if index < 0 || index > EasyClip#Yank#GetNumYanks()
            echo "\n"
            echoerr "Yank index out of bounds"
        else
            if a:pasteBefore
                call EasyClip#PasteIndexBefore(index)
            else
                call EasyClip#PasteIndex(index)
            endif
        endif
    endif
endfunction

function! EasyClip#PasteIndex(index)
    if a:index == 0
        exec "normal \<plug>EasyClipPasteAfter"
    else
        let oldYankHead = EasyClip#Yank#GetYankstackHead()
        call EasyClip#Yank#SetYankStackHead(EasyClip#Yank#GetYankInfoForIndex(a:index))
        exec "normal \<plug>EasyClipPasteAfter"
        call EasyClip#Yank#SetYankStackHead(oldYankHead)
    endif
endfunction

function! EasyClip#PasteIndexBefore(index)
    if a:index == 0
        exec "normal \<plug>EasyClipPasteBefore"
    else
        let oldYankHead = EasyClip#Yank#GetYankstackHead()
        call EasyClip#Yank#SetYankStackHead(EasyClip#Yank#GetYankInfoForIndex(a:index))
        exec "normal \<plug>EasyClipPasteBefore"
        call EasyClip#Yank#SetYankStackHead(oldYankHead)
    endif
endfunction

function! EasyClip#Init()
    call EasyClip#Paste#Init()
    call EasyClip#Move#Init()
    call EasyClip#Substitute#Init()
    call EasyClip#Yank#Init()
    call EasyClip#Shared#Init()

    " Add black hole bindings last so that it only
    " adds bindings if they are not taken
    call EasyClip#BlackHole#Init()
endfunction
