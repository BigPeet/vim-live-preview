if exists('g:autoloaded_vim_live_preview') || &cp || version < 700
  finish
endif
let g:autoloaded_vim_live_preview = 1

" Script variables and constants
let s:preview_bufnr = -1
let s:focus_bufnr = -1
let s:func = 0
let s:cmd = ""
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


function! s:CleanUpLeaveCommand()
  let l:current_buffer = bufnr()
  if l:current_buffer == s:focus_bufnr
    delcommand -buffer VLPLeave
  else
    " ok, defer removal to when we re-enter the focus buffer
    augroup preview_leave_cleanup
      autocmd!
      execute "autocmd BufEnter <buffer=" . s:focus_bufnr .
            \ "> delcommand -buffer VLPLeave | autocmd! preview_leave_cleanup"
    augroup END
  endif
endfunction


function! s:LeavePreviewMode()
  autocmd! preview_mode
  autocmd! preview_mode_exit
  autocmd! preview_mode_buffer_exit
  call s:CleanUpLeaveCommand()
  let s:preview_bufnr = -1
  let s:focus_bufnr = -1
  let s:func = 0
  let s:cmd = ""
  if s:ChangeUpdateTime()
    let &updatetime = s:updatetime_restore
  endif
  call s:Print("Left preview mode.")
endfunction


function! s:CreatePreviewBuffer()
  vertical new VimLivePreview
  let l:bufnr = bufnr()

  setlocal nobuflisted
  setlocal bufhidden=delete
  setlocal buftype=nofile
  setlocal noswapfile
  setlocal autoread

  augroup preview_mode_exit
    autocmd!
    autocmd WinClosed,BufDelete <buffer> call s:LeavePreviewMode()
  augroup END
  wincmd p " go back to the previous window
  return l:bufnr
endfunction


function! s:WritePreviewBuffer(bufnr, lines)
  silent call setbufline(a:bufnr, 1, a:lines)
  silent call deletebufline(a:bufnr, len(a:lines) + 1, "$")
endfunction


function! s:GetFunction(func)
  if type(a:func) == v:t_string
    silent! return function(a:func)
  elseif type(a:func) == v:t_func
    return a:func
  endif
  return 0
endfunction


function! s:SetupWriteFunction()
  " Initial write
  call s:WritePreviewBuffer(s:preview_bufnr, s:func(1, line("$")))

  " Continuous write
  augroup preview_mode
    autocmd!
    autocmd TextChanged,TextChangedI <buffer>
          \ call s:WritePreviewBuffer(s:preview_bufnr, s:func(1, line("$")))
          \ | checktime
  augroup END
endfunction


function! s:LiteralWrite(start, end)
  if fullcommand(s:cmd) == '!'
    " external command
    return split(system(substitute(s:cmd, '^:\?!', '', '')), "\n")
  else
    return split(execute(s:cmd), "\n")
  endif
endfunction


" Main functions
" TODO: accept an optional dictionary of options, e.g.:
"       - ft of the preview buffer
"       - name of the preview buffer
"       - fname, content (range) and/or nothing as argument to func/cmd
"         - if the fname is given, the trigger needs to happen on save
"       - etc.
function! vlp#EnterPreviewMode(functor)
  if s:preview_bufnr != -1
    call s:PrintError("Already in preview mode.")
    return
  endif

  let s:func = s:GetFunction(a:functor)
  let s:cmd = s:func != 0 ? '' : type(a:functor) == v:t_string ? a:functor : ''

  only " close all windows except the current one TODO: option
  let s:focus_bufnr = bufnr()
  let s:preview_bufnr = s:CreatePreviewBuffer()

  if s:ChangeUpdateTime()
    let s:updatetime_restore = &updatetime
    let &updatetime = s:UpdateInterval()
  endif

  " Setup leave
  augroup preview_mode_buffer_exit
    autocmd!
    autocmd WinClosed,BufUnload <buffer> call s:LeavePreviewMode()
  augroup END
  command! -buffer -nargs=0  VLPLeave execute "bdelete" . s:preview_bufnr

  " Setup write function
  if s:cmd != ''
    let s:func = function('s:LiteralWrite')
  endif
  if s:func != 0
    call s:SetupWriteFunction()
  endif
endfunction
