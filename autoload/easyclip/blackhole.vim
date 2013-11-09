
function! easyclip#blackhole#AddSelectBindings()

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

function! easyclip#blackhole#AddDefaultBindings()

    nnoremap d "_d
    nnoremap dd "_dd

    nnoremap dD 0"_d$

    noremap x "_x
    xnoremap x "_x

    xnoremap d "_d

    nnoremap c "_c
    xnoremap c "_c

    " This is more consistent with yy and dd
    nnoremap cc "_S

    if g:EasyClipRemapCapitals
        nnoremap C "_C
        xnoremap C "_C

        nnoremap D "_d$
        xnoremap D <nop>
    endif
endfunction

function! easyclip#blackhole#Init()

    if g:EasyClipEnableBlackHoleRedirect
        call easyclip#blackhole#AddDefaultBindings()

        call easyclip#blackhole#AddSelectBindings()
    endif
endfunction
