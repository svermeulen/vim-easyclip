
function! EasyClip#BlackHole#AddSelectBindings()

    let i = 33

    " Add a map for every printable character to copy to black hole register
    " I see no easier way to do this
    while i <= 126
        if i !=# 124
            let char = nr2char(i)
            exec 'snoremap '. char .' <c-o>"_c'. char
        endif

        let i = i + 1
    endwhile

    snoremap <space> <c-o>"_c<space>
    snoremap \| <c-o>"_c|
endfunction

function! EasyClip#BlackHole#AddDefaultBindings()

    let bindings = 
    \ [
    \   ['d', '"_d', 'nx'],
    \   ['dd', '"_dd', 'n'],
    \   ['dD', '0"_d$', 'n'],
    \   ['x', '"_x', 'nx'],
    \   ['c', '"_c', 'nx'],
    \   ['cc', '"_S', 'n'],
    \   ['s', '"_s', 'nx'],
    \   ['S', '"_S', 'nx'],
    \   ['C', '"_C', 'nx'],
    \   ['D', '"_D', 'nx'],
    \ ]

    for binding in bindings
        call call("EasyClip#AddWeakMapping", binding)
    endfor

endfunction

function! EasyClip#BlackHole#Init()

    if g:EasyClipEnableBlackHoleRedirect
        call EasyClip#BlackHole#AddDefaultBindings()

        call EasyClip#BlackHole#AddSelectBindings()
    endif
endfunction
