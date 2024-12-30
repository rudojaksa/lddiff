# array.pl generated from libpl-0.3c/src/array.pl 2024-11-26
{ # PERL ARRAYS SUPPORT

# inar newgen, returns index+1 instead of simple 0/1
# inar \@a,$s; check whether the string is in the array, return its idx+1 or zero (1st match)
our sub inar {
  my $a=$_[0];	# array ref
  my $s=$_[1];	# string
  for(my $i=0;$i<=$#{$a};$i++) { return $i+1 if $$a[$i] eq $s; }
  return 0; }

# clar \@a,$s; clear the string in the array (1st match), return its idx+1 or zero
our sub clar {
  my $a=$_[0];	# array ref
  my $s=$_[1];	# string
  for(my $i=0;$i<=$#{$a};$i++) {
    if($$a[$i] eq $s) {
      $$a[$i] = "";
      return $i+1; }}
  return 0; }

# pushq \@a,$s; string push unique, only if not there
our sub pushq {
  my $a=$_[0];	# array ref
  my $s=$_[1];	# string
  return if inar $a,$s;
  push @{$a},$s; }

# inar \@a,$s; checks whether the string $s is in an array @a
# sub inar { for(@{$_[0]}) { return 1 if $_ eq $_[1] } return 0 }

# delar \@a,$s; removes 1st instance of the string $s from an array @a, i.e. set it to empty ""
our sub delar { for(@{$_[0]}) { $_="" if $_ eq $_[1] }}

# return the length of array without empty "" elements
our sub lenar { my $i=0; for(@{$_[0]}) { $i++ if $_ ne "" } return $i }

# $prevailing = prevails \@array; returns most prevailing value in array
our sub prevails {
  my %n; $n{$_}++ for @{$_[0]}; # count appearances per value
  my $m=(keys %n)[0]; for(keys %n) { $m=$_ if $n{$_}>$n{$m} } # most prevailing
  return $m }

# remove duplicate elements, reorder according to frequency of elements and they orig. order
# @new = uique \@old;
our sub unique {
  my %n; # per-element counts
  my @o; # original order
  for(@{$_[0]}) {
    if(defined $n{$_}) { $n{$_}++ }
    else { $n{$_}=1; push @o,$_ }}
  # print "$_: $n{$_}x\n" for @o;
  my %r; # reverse per-count elements
  push @{$r{$n{$_}}},$_ for @o;
  my @a; # final array
  push @a,@{$r{$_}} for reverse sort keys %r;
  return @a }

} # R.Jaksa 2008,2024 GPLv3
