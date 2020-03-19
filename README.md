
## LaTeXFmt is a LaTeX-aware formatter.   
 
------------------------- 

 Here's an example of what LaTeXFmt does:
 
<img src="http://physics.unc.edu/~engelj/LaTeXFmt.gif" style="width: 35vw; min-width: 330px;">

Before creating this gif, I mapped 'K' to &lt;Plug&gt;latexfmt_format.
In absence of a count or visual selection, the command formats the current
paragraph.  One might note several things about the way the paragraphs are
formatted:

1. In the first paragraph, nothing inside the align environment is formatted.
2. In the second paragraph, the individual items in the itemize environment are
   formatted while newlines after each item are retained.
3. In both paragraphs, the cursor retains its 'logical' position.
4. In both paragraphs, multiple spaces outside the align environment collapse to
   a single space (except at the ends of sentences).

## Installation
 
If you use pathogen or the native vim package manager, simply clone this
repository to the appropriate directory.  If you're using a more configurable
package manager, you'll know what to do.

## Configuration

LaTexFmt takes its instructions for how to format from a set of lists.  To
reproduce the behavior above, it is enough to define, in your .vimrc or
elsewhere in your runtime path,

```vim
let g:latexfmt_no_join_any = [ '%', '\begin, '\end', '\vspace', '\noindent' ] 

let g:latexfmt_no_join_prev = [ '\item' ] 

let g:latexfmt_verbatim_envs = [ 'align' ] 
```

The first list contains strings that prevent lines containing them from joining
the following or previous lines, the second contains strings that prevent them
from joining the previous lines but allow them to join the following lines
(there is also a list named g:latexfmt_no_join_next that does the opposite), and
the third contains environments that LaTeXFmt leaves completely alone.  The
default lists contain more strings, but are still pretty minimal.  You'll
probably want to construct your own. 

## Acknowledgment

This plugin is essentially a rewrite and extension of the inspirational script
by 'lpb612,' at https://www.vim.org/scripts/script.php?script_id=2307. 

For more information, type `:help latexfmt`.
