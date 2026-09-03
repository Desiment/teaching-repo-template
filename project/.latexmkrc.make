use File::Path qw(make_path);

$pdf_mode = 4;
$clean_ext = 'out toc bbl bcf blg run.xml idx ind ilg thlist loc lol pyg xsim mmz mmz.log';

$lualatex = 'lualatex %O -halt-on-error -synctex=1 --shell-escape %S';
$pdflatex = $lualatex;

my $print_solutions = 'true';
my $print_mode = 'false';

if (defined $ENV{SOLUTIONS_MODE}) {
    my $mode = $ENV{SOLUTIONS_MODE};
    if ($mode ne 'include' && $mode ne 'exclude') {
        die "Unknown SOLUTIONS_MODE: '$mode'. Must be 'include' or 'exclude'\n";
    }

    $print_solutions = $mode eq 'include' ? 'true' : 'false';
    $jobname = "%A-solutions-$mode";
}

@ARGV = grep {
    if ($_ eq '--print') {
        $print_mode = 'true';
        0;
    }
    elsif ($_ eq '--solutions') {
        $print_solutions = 'true';
        0;
    }
    elsif ($_ eq '--no-solutions') {
        $print_solutions = 'false';
        0;
    }
    else {
        1;
    }
} @ARGV;

my $pretex = "\\def\\printsolutionbool{$print_solutions}";
$pretex .= "\\def\\printmodebool{true}" if $print_mode eq 'true';

my $flags_file = "$aux_dir/latexmk-flags.state";
my $old_pretex = '';
my $pretex_changed = 0;

make_path($aux_dir) unless -d $aux_dir;

if (open my $fh, '<', $flags_file) {
    local $/;
    $old_pretex = <$fh>;
    close $fh;
}

if ($old_pretex ne $pretex) {
    open my $fh, '>', $flags_file
        or die "Cannot write $flags_file: $!";
    print {$fh} $pretex;
    close $fh;
    $pretex_changed = 1;
}

splice @ARGV, 0, 0, '-g' if $pretex_changed;
splice @ARGV, 0, 0, '-shell-escape', '-usepretex=' . $pretex;

foreach my $source (@ARGV) {
    next if $source =~ /^-/;
    next if ! -f $source;

    open my $fh, '<', $source
        or next;
    local $/;
    my $content = <$fh>;
    close $fh;

    while ($content =~ /\\include\{([^}]+)\}/g) {
        my $include = $1;
        $include =~ s/\.tex\z//;
        next if $include !~ m{/};

        my $dir = $include;
        $dir =~ s{/[^/]+\z}{};
        make_path("$aux_dir/$dir") if defined $aux_dir && $aux_dir ne '';
        make_path("$out_dir/$dir") if defined $out_dir && $out_dir ne '' && $out_dir ne $aux_dir;
    }
}
