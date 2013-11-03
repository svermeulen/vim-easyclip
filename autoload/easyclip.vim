
"""""""""""""""""""""""
" Global Options
" By default easy clip does nothing
"""""""""""""""""""""""
let g:EasyClipYankHistorySize = get(g:, 'EasyClipYankHistorySize', 30)
let g:EasyClipAutoFormat = get(g:, 'EasyClipAutoFormat', 0)
let g:EasyClipRemapCapitals = get(g:, 'EasyClipRemapCapitals', 0)
let g:EasyClipEnableBlackHoleRedirect = get(g:, 'EasyClipEnableBlackHoleRedirect', 0)
let g:EasyClipUseCutDefaults = get(g:, 'EasyClipUseCutDefaults', 0)
let g:EasyClipRemapCapitals = get(g:, 'EasyClipRemapCapitals', 0)
let g:EasyClipUseSubstituteDefaults = get(g:, 'EasyClipUseSubstituteDefaults', 0)
let g:EasyClipUsePasteToggleDefaults = get(g:, 'EasyClipUsePasteToggleDefaults', 0)
let g:EasyClipUsePasteDefaults = get(g:, 'EasyClipUsePasteDefaults', 0)
let g:EasyClipUseYankDefaults = get(g:, 'EasyClipUseYankDefaults', 0)
let g:EasyClipDoSystemSync = get(g:, 'EasyClipDoSystemSync', 0)
let g:EasyClipEnableInsertModePaste = get(g:, 'EasyClipEnableInsertModePaste', 0)

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

function! easyclip#Yank(str)
    EasyClipBeforeYank
    exec "let @". easyclip#GetDefaultReg() . "='". a:str . "'"
endfunction

function! easyclip#Init()

    call easyclip#paste#Init()
    call easyclip#blackhole#Init()
    call easyclip#move#Init()
    call easyclip#substitute#Init()
    call easyclip#yank#Init()
endfunction
