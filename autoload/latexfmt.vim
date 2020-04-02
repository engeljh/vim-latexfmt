let s:save_cpo = &cpoptions
set cpoptions&vim

let s:pre = substitute(substitute(join(g:latexfmt_no_join_any
       \   + g:latexfmt_no_join_prev, '\|'), '\\\ze[^|()@]', '\\\\', 'g'),
       \   '\(\[\|\]\)', '\\\1', 'g')
let s:nex = substitute(substitute(join(g:latexfmt_no_join_any
       \   + g:latexfmt_no_join_next, '\|'), '\\\ze[^|()@]', '\\\\', 'g'),
       \   '\(\[\|\]\)', '\\\1', 'g')
let s:env = substitute(substitute(join(g:latexfmt_verbatim_envs, '\|'),
       \   '\\\ze[^|()@]', '\\\\', 'g'), '\(\a\+\)', '\\\\begin{\1\\*\\=}', 'g')

function latexfmt#FormatLines(key) abort
   if a:key is 'v'                          "Format visual region
      let l:start = line("'<")
      let l:end   = line("'>")
   elseif a:key is 'n' && v:count           "Format next v:count lines
      let l:start = line('.')
      let l:end   = line('.') + v:count - 1
   elseif a:key is 'n'                      "Format paragraph
      let l:start = nextnonblank( search('^\s*$\|\%^','bcn') )
      let l:end   = prevnonblank( search('^\s*$\|\%$','n')   )
   endif

"  Save marks in temp file.
   let tmp = tempname()
   exe 'wv! ' . tmp

"  Mark cursor and window top, open folds, go to start of range, and mark.
   normal! maHmb`azn
   call cursor(l:start,1)
   normal! 0mc

   while v:true 
"     If you want, skip over all consecutive preserved environments, then mark.
      while  getline('.') =~# '\m'.s:env && g:latexfmt_preserve_envs
         call search(substitute(substitute(substitute(expand('<cWORD>'),'\[',
       \               '\\]','g'), 'begin','\\end','g'), '*','\\*','g'), 'W')
         normal! j0mc
      endwhile
      if line('.') > l:end | break | endif

"     Remove extra blanks in current line, except at beginning of line and at 
"     ends of sentences. 
      silent! s/\S\zs\([\.\?:][)}]\=\)\@2<!\s\{2,}\ze/ /g

"     If at end of range or file, format from start of marked line to end of 
"     current one, then leave loop. 
      if line('.') is l:end || line('.') is line('$') 
         normal! $md`cV`dgw
         break 
      endif

"     Format from mark to end of current line if current line and next one can't
"     join or if next line begins a preserved environment.  Then mark next line.
      if  getline( line('.') +1 ) =~# '\m'.s:pre || getline('.') =~# '\m'.s:nex 
   \  || (getline( line('.') +1 ) =~# '\m'.s:env && g:latexfmt_preserve_envs)
            normal! $md'cV`dgwj0mck
      endif

"     Proceed to next line.
      normal! j0
 	endwhile
    
"  Close folds, reset window top, restore cursor and marks, delete temp file.
   normal! zN`bzt`a
   exe 'rv! ' . tmp
   call delete(tmp)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
