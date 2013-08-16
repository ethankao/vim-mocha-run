if exists("g:loaded_mocha_run") || &cp
  finish
endif

let g:loaded_mocha_run = 1
let s:keepcpo = &cpo
set cpo&vim

let s:mochaCmd = 'mocha'
let s:mochaOptions = '-R Min'

function! s:initVar(var, value)
  if ! exists(a:var)
    exec 'let ' . a:var . ' = ' . "'" . substitute(a:value, "'", "''", "g") . "'"
  endif
endfunction

call s:initVar("g:mocha_run_win_size", 10)
call s:initVar("g:mocha_run_path", "")

" commands
command! -n=? -complete=file -bar MochaRun :call MochaRun('<args>')
command! -n=* -complete=shellcmd -bar CmdRun :call CmdRun('<args>')

  " mappings
nnoremap <silent> <LocalLeader>m :MochaRun<CR>

function! MochaRun(fName)
  if empty(a:fName)
    let file = @%
  else
    let file = a:fName
  endif

  call s:switchWindow()
  silent normal! ggdG

  if isdirectory(a:fName)
    let opt = s:mochaOptions . ' --recursive '
  else
    let opt = s:mochaOptions . ' '
  endif
  let cmd = s:mochaCmd . ' ' . file . ' ' . opt
  if ! empty(g:mocha_run_path)
    let cmd = g:mocha_run_path . "/" . cmd
  endif

  let output = split(system(cmd), '\v\n')
  call s:formatOutput(output)
endfunction

function! CmdRun(...)
  if empty(a:1)
    return
  endif
  call s:switchWindow()
  silent execute ":%!" . a:1
endfunction

function! s:switchWindow()
  if ! exists("b:mochaRunWinParent")
    let l:pBuf = bufnr("%")
    " check if need to open new buf
    let bufName = "MochaRun"
    let mochaBuf = bufnr(bufName)
    if mochaBuf == -1
      let mochaBuf = bufnr(bufName, 1)
      silent execute "bo sb " . mochaBuf
      silent execute "resize " . g:mocha_run_win_size

      call setbufvar(mochaBuf, "&swapfile", 0)
      call setbufvar(mochaBuf, "&buftype", "nofile")
      call setbufvar(mochaBuf, "&buftype", "nowrite")
      call setbufvar(mochaBuf, "&bufhidden", "wipe")
      call setbufvar(mochaBuf, "mochaRunWinParent", l:pBuf)
      call setbufvar(mochaBuf, "&winfixheight", "1")

      " local mapping to close buffer
      execute "nnoremap \<buffer> \<silent> \<esc> :bw " . mochaBuf . "\<CR>"
    else
      let winNr = bufwinnr(mochaBuf)
      if winNr == -1
        silent execute "sb " . mochaBuf
        silent execute "resize " . g:mocha_run_win_size
      else
        silent execute winNr . "wincmd w"
      endif
    endif
  endif
endfunction

function! s:formatOutput(lines)
  let status = ""
  for line in a:lines
    let st = matchstr(line, '\d\+\s\(passing\|failing\|pending\).*')
    if !empty(st)
      let status = status . "\t" . st
    elseif !empty(line) && !empty(status)
      call append(line('$'), line)
    endif
  endfor
  if empty(status)
    call append("0", a:lines)
  else
    call append("0", status)
  endif
endfunction


let &cpo= s:keepcpo
unlet s:keepcpo
