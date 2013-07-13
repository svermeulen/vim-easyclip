
let g:EasyClipAutoFormat = get(g:, 'EasyClipAutoFormat', 1)

" Adds the following functionality to paste:
" - add position of cursor before pasting to jumplist
" - optionally auto format, preserving the marks `[ and `] in the process
" - always position the cursor directly after the text for P and p versions
" - do not move the cursor for gp and gP versions
function! g:EasyClipPaste(op, format, reg)

    let text = getreg(a:reg)

    if text ==# ''
        " Necessary to avoid error
        return
    endif

    let isMultiLine = (text =~# "\n")
    let line = getline(".")
    let isEmptyLine = (line =~# '^\s*$')

    " Save their old position to jumplist
    " Except for gp since the cursor pos shouldn't change
    " in that case
    if isMultiLine && a:op ==# 'P'
        " just doing m` doesn't work in this case so do it one line above
        exec "normal! km`j"
    else
        exec "normal! m`"
    endif

    exec "normal! \"".a:reg.a:op

    if (isMultiLine || isEmptyLine) && a:format && g:EasyClipAutoFormat
        " Only auto-format if it's multiline or pasting into an empty line

        keepjumps normal! `]
        let startPos = getpos('.')
        exec "keepjumps normal! `[=`]"
        call setpos('.', startPos)

        " Update the `] register with the end of the formatted text
        " I don't know of any way to get this other than searching for it
        " Go to last line
        let line = getline(".")
        let lastWords = matchstr(text, '\v\n=\s*\zs\p*\ze\n=$')

        if line !~# '^\s*$' && lastWords !=# ''
            let colNo = stridx(line, lastWords)

            if colNo != -1
                let colNo = colNo + len(lastWords)
                call cursor(line('.'), colNo)
            endif
        endif

        normal! m]
    endif

    if a:op ==# 'gp'
        exec "normal! ``"
    endif

    if a:op ==# 'gP'
        exec "keepjumps normal! `["
    endif

    if a:op ==# 'P' || a:op ==# 'p'
        exec "keepjumps normal! `]"
    endif
endfunction

function! s:PasteText(reg, count, op, format, plugName)
    let reg = a:reg

    " This is necessary to get around a bug in vim where the active register persists to
    " the next command. Repro by doing "_d and then a command that uses v:register
    if reg == "_"
        let reg = easyclip#GetDefaultReg()
    end

    let i = 0
    let cnt = a:count > 0 ? a:count : 1 

    while i < cnt
        call g:EasyClipPaste(a:op, a:format, reg)
        let i = i + 1
    endwhile

    call repeat#set("\<plug>". a:plugName, a:count)
endfunction

" Change to use the same paste routine above when pasting things in insert mode
function! g:EasyClipInsertModePaste(reg)
    let op = (col(".") == (strlen(getline("."))+1)) ? "p" : "P"

    call g:EasyClipPaste(op, 1, a:reg)
    return "\<right>"
endfunction

" Make sure paste works the same in insert mode
function! s:FixInsertModePaste()

    let registers = '1234567890abcdefghijklmnopqrstuvwxyz*'

    for i in range(strlen(registers))
        let chr = strpart(registers, i, 1)
        exec "inoremap <c-r>".chr ." <c-r>=g:EasyClipInsertModePaste('". chr ."')<cr>"
    endfor
endfunction

" Our Paste options are:
" p - paste after newline if multiline, paste after character if non-multiline
" P - paste before newline if multiline, paste before character if non-multiline
" gp - same as p but keep old cursor position
" gP - same as P but keep old cursor position
" <c-p> - same as p but does not auto-format
" <c-s-p> - same as P but does not auto-format
" g<c-p> - same as c-p but keeps cursor position
" g<c-P> - same as c-p but keeps cursor position
nnoremap <silent> <plug>EasyClipPasteAfter :<c-u>call <sid>PasteText(v:register, v:count, 'p', 1, "EasyClipPasteAfter")<cr>
nnoremap <silent> <plug>EasyClipPasteBefore :<c-u>call <sid>PasteText(v:register, v:count, 'P', 1, "EasyClipPasteBefore")<cr>
xnoremap <silent> <plug>XEasyClipPaste "_d:<c-u>call <sid>PasteText(v:register, v:count, 'P', 1, "EasyClipPasteBefore")<cr>

nnoremap <silent> <plug>G_EasyClipPasteAfter :<c-u>call <sid>PasteText(v:register, v:count, 'gp', 1, "G_EasyClipPasteAfter")<cr>
nnoremap <silent> <plug>G_EasyClipPasteBefore :<c-u>call <sid>PasteText(v:register, v:count, 'gP', 1, "G_EasyClipPasteBefore")<cr>
xnoremap <silent> <plug>XG_EasyClipPaste "_d:<c-u>call <sid>PasteText(v:register, v:count, 'gP', 1, "G_EasyClipPasteBefore")<cr>

nnoremap <silent> <plug>EasyClipPasteUnformattedAfter :<c-u>call <sid>PasteText(v:register, v:count, 'p', 0, "EasyClipPasteUnformattedAfter")<cr>
nnoremap <silent> <plug>EasyClipPasteUnformattedBefore :<c-u>call <sid>PasteText(v:register, v:count, 'P', 0, "EasyClipPasteUnformattedBefore")<cr>
nnoremap <silent> <plug>XEasyClipPasteUnformatted "_d:<c-u>call <sid>PasteText(v:register, v:count, 'P', 0, "EasyClipPasteUnformattedBefore")<cr>

nnoremap <silent> <plug>G_EasyClipPasteUnformattedAfter :<c-u>call <sid>PasteText(v:register, v:count, 'gp', 0, "G_EasyClipPasteUnformattedAfter")<cr>
nnoremap <silent> <plug>G_EasyClipPasteUnformattedBefore :<c-u>call <sid>PasteText(v:register, v:count, 'gP', 0, "G_EasyClipPasteUnformattedBefore")<cr>
xnoremap <silent> <plug>XG_EasyClipPasteUnformatted "_d:<c-u>call <sid>PasteText(v:register, v:count, 'gP', 0, "G_EasyClipPasteUnformattedBefore")<cr>

call s:FixInsertModePaste()

if !exists('g:EasyClipUsePasteDefaults') || g:EasyClipUsePasteDefaults

    xmap p <plug>XEasyClipPaste
    xmap P <plug>XEasyClipPaste

    xmap gp <plug>XG_EasyClipPaste
    xmap gP <plug>XG_EasyClipPaste

    xmap <c-p> <plug>XEasyClipPasteUnformatted
    xmap g<c-p> <plug>XG_EasyClipPasteUnformatted

    nmap P <plug>EasyClipPasteBefore
    nmap p <plug>EasyClipPasteAfter
    nmap gp <plug>G_EasyClipPasteAfter
    nmap gP <plug>G_EasyClipPasteBefore

    " We need to map <c-s-p> to <c-end> using autohotkey since vim doesn't support it
    nmap <c-p> <plug>EasyClipPasteUnformattedAfter
    nmap g<c-p> <plug>G_EasyClipPasteUnformattedAfter
endif

