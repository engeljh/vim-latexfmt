if exists('g:latexfmt_noload') | finish | endif
if exists("b:did_latexfmt")    | finish | endif
let b:did_latexfmt = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

" Default values of global variables
let g:latexfmt_no_join_any = get( g:,'latexfmt_no_join_any', ['\(\\)\@1<!%',
         \                '\begin', '\end', '\section', '\subsection', 
         \                '\subsubsection', '\document', '\(\\)\@1<!\[', '\]'] )
let g:latexfmt_no_join_prev  = get( g:,'latexfmt_no_join_prev', ['\item'] )
let g:latexfmt_no_join_next  = get( g:,'latexfmt_no_join_next', ['\\' ] )
let g:latexfmt_verbatim_envs = get( g:,'latexfmt_verbatim_envs', ['equation', 
         \                  'align', 'eqnarray', '\(\\)\@1<!\[' ] )
let g:latexfmt_preserve_envs = get( g:,'latexfmt_preserve_envs', 1 )

" Mapppings
noremap <expr><silent><buffer> <Plug>latexfmt_format mode() =~? 'v' 
         \                   ? ':<C-U>call latexfmt#FormatLines("v")<CR>' 
         \                   : ':<C-U>call latexfmt#FormatLines("n")<CR>' 
nnoremap <silent><buffer> <Plug>latexfmt_toggle_envs 
         \   :let g:latexfmt_preserve_envs =  1 - g:latexfmt_preserve_envs<CR>

let &cpoptions = s:save_cpo
unlet s:save_cpo
