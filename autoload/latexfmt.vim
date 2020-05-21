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

function! latexfmt#FormatLines(key) abort
   if a:key is 'v'                          "Format visual region.
      let l:start = line("'<")
      let l:end   = line("'>")
   elseif a:key is 'n' && v:count           "Format next v:count lines.
      let l:start = line('.')
      let l:end   = line('.') + v:count - 1
   elseif a:key is 'n'                      "Format paragraph.
      let l:start = nextnonblank( search('^\s*$\|\%^', 'bcn') )
      let l:end   = prevnonblank( search('^\s*$\|\%$', 'n')   )
   endif

"  Fix cursor placement after undo (unless blanks are merged).
   if foldclosed('.') == -1 | exe "normal! ix\<ESC>x"     | else 
                              exe "normal! zoix\<ESC>xzc" | endif

"  Build list of non-blanks + end blanks (if needed) from start line to cursor.
   let l:up_amt = l:start - line('.')    
   if l:up_amt <= 0     "True unless starting on blank line in paragraph mode.
      let l:lines = getline(l:start, '.')
      let l:lines[-1] = strpart(l:lines[-1], 0, col('.')) 
      let l:chars = split( substitute(join(l:lines,''),' \ze.','', 'g'),'\zs' )
      let l:ext_bl = len( matchstr(l:lines[-1],'[\.\?:][)}]\=\zs\s\{2,}$') ) - 1
   endif
    
"  Save window view, go to start of range, open folds, and mark line. 
   let l:win = winsaveview()
   call cursor(l:start, 1)
   normal! zn
   let l:mark = l:start

   while v:true 
"     Skip over any preserved environments, moving line mark after each.
      while  getline('.') =~# '\m'.s:env && g:latexfmt_preserve_envs
         call search(substitute(substitute(substitute(expand('<cWORD>'),'\[',
       \               '\\]','g'), 'begin','\\end','g'), '*','\\*','g'), 'W')
         normal! j
         let l:mark = line('.')
      endwhile
      if line('.') > l:end | break | endif

"     Remove multiple blanks, except at beginning of line and ends of sentences.
      if g:latexfmt_merge_blanks 
         silent! s/\S\zs\([\.\?:][)}]\=\)\@2<!\s\{2,}\ze/ /g
      endif

"     If at end of range or file, format from marked line and leave loop. 
      if line('.') is l:end || line('.') is line('$') 
         exe 'normal! $gw'.l:mark.'G'
         break 
      endif

"     If current line and next one can't join, or if next one begins a preserved
"     environment, format from marked line and move mark to next line.
      if  getline( line('.') + 1 ) =~# '\m'.s:pre || getline('.') =~# '\m'.s:nex
   \  || (getline( line('.') + 1 ) =~# '\m'.s:env && g:latexfmt_preserve_envs)
         exe 'normal! $gw'.l:mark.'G'
         let l:mark = line('.') + 1
      endif

"     Proceed to next line.
      normal! j
 	endwhile
    
"  Close folds, restore window view, and restore cursor position.
   normal! zN
   call winrestview(l:win)
   call cursor(l:start, 1)
   if l:up_amt > 0       | exe 'norm! '.l:up_amt.'k' | return | endif
   for i in l:chars[1:]  | call search('\S')         | endfor
   if l:chars[-1] is ' ' | call search('\S ','be')   | endif  "For blank at end
   if l:ext_bl > 0       | exe 'norm! '.l:ext_bl.'l' | endif  "For extra blanks
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
