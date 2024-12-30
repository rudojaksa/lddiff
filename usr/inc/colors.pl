# colors.pl generated from libpl-0.3c/src/colors.pl 2024-11-26
{ # TERMINAL COLORS

our $CR_="\033[31m"; # color red
our $CG_="\033[32m"; # color green
our $CY_="\033[33m"; # color yellow
our $CB_="\033[34m"; # color blue
our $CM_="\033[35m"; # color magenta
our $CC_="\033[36m"; # color cyan
our $CW_="\033[37m"; # color white
our $CK_="\033[90m"; # color black
our $CP_="\033[91m"; # color pink
our $CL_="\033[92m"; # color lime
our $CS_="\033[93m"; # color sulphur yellow
our $CZ_="\033[94m"; # color azure
our $CO_="\033[95m"; # color orchid
our $CA_="\033[96m"; # color aqua cyan
our $CF_="\033[97m"; # color fluorescent white
our $CD_="\033[0m";  # color default

# return length of string without escape sequences
our sub esclen { my $s = $_[0];
  $s =~ s/\033\[[0-9]+m//g;
  return length $s; }

sub CK { return "$CK_$_[0]$CD_" }
sub CC { return "$CC_$_[0]$CD_" }
sub CW { return "$CW_$_[0]$CD_" }

} # R.Jaksa 2003,2008,2019,2024 GPLv3
