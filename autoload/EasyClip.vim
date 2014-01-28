
"""""""""""""""""""""""
" Global Options
"""""""""""""""""""""""
let g:EasyClipYankHistorySize = get(g:, 'EasyClipYankHistorySize', 50)
let g:EasyClipAutoFormat = get(g:, 'EasyClipAutoFormat', 0)
let g:EasyClipEnableBlackHoleRedirect = get(g:, 'EasyClipEnableBlackHoleRedirect', 1)
let g:EasyClipUseCutDefaults = get(g:, 'EasyClipUseCutDefaults', 1)
let g:EasyClipUseSubstituteDefaults = get(g:, 'EasyClipUseSubstituteDefaults', 0)
let g:EasyClipUsePasteToggleDefaults = get(g:, 'EasyClipUsePasteToggleDefaults', 1)
let g:EasyClipUsePasteDefaults = get(g:, 'EasyClipUsePasteDefaults', 1)
let g:EasyClipAlwaysMoveCursorToEndOfPaste = get(g:, 'EasyClipAlwaysMoveCursorToEndOfPaste', 0)
let g:EasyClipUseYankDefaults = get(g:, 'EasyClipUseYankDefaults', 1)
let g:EasyClipDoSystemSync = get(g:, 'EasyClipDoSystemSync', 1)
let g:EasyClipPreserveCursorPositionAfterYank = get(g:, 'EasyClipPreserveCursorPositionAfterYank', 0)

let g:EasyClipEnableBlackHoleRedirectForChangeOperator = get(g:, 'EasyClipEnableBlackHoleRedirectForChangeOperator', 1)
let g:EasyClipEnableBlackHoleRedirectForDeleteOperator = get(g:, 'EasyClipEnableBlackHoleRedirectForDeleteOperator', 1)
let g:EasyClipEnableBlackHoleRedirectForSelectOperator = get(g:, 'EasyClipEnableBlackHoleRedirectForSelectOperator', 1)

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
endfunction

function! EasyClip#Yank(str)
    EasyClipBeforeYank
    exec "let @". EasyClip#GetDefaultReg() . "='". a:str . "'"
endfunction

function! EasyClip#Init()

    call EasyClip#Paste#Init()
    call EasyClip#Move#Init()
    call EasyClip#Substitute#Init()
    call EasyClip#Yank#Init()

    " Add black hole bindings last so that it only
    " adds bindings if they are not taken
    call EasyClip#BlackHole#Init()
endfunction
