
let s:activeRegister = easyclip#GetDefaultReg()

nnoremap <silent> <plug>MoveMotionEndOfLinePlug :<c-u>EasyClipBeforeYank<cr>y$"_d$
nnoremap <silent> <plug>MoveMotionReplaceLinePlug :<c-u>EasyClipBeforeYank<cr>0y$"_d$ 
nnoremap <silent> <expr> <plug>MoveMotionLinePlug ':<c-u>EasyClipBeforeYank<cr>'. v:count .'yy'. v:count . '"_dd'
xnoremap <silent> <plug>MoveMotionXPlug :<c-u>EasyClipBeforeYank<cr>gvygv"_d
nnoremap <silent> <plug>MoveMotionPlug :call <sid>PreMoveMotion()<cr>:set opfunc=<sid>MoveMotion<cr>g@

function! s:PreMoveMotion( )
    let s:activeRegister = v:register

    " This is necessary to get around a bug in vim where the active register persists to
    " the next command. Repro by doing "_d and then a command that uses v:register
    if s:activeRegister ==# "_"
        let s:activeRegister = easyclip#GetDefaultReg( )
    endif
endfunction

function! s:MoveMotion(type)

    EasyClipBeforeYank
    let selectType = (a:type ==# 'line' ? "'[V']" : "`[v`]")
    exe "keepjumps normal! ". selectType . "\"".s:activeRegister."y"

    exec "normal! gv"
    exec "normal! \"_d"
endfunction

if !exists('g:EasyClipUseCutDefaults') || g:EasyClipUseCutDefaults

    "" "m" = "move" to a different location
    nmap m <Plug>MoveMotionPlug
    nmap mm <Plug>MoveMotionLinePlug
    xmap m <Plug>MoveMotionXPlug

    " Leave these commented to avoid shadowing M (go to middle of screen)
    "nmap M <Plug>MoveMotionEndOfLinePlug
    "nmap mM <Plug>MoveMotionReplaceLinePlug
endif
