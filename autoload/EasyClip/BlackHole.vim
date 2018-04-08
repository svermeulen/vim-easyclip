
function! EasyClip#BlackHole#AddSelectBindings()

    let i = 33

    " Add a map for every printable character to copy to black hole register
    " I see no easier way to do this
    while i <= 126
        if i !=# 124
            let char = nr2char(i)
            if i ==# 92
              let char = '\\'
            endif
            exec 'snoremap '. char .' <c-o>"_c'. char
        endif

        let i = i + 1
    endwhile

    snoremap <bs> <c-o>"_c
    snoremap <space> <c-o>"_c<space>
    snoremap \| <c-o>"_c|
endfunction

function! EasyClip#BlackHole#AddDeleteBindings()

    let bindings =
    \ [
    \   ['d', '"_d', 'nx'],
    \   ['dd', '"_dd', 'n'],
    \   ['dD', '0"_d$', 'n'],
    \   ['D', '"_D', 'nx'],
    \   ['x', '"_x', 'nx'],
    \   ['X', '"_X', 'nx'],
    \ ]

    for binding in bindings
        call call("EasyClip#AddWeakMapping", binding)
    endfor
endfunction

function! EasyClip#BlackHole#AddChangeBindings()

    let bindings =
    \ [
    \   ['c', '"_c', 'nx'],
    \   ['cc', '"_S', 'n'],
    \   ['C', '"_C', 'nx'],
    \   ['s', '"_s', 'nx'],
    \   ['S', '"_S', 'nx'],
    \ ]

    for binding in bindings
        call call("EasyClip#AddWeakMapping", binding)
    endfor
endfunction

function! EasyClip#BlackHole#Init()

    if g:EasyClipEnableBlackHoleRedirect

        if g:EasyClipEnableBlackHoleRedirectForChangeOperator
            call EasyClip#BlackHole#AddChangeBindings()
        endif

        if g:EasyClipEnableBlackHoleRedirectForDeleteOperator
            call EasyClip#BlackHole#AddDeleteBindings()
        endif

        if g:EasyClipEnableBlackHoleRedirectForSelectOperator
            call EasyClip#BlackHole#AddSelectBindings()
        endif
    endif
endfunction
