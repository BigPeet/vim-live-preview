if exists('g:autoloaded_vim_live_preview') || &cp || version < 700
  finish
endif
let g:autoloaded_vim_live_preview = 1

" Script variables and constants
let s:tmpfile = ""
let s:func = ""
let s:updatetime_restore = &updatetime

" Getter functions for Options
function! s:ChangeUpdateTime()
  return get(g:, 'vim_live_preview_change_updatetime', v:true)
endfunction

function! s:UpdateInterval()
  return get(g:, 'vim_live_preview_update_interval', 250)
endfunction


" Print functions
function! s:Print(msg)
  echomsg a:msg
endfunction


function! s:PrintError(msg)
  echohl ErrorMsg
  echomsg "Error: " . a:msg
  echohl None
endfunction


function! s:LeavePreviewMode()
  autocmd! preview_mode
  autocmd! preview_mode_exit
  execute 'bwipe ' . fnameescape(s:tmpfile)
  delcommand LeavePreviewMode
  let s:tmpfile = ""
  let s:func = ""
  if s:ChangeUpdateTime()
    let &updatetime = s:updatetime_restore
  endif
endfunction


" Main functions
function! vlp#EnterPreviewMode(func)
  if s:tmpfile != ""
    call PrintError("Already in preview mode.")
    return
  endif

  let s:tmpfile = tempname()
  let s:func = function(a:func)
  call writefile([""], s:tmpfile) " create empty file
  augroup preview_mode
    autocmd!
    autocmd TextChanged,TextChangedI <buffer>
          \ call writefile(s:func(1, line("$")), fnameescape(s:tmpfile)) | checktime
    autocmd BufDelete <buffer> call s:LeavePreviewMode()
  augroup END
  command! -buffer -nargs=0  LeavePreviewMode call s:LeavePreviewMode()
  execute 'vs' fnameescape(s:tmpfile)
  setlocal autoread
  setlocal readonly
  augroup preview_mode_exit
    autocmd!
    autocmd WinClosed,BufDelete <buffer> call s:LeavePreviewMode()
  augroup END
  wincmd p " go back to previous window
  if s:ChangeUpdateTime()
    let s:updatetime_restore = &updatetime
    let &updatetime = s:UpdateInterval()
  endif
endfunction
