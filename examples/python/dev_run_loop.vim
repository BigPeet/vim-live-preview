" Python Example

" This is a very straightforward example of how to use VLP to a typical
" develop-and-run workflow.
"
" The command will call 'python3 <fname>' where <fname> is the name of the
" working file. Optionally, you can pass arguments to the command.
" The preview buffer will be named 'Python Output' and will be updated
" automatically every time the working file is saved.

if &rtp =~ 'vim-live-preview'
  autocmd FileType python command! -nargs=? VLPPython call
        \ vlp#EnterPreviewMode(":!python3 <fname> " . <q-args>,
        \ {
        \   'input': 'fname',
        \   'preview_buffer_name': 'Python Output',
        \   'trigger_events': ['BufWritePost'],
        \ })
endif

if !executable("pytest")
  finish
endif

" Similarly, we can also run pytest with VLP.
" Notably, this command does not pass the filename to pytest.
" Instead, it will run pytest with the given arguments.

if &rtp =~ 'vim-live-preview'
  autocmd FileType python command! -nargs=? VLPPytest call
        \ vlp#EnterPreviewMode(":!pytest " . <q-args>,
        \ {
        \   'input': 'none',
        \   'preview_buffer_name': 'pytest',
        \   'trigger_events': ['BufWritePost'],
        \ })
endif
