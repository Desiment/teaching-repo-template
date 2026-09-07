# Use LuaLaTeX.
# This is a hint for editors; LuaLaTeX is enforced by project/.latexmkrc.make.
$pdf_mode = 4;

ensure_path('LUAINPUTS', '../configuration//');
ensure_path('LUAINPUTS', '../../');
ensure_path('TEXINPUTS', '../../');
ensure_path('TEXINPUTS', '../configuration//');
ensure_path('BIBINPUTS', '../../');
ensure_path('BIBINPUTS', '../configuration//');

$out_dir = '../../project/build';
$aux_dir = '../../project/build';

do '../../project/.latexmkrc.memoize';
do '../../project/.latexmkrc.make';
