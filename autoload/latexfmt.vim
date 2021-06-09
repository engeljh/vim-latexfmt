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
   if foldclosed('.') == -1 | exe "normal! i \<esc>x"     | else 
                              exe "normal! zoi \<esc>xzc" | endif
                            
"  Get text from first line to cursor, extract nonblanks, and count blanks at
"  end. Then count nonblanks from beginning to end of formatting range.
   let up_amt = first - line('.')    
   let txt = join( add( getline(first,line('.')-1),
       \                strpart( getline('.'),0,col('.') ) ), '' )
   let nb_txt = substitute(txt,' ','','g')
   let end_bl = strchars( matchstr(txt,'\s*$') )     
   let tot_nb = strchars(substitute(join(getline(first,last)),' ','','g'))
    
"  Save window view, go to start of range, open folds, and mark first line. 
   let win = winsaveview()
   call cursor(first, 1)
   normal! zn
   let mark = first
   let nb = 0

   while v:true 
"     Skip over any preserved environments, counting skipped characters and 
"     moving line mark after each. Then exit loop if beyond end of range.
      while  search(s:env,'c',line('.')) && g:latexfmt_preserve_envs
         call search(substitute(substitute(substitute(matchstr(expand('<cWORD>')
       \     ,s:env),'\[','\\]','g'), 'begin','\\end',''), '*','\\*',''), 'W')
         let nb += strchars(substitute(join(getline(mark,'.')),' ','','g')) 
         normal! j0
         let mark = line('.')
      endwhile
      let nb += strchars(substitute(getline('.'),' ','','g')) 
      if nb > tot_nb || (nb == tot_nb && getline('.') =~ '\m^\s*$') | break | en

"     Remove multiple blanks, except at beginning of line and ends of sentences.
      if g:latexfmt_merge_blanks 
         s/\S\zs\([\.\?:][)}]\=\)\@2<!\s\{2,}\ze/ /ge
      endif

"     If at end of range or file, format from marked line and exit loop. 
      if nb == tot_nb || line('.') is line('$')
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
   if up_amt > 0             | exe 'norm! '.up_amt.'k'      | return | endif
   if !up_amt && txt !~ '\S' | call cursor('.',end_bl)      | return | endif
   for i in nb_txt[1:]       | call search('\S')            | endfor
   if end_bl | call search('\( \|\n \)\{1,'.end_bl.'}','e') | endif 
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
