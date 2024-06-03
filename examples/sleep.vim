" Check if the vim-live-preview plugin is installed
if &rtp =~ 'vim-live-preview'
  command! VLPSleepShell
        \ call vlp#EnterPreviewMode('!sleep 5; echo "Hello, World!"',
        \ {
        \   'input': 'none',
        \ })
  command! VLPSleepCmd
        \ call vlp#EnterPreviewMode('sleep 5; echo "Hello, World!"',
        \ {
        \   'input': 'none',
        \ })
endif

