# printhelp.pl generated from helpman-0.3/src/printhelp.pl 2024-10-21
{ # PRINT A MAN-STYLE HELP
  # require colors.pl

our sub printhelp {
  my $help = $_[0];

  # we will store parsed text elements in this private hash
  my %STR;				# private substitutions content strings
  my $id=0;				# last ID

  # in the text these elements will be repled by this string
  my ($L,$R) = ("\#\#\>","\<\#\#");	# private left/right brace
  my sub REP { return "$L$_[0]$R"; }	# return complete private substitution identifier

  # ------------------------------------------------------------------------ PREPROCESSOR

  $help =~ s/(\n\#.*)*\n/\n/g;		# skip commented-out lines
  $help =~ s/\\\)/REP "brc2"/eg;	# save escaped bracket

  # ------------------------------------------------------------------------------ PARSER

  # CC(text)
  my $colors = "CWRDKGMB";
  my $RE1 = qr/(\((([^()]|(?-3))*)\))/x; # () group, $1=withparens, $2=without
  $STR{$id++}=$4 while $help =~ s/([^A-Z0-9])(C[$colors])$RE1/$1.REP("c$2$id")/e;

  # 'xyz'
  $STR{$id++}="$2" while $help =~ s/([^A-Z0-9])`([^`]+)`/$1.REP("cCC$id")/e;

  # options lists, like -option ...
  $STR{$id++}=$2 while $help =~ s/(\n[ ]*)(-[a-zA-Z0-9_\/-]+(\[?[ =][A-Z]{2,}(x[A-Z]{2,})?\]?)?)([ \t])/$1.REP("op$id").$5/e;

  # bracketed uppercase words, like [WORD]
  $STR{$id++}="$1$2" while $help =~ s/\[([+-])?([A-Z_\/-]+)\]/REP("br$id")/e;

  # plain uppercase words, like sections headers
  $STR{$id++}=$2 while $help =~ s/(\n|[ \t])(([A-Z_\/-]+[ ]?){4,})/$1.REP("pl$id")/e;

  # --------------------------------------------------------------------------- PROCESSOR

  # re-substitute
  $help =~ s/${L}pl([0-9]+)$R/$CC_$STR{$1}$CD_/g;	# plain uppercase words
  $help =~ s/${L}op([0-9]+)$R/$CC_$STR{$1}$CD_/g;	# options
  $help =~ s/${L}br([0-9]+)$R/\[$CC_$STR{$1}$CD_\]/g;	# bracketed words

  # CC(text)
  my %cc; $cc{$_} = ${"C".$_."_"} for split //,$colors;
  $help =~ s/${L}cC([$colors])([0-9]+)$R/$cc{$1}$STR{$2}$CD_/g;

  # escapes
  $help =~ s/${L}brc2$R/)/g;

  # ----------------------------------------------------------------------- POSTPROCESSOR

  # star bullets
  $help =~ s/\n(\h\h+)\* /\n$1$CC_\*$CD_ /g;

  print $help; }

} # R.Jaksa 2015,2019,2024 GPLv3
