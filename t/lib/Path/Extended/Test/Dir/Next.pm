package Path::Extended::Test::Dir::Next;

use strict;
use warnings;
use Test::Classy::Base;
use Path::Extended;

sub next : Tests(4) {
  my $class = shift;

  my $dir = dir('t/tmp/next')->mkdir;

  ok $dir->exists, $class->message('made directory');

  my $file1 = file('t/tmp/next/file1.txt')->save('content1');
  my $file2 = file('t/tmp/next/file2.txt')->save('content2');

  ok !$dir->is_open, $class->message('directory is not open');

  my (@files, @dirs);
  while ( my $item = $dir->next ) {
    push @files, $item if -f $item;
    push @dirs,  $item if -d $item; # including '.' and '..'
  }
  ok @files == 2, $class->message('found two files');

  ok !$dir->is_open, $class->message('directory is not open');

  $dir->rmdir;
}

1;
