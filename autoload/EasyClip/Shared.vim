scriptencoding utf-8

" Thanks https://github.com/vim-scripts/YankRing.vim/blob/a884f3a161fa3cd8c996eb53a3d1c68631f60c21/plugin/yankring.vim#L273
let s:newLinePattern              = "\2"
let s:newLinePatternRegexp        = "\2"
let s:shareYanksFile              = ''
let s:mostRecentYanksFileReadTime = 0

function! EasyClip#Shared#SaveToFileIfDirty()
    if !g:EasyClipShareYanks
        return
    endif

    let l:yankstackStrings = []

    for yankStackItem in [EasyClip#Yank#GetYankstackHead()] + EasyClip#Yank#GetYankstackTail()
        let l:yankstackItemCopy = { 'text': yankStackItem.text, 'type': yankStackItem.type }
        let l:yankstackItemCopy.text = substitute(l:yankstackItemCopy.text, "\n", s:newLinePattern, 'g')
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
        echo 'Failed to save EasyClip yank stack'
        echohl None
        return
    endif

    let s:mostRecentYanksFileReadTime = getftime(s:shareYanksFile)
endfunction

function! EasyClip#Shared#LoadFileIfChanged()
    if !g:EasyClipShareYanks
        return 0
    endif

    if !filereadable(s:shareYanksFile)
        return 0
    endif

    " Only read in yanks from disk if the file has been modified since
    " last read
    let l:currentYanksFileModificationTime = getftime(s:shareYanksFile)
    if l:currentYanksFileModificationTime <= s:mostRecentYanksFileReadTime
        return 0
    endif

    let s:mostRecentYanksFileReadTime = l:currentYanksFileModificationTime

    let l:allYanksFileContent = readfile(s:shareYanksFile)
    let l:allYanks = []

    for allYanksFileContentLine in l:allYanksFileContent
        let l:allYanksItem = eval(allYanksFileContentLine)
        let l:allYanksItem.text = substitute(l:allYanksItem.text, s:newLinePatternRegexp, "\n", 'g')
        call add(l:allYanks, l:allYanksItem)
    endfor

    if len(l:allYanks)
        call EasyClip#Yank#SetYankStackHead(remove(l:allYanks, 0))
        call EasyClip#Yank#SetYankStackTail(l:allYanks)
    endif

    call EasyClip#Yank#SyncNumberedRegisters()
    return 1
endfunction

function! EasyClip#Shared#Init()
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

    let yankHeadBeforeLoad = EasyClip#Yank#GetYankstackHead()

    call EasyClip#Shared#LoadFileIfChanged()

    let newYankHead = EasyClip#Yank#GetYankstackHead()

    " Do not clobber the initial yank after first loading Vim
    if yankHeadBeforeLoad.text !=# newYankHead.text
        EasyClipBeforeYank
        call EasyClip#Yank#SetYankStackHead(yankHeadBeforeLoad)
        EasyClipOnYanksChanged
    endif
endfunction
