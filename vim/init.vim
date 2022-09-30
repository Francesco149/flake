let g:python_recommended_style = 0
filetype plugin on
"filetype indent on
filetype indent off
set smarttab
"set autoindent
set noautoindent
set nocindent
set nowrap
set swapfile
set backup
set colorcolumn=100
set wildmenu
set path+=**
let g:netrw_liststyle=3
highlight LineNr ctermfg=darkgrey
highlight CursorLineNr ctermfg=grey
highlight Pmenu ctermbg=darkgrey
highlight PmenuSel ctermbg=grey ctermfg=black
highlight ColorColumn ctermbg=grey
syntax on

function NoTabs()
  set expandtab
  set softtabstop=0
  set listchars=tab:>~,nbsp:_,trail:.
  set list
endfunction

function Tabs()
  set noexpandtab
  set softtabstop=4
  set listchars=tab:\ \ ,nbsp:_,trail:.
  set list
endfunction

call NoTabs()

command! NoTabs call NoTabs()
command! Tabs call Tabs()
