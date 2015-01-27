scriptencoding utf-8

" Thanks https://github.com/vim-scripts/YankRing.vim/blob/a884f3a161fa3cd8c996eb53a3d1c68631f60c21/plugin/yankring.vim#L273
let s:newLinePattern            = '@@@'
let s:newLinePatternRegexp      = '\%(\\\)\@<!@@@'

function! EasyClip#Shared#SaveSharedYanks()
    if !g:EasyClipShareYanks
        return
    endif

    let l:yankstackStrings = []

    for yankStackItem in [EasyClip#Yank#GetYankstackHead()] + s:yankstackTail
        let l:yankstackItemCopy = yankStackItem
        let l:yankstackItemCopy.text = substitute(yankStackItem.text, "\n", s:newLinePattern, 'g')
        call add(l:yankstackStrings, string(l:yankstackItemCopy))
    endfor

    " Thanks https://github.com/xolox/vim-misc/blob/master/autoload/xolox/misc/list.vim
    " Remove duplicate values from the given list in-place (preserves order).
    call reverse(l:yankstackStrings)
    call filter(l:yankstackStrings, 'count(l:yankstackStrings, v:val) == 1')
    let l:yankstackStrings = reverse(l:yankstackStrings)

    let fileWriteStatus = writefile(l:yankstackStrings, s:shareYanksFile)
    if fileWriteStatus != 0
        echohl ErrorMsg
        echo 'Failed to save EasyClip stack'
        echohl None
    endif
endfunction

function! EasyClip#Shared#LoadSharedYanks()
    if !g:EasyClipShareYanks
        return
    endif

    for dir in split(g:EasyClipShareYanksDirectory, ",")
        if isdirectory(expand(dir))
            let g:EasyClipShareYanksDirectory = expand(dir)
            break
        endif
    endfor
    let s:shareYanksFile = g:EasyClipShareYanksDirectory . '/' . g:EasyClipShareYanksFile

    if filereadable(s:shareYanksFile)
        let l:allYanksFileContent = readfile(s:shareYanksFile)
        let l:allYanks = []
        for allYanksFileContentLine in l:allYanksFileContent
            let l:allYanksItem = eval(allYanksFileContentLine)
            let l:allYanksItem.text = substitute(l:allYanksItem.text, s:newLinePatternRegexp, "\n", 'g')
            call add(l:allYanks, l:allYanksItem)
        endfor

        if len(l:allYanks)
            call EasyClip#Yank#SetYankStackHead(remove(l:allYanks, 0))
            let s:yankstackTail = l:allYanks
        endif
    endif
endfunction

function! EasyClip#Shared#InitSharedYanks()
    call EasyClip#Shared#LoadSharedYanks()
endfunction

function! EasyClip#Shared#Init()
    if g:EasyClipShareYanks
        call EasyClip#Shared#InitSharedYanks()
    endif
endfunction


