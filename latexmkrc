$out_dir = './project/pdf';
$aux_dir = './project/build';

do './project/.latexmkrc.paths';
do './project/.latexmkrc.memoize';
do './project/.latexmkrc.make';
