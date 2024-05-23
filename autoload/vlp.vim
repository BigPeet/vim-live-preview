if exists('g:autoloaded_vim_live_preview') || &cp || version < 700
  finish
endif
let g:autoloaded_vim_live_preview = 1

" Script variables and constants
let s:preview_bufnr = -1
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
  execute 'bwipe ' . s:preview_bufnr
  delcommand VLPLeave
  let s:preview_bufnr = -1
  let s:func = ""
  if s:ChangeUpdateTime()
    let &updatetime = s:updatetime_restore
  endif
endfunction


function! s:CreatePreviewBuffer()
  vertical new VimLivePreview
  let l:bufnr = bufnr()
  " setup scratch-buffer
  setlocal bufhidden=hide
  setlocal buftype=nofile
  setlocal noswapfile

  setlocal autoread
  augroup preview_mode_exit
    autocmd!
    " TODO: bug: if the window is closed via <c-w>O, an empty buffer remains
    autocmd WinClosed,BufDelete <buffer> call s:LeavePreviewMode()
  augroup END
  wincmd p " go back to the previous window
  return l:bufnr
endfunction


function! s:ClearPreviewBuffer(bufnr)
  silent call deletebufline(a:bufnr, 1, "$")
endfunction


function! s:WritePreviewBuffer(bufnr, lines)
  silent call s:ClearPreviewBuffer(a:bufnr)
  silent call setbufline(a:bufnr, 1, a:lines)
endfunction


" Main functions
" TODO: accept an optional dictionary of options, e.g.:
"       - ft of the preview buffer
"       - name of the preview buffer
"       - function or command
"       - fname, content or nothing as argument to func
"       - etc.
function! vlp#EnterPreviewMode(func)
  if s:preview_bufnr != -1
    call PrintError("Already in preview mode.")
    return
  endif

  let s:preview_bufnr = s:CreatePreviewBuffer()
  let s:func = a:func " TODO: also add support for cmds
  call s:WritePreviewBuffer(s:preview_bufnr, s:func(1, line("$")))
  augroup preview_mode
    autocmd!
    autocmd TextChanged,TextChangedI <buffer>
          \ call s:WritePreviewBuffer(s:preview_bufnr, s:func(1, line("$")))
          \ | checktime
    autocmd BufDelete <buffer> call s:LeavePreviewMode()
  augroup END
  command! -buffer -nargs=0  VLPLeave call s:LeavePreviewMode()

  if s:ChangeUpdateTime()
    let s:updatetime_restore = &updatetime
    let &updatetime = s:UpdateInterval()
  endif
endfunction
