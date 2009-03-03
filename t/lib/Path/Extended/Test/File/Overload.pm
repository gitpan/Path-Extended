package Path::Extended::Test::File::Overload;

use strict;
use warnings;
use Test::Classy::Base;
use Path::Extended;

sub compare : Tests(2) {
  my $class = shift;

  my $file1 = file('t/tmp/file1');
  my $file2 = file('t/tmp/file2');

  ok $file1 ne $file2,    $class->message('ne works');
  ok !($file1 eq $file2), $class->message('eq works');
}

sub handle : Test {
  my $class = shift;

  my $file = file('t/tmp/overload.txt');
     $file->touch;
     $file->openw;
  print $file 'content';
  $file->close;

  ok $file->slurp eq 'content', $class->message('as a file handle');

  $file->unlink;
}

1;