" Sleep example

" This example demonstrates how to use the vim-live-preview plugin to run a
" command that sleeps for a few seconds before printing a message.
"
" The `VLPSleepShell` command uses a shell to run sleep, while the
" `VLPSleepCmd` command runs Vim's sleep command.
" As you will see, the `VLPSleepShell` runs asynchronously, while the
" `VLPSleepCmd` will block the UI until the command finishes.
"
" Long running commands should use the shell to be run asynchronously!
"
" The `input` option is set to `none`, which means that the command does not
" receive any input.


" Check if the vim-live-preview plugin is installed
if &rtp =~ 'vim-live-preview'
  command! VLPSleepShell
        \ call vlp#EnterPreviewMode('!sleep 5; echo "Hello, World!"',
        \ {
        \   'input': 'none',
        \ })
  command! VLPSleepCmd
        \ call vlp#EnterPreviewMode('sleep 5 | echo "Hello, World!"',
        \ {
        \   'input': 'none',
        \ })
endif

