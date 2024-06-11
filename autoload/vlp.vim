if exists('g:autoloaded_vim_live_preview') || &cp || version < 700
  finish
endif
let g:autoloaded_vim_live_preview = 1

" Script variables and constants
let s:preview_bufnr = -1
let s:focus_bufnr = -1
let s:error_bufnr = -1
let s:func = 0
let s:cmd = ""
let s:use_shell = v:false
let s:job = 0
let s:updatetime_restore = &updatetime
let s:options = {}
let s:default_options = {
      \ 'change_updatetime': v:true,
      \ 'update_interval': 250,
      \ 'preview_buffer_filetype': '',
      \ 'preview_buffer_name': '[VimLivePreview]',
      \ 'input': 'range',
      \ 'trigger_events': ['TextChanged', 'TextChangedI', 'TextChangedP',],
      \ 'use_jobs': v:true,
      \ 'stderr': 'fallback',
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


function! s:EnsureBrackets(name)
  let l:bracketed_name = a:name
  if l:bracketed_name[0] != '['
    let l:bracketed_name = '[' . l:bracketed_name
  endif
  if l:bracketed_name[-1:] != ']'
    let l:bracketed_name = l:bracketed_name . ']'
  endif
  return l:bracketed_name
endfunction

" Print functions
function! s:Print(msg)
  echomsg a:msg
endfunction


function! s:PrintError(msg)
  echoerr "Error: " . a:msg
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
  if exists('#error_buffer_exit')
    autocmd! error_buffer_exit
  endif
  call s:CleanUpLeaveCommand()
  if s:error_bufnr != -1
    exec "bdelete! " . s:error_bufnr
  endif
  let s:preview_bufnr = -1
  let s:focus_bufnr = -1
  let s:error_bufnr = -1
  let s:func = 0
  let s:cmd = ""
  let s:use_shell = v:false
  if s:GetOption('change_updatetime')
    let &updatetime = s:updatetime_restore
  endif
  call s:Print("Left preview mode.")
endfunction


function! s:CreatePreviewBuffer(bufname)
  exec "vertical new " . a:bufname
  let l:bufnr = bufnr()

  setlocal nobuflisted
  setlocal bufhidden=wipe " or delete?
  setlocal buftype=nofile
  setlocal noswapfile
  setlocal nomodifiable " TODO: option to let it be modifiable
  setlocal autoread
  exec "set ft=" . s:GetOption('preview_buffer_filetype')

  augroup preview_mode_exit
    autocmd!
    autocmd WinClosed,BufDelete <buffer> call s:LeavePreviewMode()
  augroup END
  wincmd p " go back to the previous window
  return l:bufnr
endfunction

function! s:CreateErrorBuffer()
  let l:preview_bufname = s:EnsureBrackets(s:GetOption('preview_buffer_name'))
  let l:bufname = l:preview_bufname[0:len(l:preview_bufname)-2] . " Error]"
  exec win_id2win(bufwinid(s:preview_bufnr)) . "wincmd w"
  exec "horizontal 10new " . l:bufname
  let l:bufnr = bufnr()
  setlocal nobuflisted
  setlocal bufhidden=wipe " or delete?
  setlocal buftype=nofile
  setlocal noswapfile
  setlocal nomodifiable
  setlocal autoread
  augroup error_buffer_exit
    autocmd!
    autocmd WinClosed,BufDelete <buffer> let s:error_bufnr = -1
  augroup END
  exec win_id2win(bufwinid(s:focus_bufnr)) . "wincmd w"
  return l:bufnr
endfunction


function! s:WritePreviewBuffer(bufnr, lines)
  silent call setbufvar(a:bufnr, '&modifiable', v:true)
  silent call setbufline(a:bufnr, 1, a:lines)
  silent call deletebufline(a:bufnr, len(a:lines) + 1, "$")
  silent call setbufvar(a:bufnr, '&modifiable', v:false)
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
    let l:params = "expand('%:p')"
  elseif l:input == 'content'
    let l:params = "escape(join(getline(1, '$'), '\n'), '\"')"
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
  elseif l:input == 'content'
    let l:cmd_suffix = substitute(a:args[0], '\\"', '"', 'g')
  elseif l:input == 'none' || l:input == ''
    " do nothing
  else
    call s:PrintError("Invalid input option: " . l:input)
  endif
  return l:cmd_prefix . a:cmd . " " . l:cmd_suffix
endfunction


function! s:FunctionCallback(...)
  if a:0 < 3 && a:0 >= 0
    let l:input = s:GetOption('input')
    let l:quote = l:input == 'content' || l:input == 'fname' ? '"' : ''
    exec "call s:WritePreviewBuffer(s:preview_bufnr, s:func(" . l:quote .
          \ join(a:000, ',') . l:quote . "))"
  else
    call s:PrintError("Invalid number of arguments.")
  endif
endfunction


function! s:SetupWriteFunction()
  let l:write_callback = 'call ' .
        \ (
        \   s:func != 0 ? 's:FunctionCallback' :
        \   s:use_shell ? 's:ShellCallback' :
        \   's:CommandCallback'
        \ )
        \ . '(' . s:GetParams() . ')'
  " Initial write
  exec l:write_callback

  " Continuous write
  let l:events = s:GetOption('trigger_events')
  augroup preview_mode
    autocmd!
    if !empty(l:events)
      exec "autocmd " . join(l:events, ",") . " <buffer> " .
            \ l:write_callback . " | checktime"
    else
      call s:Print("No trigger events defined.")
    endif
  augroup END
endfunction


function! s:ReadChannel(channel, part)
  let l:lines = []
  while ch_status(a:channel, {'part': a:part}) == 'buffered'
    let l:lines += [ch_read(a:channel, {'part': a:part})]
  endwhile
  return l:lines
endfunction


function! s:JobClosedCallback(channel) abort
  let l:stderr = s:GetOption('stderr')
  let l:lines = []
  let l:out_lines = s:ReadChannel(a:channel, 'out')
  let l:err_lines = s:ReadChannel(a:channel, 'err')
  if l:stderr == 'fallback'
    let l:lines = empty(l:out_lines) ? l:err_lines : l:out_lines
  elseif l:stderr == 'first'
    let l:lines = l:err_lines + l:out_lines
  elseif l:stderr == 'last'
    let l:lines = l:out_lines + l:err_lines
  elseif l:stderr == 'none'
    let l:lines = l:out_lines
  elseif l:stderr == 'window'
    let l:lines = l:out_lines
    if !empty(l:err_lines)
      if s:error_bufnr == -1
        let s:error_bufnr = s:CreateErrorBuffer()
      endif
      call s:WritePreviewBuffer(s:error_bufnr, l:err_lines)
    elseif s:error_bufnr != -1
      exec "bdelete! " . s:error_bufnr
    endif
  endif
  call s:WritePreviewBuffer(s:preview_bufnr, l:lines)
endfunction


function! s:InsertInputIntoShellCommand(cmd, input, value)
  let l:pattern = '<' . a:input . '>'
  if stridx(a:cmd, l:pattern) != -1
    return substitute(a:cmd, l:pattern, a:value, 'g')
  else
    return a:cmd . " " . a:value
  endif
endfunction


function! s:ShellCallback(...)
  " external shell command
  let l:cmd = s:cmd
  let l:input = s:GetOption('input')
  let l:value = ''
  if l:input == 'content'
    let l:value = substitute(a:1, '\\"', '"', 'g')
  elseif l:input != 'none'
    let l:value = l:input == 'range' ? a:1 . ',' . a:2 : a:1
    let l:cmd = s:InsertInputIntoShellCommand(l:cmd, l:input, l:value)
  endif

  " TODO: neovim support: jobstart
  if exists("*job_start") && s:GetOption('use_jobs')
    let l:cmd = has('win32') ? l:cmd : [&shell, '-c', l:cmd]
    " preview buffer will be written in callback
    let s:job = job_start(l:cmd, {'close_cb': function('s:JobClosedCallback')})
    if l:input == 'content'
      let l:channel = job_getchannel(s:job)
      call ch_sendraw(l:channel, l:value)
      call ch_close_in(l:channel)
    endif
    return
  else
    if l:input == 'content'
      let l:lines = split(system(l:cmd, l:value), "\n")
    else
      let l:lines = split(system(l:cmd), "\n")
    endif
  endif
  call s:WritePreviewBuffer(s:preview_bufnr, l:lines)
endfunction


function! s:CommandCallback(...)
  " internal vim command
  let l:cmd = s:ParameterizedCommand(s:cmd, a:000)
  let l:lines = split(execute(l:cmd), "\n")
  call s:WritePreviewBuffer(s:preview_bufnr, l:lines)
endfunction


function! vlp#DefaultOptions()
  return deepcopy(s:default_options)
endfunction


" Main functions
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
  if fullcommand(s:cmd) == '!'
    let s:use_shell = v:true
    let s:cmd = substitute(s:cmd, '^:\?!', '', '')
  else
    let s:use_shell = v:false
  end

  if s:func == 0 && s:cmd == ''
    call s:PrintError("Invalid argument: " . a:functor)
    return
  endif

  let l:bufname = s:EnsureBrackets(s:GetOption('preview_buffer_name'))
  if bufexists(l:bufname) " TODO: use bufloaded instead?
    " TODO: option to reuse the buffer
    call s:PrintError("Preview buffer already exists: " .
          \ s:EnsureBrackets(s:GetOption('preview_buffer_name')))
    return
  endif

  if s:GetOption('change_updatetime')
    let s:updatetime_restore = &updatetime
    let &updatetime = s:GetOption('update_interval')
  endif

  " is there only one window open?
  if winnr("$") > 1
    only " close all windows except the current one TODO: option
  endif
  let s:focus_bufnr = bufnr()
  let s:preview_bufnr = s:CreatePreviewBuffer(l:bufname)
  if s:preview_bufnr == -1
    call s:PrintError("Preview buffer already exists: " .
          \ s:EnsureBrackets(s:GetOption('preview_buffer_name')))
    return
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
