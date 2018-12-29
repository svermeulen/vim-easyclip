
"""""""""""""""""""""""
" Variables
"""""""""""""""""""""""
let s:activeRegister = EasyClip#GetDefaultReg()

"""""""""""""""""""""""
" Plugs
"""""""""""""""""""""""
nnoremap <silent> <plug>MoveMotionEndOfLinePlug :<c-u>EasyClipBeforeYank<cr>y$:EasyClipOnYanksChanged<cr>"_d$:call repeat#set("\<plug>MoveMotionEndOfLinePlug")<cr>
nnoremap <silent> <plug>MoveMotionReplaceLinePlug :<c-u>EasyClipBeforeYank<cr>0y$:EasyClipOnYanksChanged<cr>"_d$:call repeat#set("\<plug>MoveMotionReplaceLinePlug")<cr>
nnoremap <silent> <expr> <plug>MoveMotionLinePlug ':<c-u>EasyClipBeforeYank<cr>'. v:count .'yy'. v:count . '"_dd:EasyClipOnYanksChanged<cr>:call repeat#set("\<plug>MoveMotionLinePlug")<cr>'
xnoremap <silent> <plug>MoveMotionXPlug :<c-u>call <sid>VisualModeMoveMotion(v:register)<cr>
nnoremap <silent> <expr> <plug>MoveMotionPlug ":<c-u>call EasyClip#Move#PreMoveMotion()<cr>:set opfunc=EasyClip#Move#MoveMotion<cr>" . (v:count > 0 ? v:count : '') . "g@"

"""""""""""""""""""""""
" Functions
"""""""""""""""""""""""
function! s:VisualModeMoveMotion(reg)

    if a:reg == EasyClip#GetDefaultReg() || g:EasyClipCopyExplicitRegisterToDefault
        EasyClipBeforeYank
        normal! gvy
        normal! gv"_d
        EasyClipOnYanksChanged

        if g:EasyClipCopyExplicitRegisterToDefault
            call EasyClip#Yank#SetRegToYankInfo(a:reg, EasyClip#Yank#GetYankstackHead())
        endif
    else
        let oldDefaultInfo = EasyClip#Yank#GetYankstackHead()
        " If register is specified explicitly then do not change default register
        " or add to yank history
        exec "normal! gv\"" . a:reg . "y"
        normal! gv"_d
        call EasyClip#Yank#SetYankStackHead(oldDefaultInfo)
    endif
endfunction

function! EasyClip#Move#PreMoveMotion( )
    let s:activeRegister = v:register

    " This is necessary to get around a bug in vim where the active register persists to
    " the next command. Repro by doing "_d and then a command that uses v:register
    if s:activeRegister ==# "_"
        let s:activeRegister = EasyClip#GetDefaultReg( )
    endif
endfunction

function! EasyClip#Move#MoveMotion(type)
    let oldSelection = &selection
    let &selection = 'inclusive'

    let oldVisualStart = getpos("'<")
    let oldVisualEnd = getpos("'>")
    let visualStart = getpos("'[")
    let visualEnd = getpos("']")

    let newType = a:type

    if newType ==# 'char'
        let numColumnsFirstLine = col([visualStart[1], '^'])
        let numColumnsLastLine = col([visualEnd[1], '$'])

        if visualStart[1] != visualEnd[1] && visualStart[2] == numColumnsFirstLine+1 && visualEnd[2] == numColumnsLastLine-1
            let newType = 'line'
        endif
    endif

    call EasyClip#Yank#_YankLastChangedText(newType, s:activeRegister)

    exe "keepjumps normal! `[" . (newType ==# 'line' ? 'V' : 'v')
                \ . "`]\"_d"

    call setpos("'<", oldVisualStart)
    call setpos("'>", oldVisualEnd)

    let &selection = oldSelection
endfunction

function! EasyClip#Move#SetDefaultBindings()

    let bindings =
    \ [
    \   ['m',  '<Plug>MoveMotionPlug',  'n',  1],
    \   ['mm',  '<Plug>MoveMotionLinePlug',  'n',  1],
    \   ['m',  '<Plug>MoveMotionXPlug',  'x',  1],
    \ ]

    " Leave these commented to avoid shadowing M (go to middle of screen)
    "\   ['M',  '<Plug>MoveMotionEndOfLinePlug',  'n',  1],
    "\   ['mM',  '<Plug>MoveMotionReplaceLinePlug',  'n',  1],

    for binding in bindings
        call call("EasyClip#AddWeakMapping", binding)
    endfor
endfunction

function! EasyClip#Move#Init()

    if g:EasyClipUseCutDefaults
        call EasyClip#Move#SetDefaultBindings()
    endif
endfunction
