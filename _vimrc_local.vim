augroup LOCAL_SETUP
	 "using vim-addon-sql providing alias aware SQL completion for .sql files and PHP:
	 "autocmd BufRead,BufNewFile *.sql,*.php call vim_addon_sql#Connect('mysql',{'database':'DATABASE', 'user':'USER', 'password' : 'PASSWORD'})
	
	 "for php use tab as indentation character. Display a tab as 4 spaces:
	 "autocmd BufRead,BufNewFile *.php set noexpandtab| set tabstop=4 | set sw=4
	 "autocmd FileType php setlocal noexpandtab| setlocal tabstop=4 | setlocal sw=4
	
   "hint: for indentation settings modelines can be an alternative as well as
	"various plugins trying to set vim's indentation based on file contents.
augroup end
set tabstop=4
set expandtab
set shiftwidth=4
set autoindent
set smartindent
set cindent

