" Check if the vim-live-preview plugin is installed
if &rtp =~ 'vim-live-preview'
  autocmd FileType python command! VLPPython call
        \ vlp#EnterPreviewMode(':!python3 <fname> --verbose $USER',
        \ {
        \   'input': 'fname',
        \   'preview_buffer_name': 'Python Output',
        \   'trigger_events': ['BufWritePost'],
        \ })
endif
