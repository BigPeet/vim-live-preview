if exists('g:autoloaded_vim_live_preview') || &cp || version < 700
  finish
endif
let g:autoloaded_vim_live_preview = 1

" Script variables and constants
let s:preview_bufnr = -1
let s:focus_bufnr = -1
let s:func = 0
let s:cmd = ""
let s:job = 0
let s:updatetime_restore = &updatetime
let s:options = {}
let s:default_options = {
      \ 'change_updatetime': v:true,
      \ 'update_interval': 250,
      \ 'preview_buffer_filetype': '',
      \ 'preview_buffer_name': 'VimLivePreview',
      \ 'input': 'range',
      \ 'trigger_events': ["TextChanged", "TextChangedI", "TextChangedP",],
      \ }

" Getter functions for 'global' options
"  - If the option is not directly set by the user,
"      it will fallback to the global variable.
"  - If the global variable is not set,
"      it will fallback to the default value.
function! s:GetOption(name)
  return get(s:options, a:name,
       \ get(g:, 'vlp_' . a:name, s:default_options[a:name]))
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
  if s:GetOption('change_updatetime')
    let &updatetime = s:updatetime_restore
  endif
  call s:Print("Left preview mode.")
endfunction


function! s:CreatePreviewBuffer()
  exec "vertical new " . s:GetOption('preview_buffer_name')
  let l:bufnr = bufnr()

  setlocal nobuflisted
  setlocal bufhidden=delete
  setlocal buftype=nofile
  setlocal noswapfile
  setlocal autoread
  exec "set ft=" . s:GetOption('preview_buffer_filetype')

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


function! s:GetParams()
  let l:input = s:GetOption('input')
  if l:input == 'range'
    let l:params = "1, line('$')"
  elseif l:input == 'buffer'
    let l:params = "bufnr('%')"
  elseif l:input == 'fname'
    let l:params = "shellescape(expand('%:p'))"
  elseif l:input == 'none' || l:input == ''
    let l:params = ""
  else
    call s:PrintError("Invalid input option: " . l:input)
  endif
  return l:params
endfunction

function! s:ParameterizedCommand(cmd, args)
  let l:input = s:GetOption('input')
  let l:cmd_prefix = ""
  let l:cmd_suffix = ""

  if l:input == 'range'
    let l:cmd_prefix = a:args[0] . "," . a:args[1]
  elseif l:input == 'buffer' || l:input == 'fname'
    let l:cmd_suffix = a:args[0]
  elseif l:input == 'none' || l:input == ''
    " do nothing
  else
    call s:PrintError("Invalid input option: " . l:input)
  endif
  return l:cmd_prefix . a:cmd . " " . l:cmd_suffix
endfunction


function! s:FunctionWrite(...)
  if a:0 < 3 && a:0 >= 0
    exec "call s:WritePreviewBuffer(s:preview_bufnr, s:func(" .
          \ join(a:000, ',') . "))"
  else
    call s:PrintError("Invalid number of arguments.")
  endif
endfunction


function! s:SetupWriteFunction()
  let l:write_callback = "call " .
        \ (s:func != 0 ? "s:FunctionWrite(" : "s:CommandWrite(")
        \ . s:GetParams() . ")"
  " Initial write
  exec l:write_callback

  " Continuous write
  augroup preview_mode
    autocmd!
    exec "autocmd " . join(s:GetOption('trigger_events'), ",") . " <buffer> " .
          \ l:write_callback . " | checktime"
  augroup END
endfunction


function! s:CloseCallback(channel) abort
  let l:lines = []
  while ch_status(a:channel, {'part': 'out'}) == 'buffered'
    let l:lines += [ch_read(a:channel)]
  endwhile
  unlet s:job
  call s:WritePreviewBuffer(s:preview_bufnr, l:lines)
endfunction


function! s:CommandWrite(...)
  let l:cmd = s:ParameterizedCommand(s:cmd, a:000)
  if fullcommand(s:cmd) == '!'
    " external shell command
    let l:cmd = substitute(l:cmd, '^:\?!', '', '')
    if exists("*job_start") " TODO: neovim support: jobstart
      let l:cmd = has('win32') ? l:cmd : [&shell, '-c', l:cmd]
      " preview buffer will be written in callback
      let s:job = job_start(l:cmd, {'close_cb': function('s:CloseCallback')})
      return
    else
      let l:lines = split(system(l:cmd), "\n")
    endif
  else
    let l:lines = split(execute(l:cmd), "\n")
  endif
  call s:WritePreviewBuffer(s:preview_bufnr, l:lines)
endfunction


function! vlp#DefaultOptions()
  return deepcopy(s:default_options)
endfunction


" Main functions
" TODO: accept an optional dictionary of options, e.g.:
"       - fname, content (range) and/or nothing as argument to func/cmd
"         - if the fname is given, the trigger needs to happen on save
"       - etc.
" Entry point for 'plugins'
"   - accepts a function or a command
"   - optionally a dictionary with options (see ...)
function! vlp#EnterPreviewMode(functor, ...)
  if s:preview_bufnr != -1
    call s:PrintError("Already in preview mode.")
    return
  endif

  let s:options = a:0 > 0 && type(a:1) == v:t_dict ? a:1 : {}
  let s:func = s:GetFunction(a:functor)
  let s:cmd = s:func != 0 ? '' : type(a:functor) == v:t_string ? a:functor : ''

  if s:func == 0 && s:cmd == ''
    call s:PrintError("Invalid argument: " . a:functor)
    return
  endif

  only " close all windows except the current one TODO: option
  let s:focus_bufnr = bufnr()
  let s:preview_bufnr = s:CreatePreviewBuffer()

  if s:GetOption('change_updatetime')
    let s:updatetime_restore = &updatetime
    let &updatetime = s:GetOption('update_interval')
  endif

  " Setup leave
  augroup preview_mode_buffer_exit
    autocmd!
    autocmd WinClosed,BufUnload <buffer> call s:LeavePreviewMode()
  augroup END
  command! -buffer -nargs=0  VLPLeave execute "bdelete" . s:preview_bufnr

  " Setup write function
  call s:SetupWriteFunction()
endfunction
