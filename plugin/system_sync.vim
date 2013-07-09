
let s:lastSystemClipboard = ''

function! s:OnFocusLost()
    let s:lastSystemClipboard = @*
endfunction

" Just automatically copy system clipboard to the default
" register
function! s:OnFocusGained()
    if s:lastSystemClipboard !=# @*
        EasyClipBeforeYank
        let s:lastSystemClipboard = @*
        exec 'let @'. easyclip#GetDefaultReg() .' = @*'
    endif
endfunction

" Check whether the system clipboard changed while focus was lost and 
" add it to our yank buffer
augroup _sync_clipboard
    au!
    autocmd FocusGained * call <sid>OnFocusGained()
    autocmd FocusLost * call <sid>OnFocusLost()
augroup END

