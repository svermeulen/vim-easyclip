
"""""""""""""""""""""""
" Variables
"""""""""""""""""""""""

" This is made global because it's changed in paste.vim
let g:lastSubChangedtick = -1

let s:activeRegister = EasyClip#GetDefaultReg()
let s:moveCursor = 0

"""""""""""""""""""""""
" Plugs
"""""""""""""""""""""""
nnoremap <silent> <plug>SubstituteOverMotionMap :<c-u>call EasyClip#Substitute#OnPreSubstitute(v:register, 1)<cr>:set opfunc=EasyClip#Substitute#SubstituteMotion<cr>g@
nnoremap <silent> <plug>G_SubstituteOverMotionMap :<c-u>call EasyClip#Substitute#OnPreSubstitute(v:register, 0)<cr>:set opfunc=EasyClip#Substitute#SubstituteMotion<cr>g@

nnoremap <silent> <plug>SubstituteToEndOfLine :<c-u>call EasyClip#Substitute#SubstituteToEndOfLine(v:register, 1)<cr>:call repeat#set("\<plug>SubstituteToEndOfLine")<cr>
nnoremap <silent> <plug>G_SubstituteToEndOfLine :<c-u>call EasyClip#Substitute#SubstituteToEndOfLine(v:register, 0)<cr>:call repeat#set("\<plug>G_SubstituteToEndOfLine")<cr>

nnoremap <silent> <plug>SubstituteLine :<c-u>call EasyClip#Substitute#SubstituteLine(v:register, v:count)<cr>:call repeat#set("\<plug>SubstituteLine")<cr>

"""""""""""""""""""""""
" Functions
"""""""""""""""""""""""
function! EasyClip#Substitute#OnPreSubstitute(register, moveCursor)
    let s:activeRegister = a:register

    " This is necessary to get around a bug in vim where the active register persists to
    " the next command. Repro by doing "_d and then a command that uses v:register
    if a:register == "_"
        let s:activeRegister = EasyClip#GetDefaultReg()
    endif

    let s:moveCursor = a:moveCursor
endfunction

function! EasyClip#Substitute#SubstituteMotion(type, ...)

    let startPos = getpos('.')

    if &selection ==# 'exclusive'
        let excl_right = "\<right>"
    else
        let excl_right = ""
    endif

    let oldVirtualEdit=&virtualedit
    set virtualedit=onemore

    " use keepjumps since we only want to change jumplist
    " if it's multiline
    if a:type ==# 'line'
        exe "keepjump normal! '[V']".excl_right
    elseif a:type ==# 'char'
        exe "keepjump normal! `[v`]".excl_right
    else
        echom "Unexpected selection type"
        exec "set virtualedit=". oldVirtualEdit
        return
    endif

    let reg = s:activeRegister

    if (getreg(reg) =~# "\n")
        if s:moveCursor
            " Record the start of the substitution to the jump list
            exec "normal! m`"
        endif
    endif

    " Using "c" change doesn't work correctly for multiline,
    " Adds an extra line at the end, so delete instead
    exe "normal! \"_d"

    " Use our own version of paste so it autoformats and positions the cursor correctly
    call EasyClip#Paste#Paste("P", 1, reg, 0)
    exec "set virtualedit=". oldVirtualEdit

    let g:lastSubChangedtick = b:changedtick

    if !s:moveCursor
        call setpos('.', startPos)

        " For some reason this is necessary otherwise doing gS and then hitting 'j' does not work as you'd expect (jumps to end of next line)
        normal! hl
    end
endfunction

function! EasyClip#Substitute#SubstituteLine(reg, count)

    " Check for black hole register to get around a bug in vim where the active
    " register persists to the next command
    let reg = (a:reg == "_" ? EasyClip#GetDefaultReg() : a:reg)

    if getreg(reg) !~ '\n'

        exec "normal! 0\"_d$"
        " Use our own version of paste so it autoformats and positions the cursor correctly
        call EasyClip#Paste#Paste("P", 1, reg, 0)
    else
        let isLastLine = (line(".") == line("$"))

        let cnt = a:count > 0 ? a:count : 1
        exe "normal! ". cnt . "\"_dd"

        let i = 0
        while i < cnt
            " Use our own version of paste so it autoformats and positions the cursor correctly
            call EasyClip#Paste#Paste(isLastLine ? "p" : "P", 1, reg, 0)

            let i = i + 1
        endwhile
    endif

    let g:lastSubChangedtick = b:changedtick
endfunction

function! EasyClip#Substitute#SubstituteToEndOfLine(reg, moveCursor)
    let startPos = getpos('.')
    exec "normal! \"_d$"

    " Use our own version of paste so it autoformats and positions the cursor correctly
    call EasyClip#Paste#Paste("p", 1, a:reg, 0)

    if !a:moveCursor
        call setpos('.', startPos)
    endif
endfunction

function! EasyClip#Substitute#SetDefaultBindings()

    let bindings =
    \ [
    \   ['s',  '<plug>SubstituteOverMotionMap',  'n',  1],
    \   ['gs',  '<plug>G_SubstituteOverMotionMap',  'n',  1],
    \   ['ss',  '<plug>SubstituteLine',  'n',  1],
    \   ['s',  '<plug>XEasyClipPaste',  'x',  1],
    \   ['S',  '<plug>SubstituteToEndOfLine',  'n',  1],
    \   ['gS',  '<plug>G_SubstituteToEndOfLine',  'n',  1],
    \ ]

    for binding in bindings
        call call("EasyClip#AddWeakMapping", binding)
    endfor
endfunction

function! EasyClip#Substitute#Init()

    if g:EasyClipUseSubstituteDefaults
        call EasyClip#Substitute#SetDefaultBindings()
    endif
endfunction
