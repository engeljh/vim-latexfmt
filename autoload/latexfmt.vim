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

"  Build list of non-blanks + end blanks (if needed) from first line to cursor.
   let up_amt = first - line('.')    
   let txt = add( getline(first,line('.')-1), strpart(getline('.'),0,col('.')) )
   let chars = split( substitute(join(txt,''),' \ze.','', 'g'),'\zs' )
   let ext_bl = len( matchstr(txt[-1],'[\.\?:][)}]\=\zs\s\{2,}$') ) - 1
    
"  Save window view, go to start of range, open folds, and mark line. 
   let win = winsaveview()
   call cursor(first, 1)
   normal! zn
   let mark = first

   while v:true 
"     Skip over any preserved environments, moving line mark after each.
      while  getline('.') =~# '\m'.s:env && g:latexfmt_preserve_envs
         call search(substitute(substitute(substitute(expand('<cWORD>'),'\[',
       \               '\\]','g'), 'begin','\\end',''), '*','\\*',''), 'W')
         normal! j
         let mark = line('.')
      endwhile
      if line('.') > last | break | endif

"     Remove multiple blanks, except at beginning of line and ends of sentences.
      if g:latexfmt_merge_blanks 
         s/\S\zs\([\.\?:][)}]\=\)\@2<!\s\{2,}\ze/ /ge
      endif

"     If at end of range or file, format from marked line and leave loop. 
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
      normal! j
 	endwhile
    
"  Restore folds, window view, and cursor position.
   normal! zN
   call winrestview(win)
   exe 'normal! '.first.'G^'
   if up_amt > 0       | exe 'norm! '.up_amt.'k' | return  | endif
   for i in chars[1:]  | call search('\S')                 | endfor
   if chars[-1] is ' ' | call search('\S ','be',line('.')) | endif    "End blank
   if ext_bl > 0       | exe 'norm! '.ext_bl.'l'           | endif "Extra blanks
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
