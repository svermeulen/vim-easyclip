
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
