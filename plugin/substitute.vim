
let s:activeRegister = easyclip#GetDefaultReg()
let s:moveCursor = 0

function! s:OnPreSubstitute(register, moveCursor)
    let s:activeRegister = a:register

    " This is necessary to get around a bug in vim where the active register persists to
    " the next command. Repro by doing "_d and then a command that uses v:register
    if a:register == "_"
        let s:activeRegister = easyclip#GetDefaultReg()
    endif

    let s:moveCursor = a:moveCursor
endfunction

function! s:SubstituteMotion(type, ...)

    let startPos = getpos('.')

    if &selection ==# 'exclusive'
      let excl_right = "\<right>"
    else
      let excl_right = ""
    endif

    if a:type ==# 'line'
        exe "normal! '[V']".excl_right
    elseif a:type ==# 'char'
        exe "normal! `[v`]".excl_right
    else
        echom "Unexpected selection type"
        return
    endif

    let reg = s:activeRegister

    " Necessary for the case where we substitute to the end of the line 
    let oldVirtualEdit=&virtualedit
    set virtualedit+=onemore

    exe "normal! \"_d"
    " Use our own version of paste so it autoformats and positions the cursor correctly
    call g:EasyClipPaste("P", 1, reg)

    exec 'set virtualedit='.oldVirtualEdit

    if !s:moveCursor
        call setpos('.', startPos)
        " For some reason this is necessary otherwise doing gS and then hitting 'j' does not work as you'd expect (jumps to end of next line)
        normal! hl
    end
endfunction

" For some reason I couldn't get this to work without defining it as a function
function! s:SubstituteLine(reg, keepNewLine)
    let isOnLastLine = (line(".") == line("$"))

    if a:keepNewLine
        exec "normal! 0\"_d$"
    else
        exe "normal! \"_dd"
    endif

    " Use our own version of paste so it autoformats and positions the cursor correctly
    call g:EasyClipPaste((isOnLastLine ? "p" : "P"), 1, a:reg)
endfunction

function! s:SubstituteToEndOfLine(reg, moveCursor)
    let startPos = getpos('.')
    exec "normal! \"_d$"

    " Use our own version of paste so it autoformats and positions the cursor correctly
    call g:EasyClipPaste("p", 1, a:reg)

    if !a:moveCursor
        call setpos('.', startPos)
    endif
endfunction

nnoremap <plug>SubstituteOverMotionMap :<c-u>call <sid>OnPreSubstitute(v:register, 1)<cr>:set opfunc=<sid>SubstituteMotion<cr>g@
nnoremap <plug>G_SubstituteOverMotionMap :<c-u>call <sid>OnPreSubstitute(v:register, 0)<cr>:set opfunc=<sid>SubstituteMotion<cr>g@

nnoremap <plug>SubstituteToEndOfLine :call <sid>SubstituteToEndOfLine(v:register, 1)<cr>:call repeat#set("\<plug>SubstituteToEndOfLine")<cr>
nnoremap <plug>G_SubstituteToEndOfLine :call <sid>SubstituteToEndOfLine(v:register, 0)<cr>:call repeat#set("\<plug>G_SubstituteToEndOfLine")<cr>

nnoremap <plug>NoNewlineSubstituteLine :call <sid>SubstituteLine(v:register, 1)<cr>
nnoremap <plug>SubstituteLine :call <sid>SubstituteLine(v:register, 0)<cr>

if !exists('g:EasyClipUseSubstituteDefaults') || g:EasyClipUseSubstituteDefaults

    " Make the s key more useful, paste over a given motion
    nmap <silent> s <plug>SubstituteOverMotionMap
    nmap <silent> gs <plug>G_SubstituteOverMotionMap

    if !exists('g:EasyClipRemapCapitals') || g:EasyClipRemapCapitals
        nmap <silent> S <plug>SubstituteToEndOfLine
        nmap <silent> gS <plug>G_SubstituteToEndOfLine
    endif

    nmap ss <plug>SubstituteLine
    nmap sS <plug>NoNewlineSubstituteLine

    xmap s p
endif
