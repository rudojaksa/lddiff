# include .version.pl .lddiff.built.pl

our $HELP=<<EOF;

NAME
    lddiff - diff ldd of two or more files

USAGE
    lddiff [OPTIONS] `FILE1` `FILE2`

DESCRIPTION
    Lddiff lists shared libs required by programs or libs.
    For two or more files it aligns them as a line-by-line diff.
    It is implemented as a wrapper of `ldd` and `od`.

OPTIONS
    -h  This help.
    -v  Verbose.
   -bw  Black & white.
    -p  Primary libs only.
    -s  Short, strip `lib` and `.so.`.
    -b  Black-out only rows with all columns present.
   -nb  Don't black-out identical names.
   -ng  Don't highlight secondary libs (green).
   -fh  Full header, display directory and filename.

COLORS
      CR(red)  Missing libs.
  CD(default)  Primary libs, referenced directly from the file.
    CG(green)  Libs referenced from libs.
  CM(magenta)  Additional libs not seen by `ldd` but found by `od`.
    CK(black)  Blacked-out libs present in all existing columns.
    CW(white)  Blacked-out libs with columns missing (`-b` option).

STATISTICS
    The last line CK(")CD(84)CK(-)CG(28)CK(-)CR(13)CK(+)CM(1)CK(") means:

  CD(84)  84 referenced libs found by `ldd`,
  CG(28)  from these, 28 are secondary, referenced from other libs,
  CR(13)  from these, 13 are not found, so program will not run,
   CM(1)  additional one potentially required lib is found by `od`.

EXAMPLES
    CW(lddiff -v -nb libgtk*)
    CW(lddiff -s libX*)
    CW(lddiff -bw libgtk* | grep libX)

TRY ALSO
    CW(objdump -p \$FILE | grep NEEDED | sed 's:.* ::' | sort)
    CW(readelf -d \$FILE | grep NEEDED | sed 's:.*\\[::' | sed 's:\\]::' | sort)
    CW(lsof -p \$PID | sed 's:.* ::' | grep .so | sed 's:.*/::' | sort)
    CW(ldd \$FILE | grep ' => ' | sed 's: => .*::' | sed 's:\\t::' | sort)
    CW(od -S 7 \$FILE | grep lib | grep -F .so | cut -d ' ' -f 2 | sed 's:^.*/::' | grep '^lib' | sort -u)

VERSION
    $PACKAGE-$VERSION$SUBVERSION CK($AUTHOR) CK(built $BUILT)

EOF

# ---------------------------------------------------------------------------------------------- ARGV
# include colors.pl array.pl string.pl printhelp.pl

$HELP =~ s:\$FILE:$CD_\$FILE$CW_:g;
$HELP =~ s:\$PID:$CD_\$PID$CW_:g;

printhelp $HELP and exit if clar \@ARGV,"-h";
our $VERBOSE=1	if clar \@ARGV,"-v";
our $SHORT=1	if clar \@ARGV,"-s";
our $NOBLACK=1	if clar \@ARGV,"-nb";
our $NOGREEN=1	if clar \@ARGV,"-ng";
our $ALLBLACK=1	if clar \@ARGV,"-b";
our $PRIM=1	if clar \@ARGV,"-p";
our $FULLHDR=1	if clar \@ARGV,"-fh";
our $BW=1	if clar \@ARGV,"-bw";

our (@FILES,@wrong,@why);
for(@ARGV) {
  next if $_ eq "";							# must be non-empty
  if(-d $_)	      { push @wrong,$_; $why{$_}="directory"; next }	# must be file
  if(not -f $_)	      { push @wrong,$_; $why{$_}="not file"; next }	# must be file
  my $s = `file -L '$_'`;
  if(not $s=~/ ELF /) { push @wrong,$_; $why{$_}="not ELF"; next }	# must be ELF
  push @FILES,$_ }

$CR_=$CG_=$CC_=$CM_=$CW_=$CK_=$CD_="" if $BW;

for(@wrong) {
  my $c=$why{$_}=~m/file/?$CD_:$CG_;
  print STDERR "${CR_}wrong arg:$CD_ $c$_$CD_ $CK_$why{$_}$CD_\n" if $VERBOSE }
print STDERR "${CR_}input file required$CD_\n" and exit if not @FILES;

# ----------------------------------------------------------------------------------- FILES SELECTION
our %REAL; # symlinks resolved

# resolve symlinks, recursion=10
sub resolve {
  my $f = $_[0];
  return $f if not -l $f;
  for(my $i=0; $i<10; $i++) {
    my $d;
    if($f=~m:/:) {
      $d = $f;
      $d =~ s:/[^/]*$::;
      $d .= "/" }
    $f = $d . readlink $f;
    last if not -l $f }
  return $f }

$REAL{$_} = resolve $_ for @FILES;
# print "$_ -> $REAL{$_}\n" for @FILES; exit;

# remove duplicite links
my @files;
for my $f (@FILES) { # copy real files
  next if -l $f;
  push @files,$f }
for my $f (@FILES) { # copy links which are not duplicite
  next if not -l $f;
  if(inar \@files,$REAL{$f}) {
    print STDERR "${CR_}wrong arg:$CD_ $CC_$f$CD_ ${CK_}link to $REAL{$f}$CD_\n" if $VERBOSE;
    next }
  push @files,$f }
@FILES = @files; # replace

# ----------------------------------------------------------------------------------------- FILENAMES
our %DIR; # directory difference
our %FNM; # filename (shortened if possible)

# get dirnames vs filenames 
for my $f (@FILES) {
  my $fn = $f; $fn =~ s:^.*/::;
  my $d = $f if $f=~m:/:; $d =~ s:/[^/]*$::;
  $DIR{$f} = $d;
  $FNM{$f} = $fn }
# print "$_ => $DIR{$_} -> $FNM{$_}\n" for @FILES; # exit;

# remove common subdir parts from begin and end of $d

# prefix
my %dir = %DIR;
while(1) {
  my $ok=1;
  my @px;
  for my $f (@FILES) {
    $ok=0 and last if not $dir{$f};
    $ok=0 and last if not $dir{$f} =~ s:^([^/]*)/::;
    push @px,$1 }
  if($ok) { # all dirs have a prefix
    my $p=$px[0];
    for(@px) { $ok=0 and last if $_ ne $p }}
  if($ok) { $DIR{$_}=$dir{$_} for @FILES } # all prefixes are the same
  else { last }}

# suffix
my %dir = %DIR;
while(1) {
  my $ok=1;
  my @sx;
  for my $f (@FILES) {
    $ok=0 and last if not $dir{$f};
    $ok=0 and last if not $dir{$f} =~ s:/([^/]*)$::;
    push @sx,$1 }
  if($ok) { # all dirs have a suffix
    my $s=$sx[0];
    for(@sx) { $ok=0 and last if $_ ne $s }}
  if($ok) { $DIR{$_}=$dir{$_} for @FILES } # all suffixes are the same
  else { last }}

# shorten filenames
if($SHORT) {
  for my $f (@FILES) {
    $FNM{$f} =~ s/^lib//;
    $FNM{$f} =~ s/\.so\..*//;
    $FNM{$f} =~ s/-([\d.]*)\.so$// }}

# disable DIR or FNM if the same
my $same=1; my $d=$DIR{$FILES[0]};
for(@FILES) { $same=0 and last if $DIR{$_} ne $d }
undef %DIR if $same and (not $FULLHDR or $DIR{$FILES[0]} eq "");
my $same=1; my $d=$FNM{$FILES[0]};
for(@FILES) { $same=0 and last if $FNM{$_} ne $d }
undef %FNM if $same and not $FULLHDR;
# print "$_ -> [$DIR{$_}] / [$FNM{$_}]\n" for @FILES; exit;

# ---------------------------------------------------------------------------------------------- LOAD
our %LDDS; # raw `ldd` outputs
our %ODS;  # raw `od` outputs

my $i=1;
for my $f (@FILES) {
  printf STDERR "file %d: $CG_$f$CD_\n",$i++ if $VERBOSE;
  $ODS{$f} = `od -S 7 '$f' | grep -F lib | grep -F .so | cut -d ' ' -f 2 | sed 's:^.*/::' | grep '^lib' | sort -u`;
  $LDDS{$f} = `ldd '$f'` }
print STDERR "\n" if $VERBOSE;

# ------------------------------------------------------------------------------------------ IDENTIFY
our @ALL; # all base-names (like "libc")
our %LDD; # per-file ldds base-to-filename maps (like "bin1"->"libc" = "libc-2.0.so")
our %NOF; # per-file per-ldd not-found ldd-to-flag maps (like "bin1"->"libc-2.0.so" = 1)
our %PRI; # per-file per-ldd whether ldd is primary, i.e. is in the od list
our %NOL; # flag -> non-ldd ldd, i.e. not present in ldd output but present in the od

# multi
our %MLT; # per-file per-basename multiple ldds with the same basename in single file
	  # 0=no-multiple 1=two 2=three ...
our %ROW; # per-basename whether there exist a multi-ldd for this basename, later no. of rows

# return the basename
sub base { my $s=$_[0]; $s=~s/\..*$//; return $s }

# parse ldd output for every file
for my $f (@FILES) {
  for(split /\n/,$LDDS{$f}) {
    s/^\h*//; 
    next if not / => /;
    my $nof; $nof=1 if s/ => not found//;
    s/ => .*$//;
    $NOF{$f}{$_} = $nof; # here $_ is full ldd-name

    # whether primary
    my $q = quotemeta $_;
    $PRI{$f}{$_} = 1 if $ODS{$f} =~ /$q/;
    next if $PRIM and not $PRI{$f}{$_};

    # base name
    my $b = base $_;
    pushq \@ALL,$b;

    # single
    if(not defined $LDD{$f}{$b}) { $LDD{$f}{$b} = $_ }

    # multi
    else { # replace string with array
      $ROW{$b} = 1;
      $MLT{$f}{$b} += 1;

      # second, etc.
      if(ref $LDD{$f}{$b} eq "ARRAY") {
	push @{$LDD{$f}{$b}},$_ }

      # first
      else {
	my @a;
	push @a,$LDD{$f}{$b};
	push @a,$_;
	$LDD{$f}{$b} = \@a }}}}

# add non-ldds from the ods list
for my $f (@FILES) {
  my $b0; $b0 = base $f if $f=~/\.so/;
  for(split /\n/,$ODS{$f}) {
    my $b = base $_;
    next if $b eq $b0;

    # missing
    if(not defined $LDD{$f}{$b}) {
      $LDD{$f}{$b} = $_;
      $NOL{$f}{$_} = 1;
      pushq \@ALL,$b }

    # new multi
    elsif(ref $LDD{$f}{$b} eq "ARRAY" and not inar $LDD{$f}{$b},$_) {
      push @{$LDD{$f}{$b}},$_;
      $MLT{$f}{$b} += 1;
      $NOL{$f}{$_} = 1 }

    # defined but different => make it multi!
    elsif(ref $LDD{$f}{$b} ne "ARRAY" and $LDD{$f}{$b} ne $_) {
      $ROW{$b} = 1;
      $MLT{$f}{$b} += 1;
      my @a;
      push @a,$LDD{$f}{$b};
      push @a,$_;
      $LDD{$f}{$b} = \@a;
      $NOL{$f}{$_} = 1 }}}
    # else: already resolved

# --------------------------------------------------------------------------------------------- MULTI

# re-sort multi columns, update ROW to be a no. of rows
for my $b (sort @ALL) {
  next if not $ROW{$b};
  my $n=0; my $m; # no. of rows, file with max of them
  for my $f (@FILES) { if($MLT{$f}{$b}>$n) { $n=$MLT{$f}{$b}; $m=$f }}

  my @max = sort @{$LDD{$m}{$b}}; # array: sorted max colums
  for my $f (@FILES) {
    my @cur; # array: current column
    if(ref $LDD{$f}{$b} eq "ARRAY") { @cur = sort @{$LDD{$f}{$b}} }
    else			    { @cur = ($LDD{$f}{$b}) }

    # resort every new column
    my @new; # array: new column
    CUR: for my $c (@cur) {
      for(my $i=$#max; $i>=0; $i--) {
	if($i==0 and $c le $max[$i]) { $new[$i]=$c; next CUR }
   	elsif($c ge $max[$i])	     { $new[$i]=$c; next CUR }
	else			     { $new[$i]="" }}}
    $LDD{$f}{$b} = \@new }

  $ROW{$b}=$n if $n }

# ---------------------------------------------------------------------------------------- STATISTICS
our %NAME; # final name to be displayed
our %LEN;  # per-file lengths of libs filenames 
our %NL;   # per-ldd number of filenames
our %N;    # per-file number of ldds
our %M;	   # per-file number of not-found ldds
our %NP;   # per-file number of not-primary ldds
our %NO;   # per-file number of not-ldd ldds (od only)
($LEN{$_},$N{$_},$M{$_},$P{$_})=(0,0,0,0) for @FILES;

# beuatify the ldd names
sub getname {
  my $s = $_[0];
  if($SHORT) {
    $s =~ s/^lib//;
    $s =~ s/\.so\./ /;
    $s =~ s/-([\d.]*)\.so$/ $1/ }
  return $s }

# do statistics for single file "$l"
sub getstat {
  my ($b,$f,$l) = @_;
  $NAME{$l} = getname $l if not defined $NAME{$l};
  $NL{$l}++;
  $N{$f}++;
  $M{$f}++ if $NOF{$f}{$l};
  $NP{$f}++ if not $PRI{$f}{$l};
  $NO{$f}++ if $NOL{$f}{$l};
  my $l=length($NAME{$l}); $LEN{$f}=$l if $l>$LEN{$f} }

# do statistics for all files
for my $f (@FILES) {
  for my $b (sort @ALL) {
    next if not $LDD{$f}{$b};
    if(ref $LDD{$f}{$b} eq "ARRAY") {
      for my $l (@{$LDD{$f}{$b}}) {
	next if not $l;
	getstat $b,$f,$l }}
    else {
      my $l = $LDD{$f}{$b};
      getstat $b,$f,$l }}}

# per-row specific
our %V;  # per-row list of different versions
for my $b (sort @ALL) {
  if(defined $ROW{$b}) { for(my $i=0; $i<=$ROW{$b}; $i++) {	# multi
    for(@FILES) { pushq \@{$V{$b}[$i]},$LDD{$_}{$b}[$i] if $LDD{$_}{$b}[$i] }}}
  else {							# simple
    for(@FILES) { pushq \@{$V{$b}},$LDD{$_}{$b} if $LDD{$_}{$b} }}}

# correct lengths according to FNM and DIR
for(@FILES) { my $l;
   if(%DIR) { $l=length($DIR{$_}); $LEN{$_}=$l if $l>$LEN{$_} }
   if(%FNM) { $l=length($FNM{$_}); $LEN{$_}=$l if $l>$LEN{$_} }}

# --------------------------------------------------------------------------------------------- PRINT

# colorize the library name
sub colorname {
  my ($c,$s) = @_;
  $s =~ s/^lib/${CK_}lib$c/    if not $SHORT;
  $s =~ s/\.so\./${CK_}.so.$c/ if not $SHORT;
  return $s }

# header: dirs
if($#FILES>0 and %DIR) {
  for(@FILES) { printf "$CK_%-$LEN{$_}s$CD_ ",$DIR{$_} } print "\n" }

# header: filenames
if(%FNM) {
  for(@FILES) {
    my $c = $CD_;
       $c = $CM_ if -x $_;
    my $s = colorname $c,$FNM{$_};
    my $sp = " "x($LEN{$_}-esclen($s));
    print "$c$s$CD_$sp " }
  print "\n"; }

# header: rule
print $CK_; for(@FILES) { print "-"x($LEN{$_})." " } print "$CD_\n";

# print a row
my sub prldd {
  my $f = $_[0]; # file name
  my $b = $_[1]; # ldd base name
  my $i = $_[2]; # multi index
  my $l = $LDD{$f}{$b}; # ldd name
     $l = $LDD{$f}{$b}[$i] if defined $i;
  my @v = @{$V{$b}};
     @v = @{$V{$b}[$i]} if defined $i;
  my $m = $#FILES+1;
  my $c = $CD_;
     if(not $NOBLACK) {
       if($ALLBLACK and $NL{$l}==$m) { $c = $CK_ } # all versions equal and nonempty
       elsif($#v<1 and $m>1) {			   # only one version in a row
	 if($ALLBLACK) { $c = $CW_ }
	 else	    { $c = $CK_ }}}
     $c = $CG_ if not $PRI{$f}{$l} and not $NOGREEN;
     $c = $CR_ if $NOF{$f}{$l}==1;
     $c = $CM_ if $NOL{$f}{$l};
  my $s = colorname $c,$NAME{$l};
     $s = "$CK_ .$CD_" if $NAME{$l} eq "";
     $s = "$CK_.$CD_"   if $NAME{$l} eq "" and $SHORT;
  my $sp = " "x($LEN{$f}-esclen($s));
  return "$c$s$CD_$sp " }

# print all rows
for my $b (sort @ALL) {
  if(defined $ROW{$b}) { for(my $i=0; $i<=$ROW{$b}; $i++) {	# multi
    print prldd $_,$b,$i for @FILES; print "\n" }}
  else {							# simple
    print prldd $_,$b for @FILES; print "\n" }}

# footer: rule
print $CK_; for(@FILES) { print "="x($LEN{$_})." " } print "$CD_\n";

# footer: statistics
for(@FILES) {
  my $n = $N{$_};
     $n-= $NO{$_} if $NO{$_};
  my $s1="$CD_$n$CK_";
     $s1.="-$CG_$NP{$_}$CK_" if $NP{$_};
     $s1.="-$CR_$M{$_}$CK_" if $M{$_};
     $s1.="+$CM_$NO{$_}" if $NO{$_};
     $s1.=$CD_;
  my $sp1=" "x($LEN{$_}-esclen($s1));
  print "$s1$sp1 " }
print "\n";

# -------------------------------------------------------------------------------- R.Jaksa 2024 GPLv3
