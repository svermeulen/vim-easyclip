"author: https://github.com/tracyone
"descrition:ctrlp support for easyclip
if ( exists('g:loaded_ctrlp_easyclip') && g:loaded_ctrlp_easyclip ) || v:version < 700 || &cp
  finish
endif
let g:loaded_ctrlp_easyclip = 1

call add(g:ctrlp_ext_vars, {
  \ 'init': 'ctrlp#easyclip#init()',
  \ 'accept': 'ctrlp#easyclip#accept',
  \ 'lname': 'EasyClip',
  \ 'sname': 'EasyClip',
  \ 'type': 'line',
  \ 'sort': 0,
  \ 'specinput': 0,
  \ })

function! ctrlp#easyclip#init() abort
    let l:result=[]
    let i = 0
    for yank in EasyClip#Yank#EasyClipGetAllYanks()
        call add(l:result, EasyClip#Yank#GetYankLine(yank, i))
        let i += 1
    endfor
    return l:result
endfunction

function! ctrlp#easyclip#accept(mode, str) abort
  let l:index=matchstr(a:str, '^\d\+\ze\s')
  if l:index =~ '\v^\s*$'
      call ctrlp#exit()
  endif
  call ctrlp#exit()
  let l:index = str2nr(l:index)

  if l:index < 0 || index > EasyClip#Yank#GetNumYanks()
      echo "\n"
      echoerr "Yank index out of bounds"
  else
    if a:mode ==# 'v'
      call EasyClip#PasteIndexBefore(l:index)
    else
      call EasyClip#PasteIndex(l:index)
    endif
  endif
  echom l:index
endfunction

let s:id = g:ctrlp_builtins + len(g:ctrlp_ext_vars)
function! ctrlp#easyclip#id() abort
  return s:id
endfunction


" vim:nofen:fdl=0:ts=2:sw=2:sts=2
