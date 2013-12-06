
"""""""""""""""""""""""
" Global Options
" By default easy clip does nothing
"""""""""""""""""""""""
let g:EasyClipYankHistorySize = get(g:, 'EasyClipYankHistorySize', 50)
let g:EasyClipAutoFormat = get(g:, 'EasyClipAutoFormat', 0)
let g:EasyClipRemapCapitals = get(g:, 'EasyClipRemapCapitals', 1)
let g:EasyClipEnableBlackHoleRedirect = get(g:, 'EasyClipEnableBlackHoleRedirect', 1)
let g:EasyClipUseCutDefaults = get(g:, 'EasyClipUseCutDefaults', 1)
let g:EasyClipUseSubstituteDefaults = get(g:, 'EasyClipUseSubstituteDefaults', 0)
let g:EasyClipUsePasteToggleDefaults = get(g:, 'EasyClipUsePasteToggleDefaults', 1)
let g:EasyClipUsePasteDefaults = get(g:, 'EasyClipUsePasteDefaults', 1)
let g:EasyClipAlwaysMoveCursorToEndOfPaste = get(g:, 'EasyClipAlwaysMoveCursorToEndOfPaste', 0)
let g:EasyClipUseYankDefaults = get(g:, 'EasyClipUseYankDefaults', 1)
let g:EasyClipDoSystemSync = get(g:, 'EasyClipDoSystemSync', 1)

"""""""""""""""""""""""
" Functions
"""""""""""""""""""""""
function! easyclip#GetDefaultReg()
    let clipboard_flags = split(&clipboard, ',')
    if index(clipboard_flags, 'unnamedplus') >= 0
        return "+"
    elseif index(clipboard_flags, 'unnamed') >= 0
        return "*"
    else
        return "\""
    endif
endfunction

function! easyclip#GetCurrentYank()
    return getreg(easyclip#GetDefaultReg())
endfunction

function! easyclip#SetCurrentYank(yank)
    call setreg(easyclip#GetDefaultReg(), a:yank)
endfunction

function! easyclip#Yank(str)
    EasyClipBeforeYank
    exec "let @". easyclip#GetDefaultReg() . "='". a:str . "'"
endfunction

function! easyclip#Init()

    call easyclip#blackhole#Init()
    call easyclip#paste#Init()
    call easyclip#move#Init()
    call easyclip#substitute#Init()
    call easyclip#yank#Init()
endfunction
