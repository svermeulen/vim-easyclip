
"""""""""""""""""""""""
" Variables
"""""""""""""""""""""""

" This made global because it's changed in paste.vim
let g:lastSubChangedtick = -1

let s:activeRegister = easyclip#GetDefaultReg()
let s:moveCursor = 0

"""""""""""""""""""""""
" Plugs
"""""""""""""""""""""""
nnoremap <plug>SubstituteOverMotionMap :<c-u>call easyclip#substitute#OnPreSubstitute(v:register, 1)<cr>:set opfunc=easyclip#substitute#SubstituteMotion<cr>g@
nnoremap <plug>G_SubstituteOverMotionMap :<c-u>call easyclip#substitute#OnPreSubstitute(v:register, 0)<cr>:set opfunc=easyclip#substitute#SubstituteMotion<cr>g@

nnoremap <plug>SubstituteToEndOfLine :<c-u>call easyclip#substitute#SubstituteToEndOfLine(v:register, 1)<cr>:call repeat#set("\<plug>SubstituteToEndOfLine")<cr>
nnoremap <plug>G_SubstituteToEndOfLine :<c-u>call easyclip#substitute#SubstituteToEndOfLine(v:register, 0)<cr>:call repeat#set("\<plug>G_SubstituteToEndOfLine")<cr>

nnoremap <plug>SubstituteLine :<c-u>call easyclip#substitute#SubstituteLine(v:register, v:count)<cr>:call repeat#set("\<plug>SubstituteLine")<cr>

"""""""""""""""""""""""
" Functions
"""""""""""""""""""""""
function! easyclip#substitute#OnPreSubstitute(register, moveCursor)
    let s:activeRegister = a:register

    " This is necessary to get around a bug in vim where the active register persists to
    " the next command. Repro by doing "_d and then a command that uses v:register
    if a:register == "_"
        let s:activeRegister = easyclip#GetDefaultReg()
    endif

    let s:moveCursor = a:moveCursor
endfunction

function! easyclip#substitute#SubstituteMotion(type, ...)

    let startPos = getpos('.')

    if &selection ==# 'exclusive'
      let excl_right = "\<right>"
    else
      let excl_right = ""
    endif

    " use keepjumps since we only want to change jumplist
    " if it's multiline
    if a:type ==# 'line'
        exe "keepjump normal! '[V']".excl_right
    elseif a:type ==# 'char'
        exe "keepjump normal! `[v`]".excl_right
    else
        echom "Unexpected selection type"
        return
    endif

    let reg = s:activeRegister

    if (getreg(reg) =~# "\n")

        if s:moveCursor
            " Record the start of the substitution to the jump list
            exec "normal! m`"
        endif

        " Using "c" change doesn't work correctly for multiline,
        " Adds an extra line at the end, so delete instead
        exe "normal! \"_d"

        " Use our own version of paste so it autoformats and positions the cursor correctly, also note: pasting inline
        call easyclip#paste#Paste("P", 1, reg, 1)
    else
        exe "normal! \"_c\<c-r>". reg
    endif

    let g:lastSubChangedtick = b:changedtick

    if !s:moveCursor
        call setpos('.', startPos)

        " For some reason this is necessary otherwise doing gS and then hitting 'j' does not work as you'd expect (jumps to end of next line)
        normal! hl
    end
endfunction

function! easyclip#substitute#SubstituteLine(reg, count)
    if getreg(a:reg) !~ '\n'

        exec "normal! 0\"_d$"
        " Use our own version of paste so it autoformats and positions the cursor correctly
        call easyclip#paste#Paste("P", 1, a:reg, 0)
    else
        let isLastLine = (line(".") == line("$"))

        let cnt = a:count > 0 ? a:count : 1 
        exe "normal! ". cnt . "\"_dd"

        let i = 0
        while i < cnt
            " Use our own version of paste so it autoformats and positions the cursor correctly
            call easyclip#paste#Paste(isLastLine ? "p" : "P", 1, a:reg, 0)

            let i = i + 1
        endwhile
    endif

    let g:lastSubChangedtick = b:changedtick
endfunction

function! easyclip#substitute#SubstituteToEndOfLine(reg, moveCursor)
    let startPos = getpos('.')
    exec "normal! \"_d$"

    " Use our own version of paste so it autoformats and positions the cursor correctly
    call easyclip#paste#Paste("p", 1, a:reg, 0)

    if !a:moveCursor
        call setpos('.', startPos)
    endif
endfunction

function! easyclip#substitute#SetDefaultBindings()

    " Make the s key more useful, paste over a given motion
    nmap <silent> s <plug>SubstituteOverMotionMap
    nmap <silent> gs <plug>G_SubstituteOverMotionMap

    if g:EasyClipRemapCapitals
        nmap <silent> S <plug>SubstituteToEndOfLine
        nmap <silent> gS <plug>G_SubstituteToEndOfLine
    endif

    nmap ss <plug>SubstituteLine
    xmap s p
endfunction

function! easyclip#substitute#Init()

    if g:EasyClipUseSubstituteDefaults
        call easyclip#substitute#SetDefaultBindings()
    endif
endfunction
