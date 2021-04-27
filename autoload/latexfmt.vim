let s:save_cpo = &cpoptions
set cpoptions&vim

let s:prv = substitute(substitute(join(g:latexfmt_no_join_any
       \   + g:latexfmt_no_join_prev, '\|'), '\\\ze[^|()@]', '\\\\', 'g'),
       \   '\(\[\|\]\)', '\\\1', 'g')
let s:nxt = substitute(substitute(join(g:latexfmt_no_join_any
       \   + g:latexfmt_no_join_next, '\|'), '\\\ze[^|()@]', '\\\\', 'g'),
       \   '\(\[\|\]\)', '\\\1', 'g')
let s:env = substitute(substitute(join(g:latexfmt_verbatim_envs, '\|'),
       \   '\\\ze[^|()@]', '\\\\', 'g'), '\(\a\+\)', '\\\\begin{\1\\*\\=}', 'g')

function! latexfmt#FormatLines(key) abort
   if a:key is 'v'                          "Format visual region.
      let first = line("'<")
      let last  = line("'>")
   elseif a:key is 'n' && v:count           "Format next v:count lines.
      let first = line('.')
      let last  = line('.') + v:count - 1
   elseif a:key is 'n'                      "Format paragraph.
      let first = nextnonblank( search('^\s*$\|\%^', 'bcn') )
      let last  = prevnonblank( search('^\s*$\|\%$', 'n')   )
   endif

"  Fix cursor placement after undo (unless blanks are merged).
   if foldclosed('.') == -1 | exe "normal! ix\<esc>x"     | else 
                              exe "normal! zoix\<esc>xzc" | endif

"  Get text from first line to cursor, extract nonblanks, count blanks at end.
   let up_amt = first - line('.')    
   let txt = join( add( getline(first,line('.')-1),
       \                strpart (getline('.'),0,col('.') ) ), '' )
   let nonblank_txt = substitute(txt,' ','','g')
   let end_blanks = strchars( matchstr(txt,'\s*$') )     
    
"  Save window view, go to start of range, open folds, and mark line. 
   let win = winsaveview()
   call cursor(first, 1)
   normal! zn
   let mark = first

   while v:true 
"     Skip over any preserved environments, moving line mark after each.
      while  search(s:env,'c',line('.')) && g:latexfmt_preserve_envs
         call search(substitute(substitute(substitute(matchstr(expand('<cWORD>')
       \     ,s:env),'\[','\\]','g'), 'begin','\\end',''), '*','\\*',''), 'W')
         normal! j0
         let mark = line('.')
      endwhile
      if line('.') > last | break | endif

"     Remove multiple blanks, except at beginning of line and ends of sentences.
      if g:latexfmt_merge_blanks 
         s/\S\zs\([\.\?:][)}]\=\)\@2<!\s\{2,}\ze/ /ge
      endif

"     If at end of range or file, format from marked line and exit loop. 
      if line('.') is last || line('.') is line('$') 
         exe 'normal! $gw'.mark.'G'
         break 
      endif

"     If current line and next one can't join, or if next one begins a preserved
"     environment, format from marked line and move mark to next line.
      if  getline( line('.') + 1 ) =~# '\m'.s:prv || getline('.') =~# '\m'.s:nxt
   \  || (getline( line('.') + 1 ) =~# '\m'.s:env && g:latexfmt_preserve_envs)
         exe 'normal! $gw'.mark.'G'
         let mark = line('.') + 1
      endif

"     Proceed to next line.
      normal! j0
 	endwhile
    
"  Restore folds, window view, and cursor position.
   normal! zN
   call winrestview(win)
   exe 'normal! '.first.'G^'
   if up_amt > 0             | exe 'norm! '.up_amt.'k'     | return | endif
   if !up_amt && txt !~ '\S' | call cursor('.',end_blanks) | return | endif
   for i in nonblank_txt[1:] | call search('\S')                    | endfor
   if end_blanks | call search('\( \|\n \)\{1,'.end_blanks.'}','e') | endif 
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
