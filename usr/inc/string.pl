# string.pl generated from libpl-0.3c/src/string.pl 2024-11-26
{ # SIMPLE STRING ROUTINES

# remove the last newline from string
our sub nonl { my $s=$_[0]; chomp $s; return $s }

# remove all newlines from a string, replace them with spaces
our sub unnl {
  my $s=$_[0];
  $s =~ s/\n+$//;
  $s =~ s/\n/ /g;
  return $s }

# remove spaces around a string
our sub nosp { my $s=$_[0]; $s=~s/^\h*(.*?)\h*$/$1/; return $s }

# unquote strings: "['o','n']" -> "[o,n]"
our sub unquote { my $s=$_[0]; $s=~s/'([^']+)'/$1/g; return $s }

} # R.Jaksa 2024 GPLv3
