package Path::Extended::Test::Dir::Find;

use strict;
use warnings;
use Test::Classy::Base;
use Path::Extended;

sub find : Tests(4) {
  my $class = shift;

  my $dir = dir('t/tmp/find')->mkdir;

  my $file1 = file('t/tmp/find/some.txt');
     $file1->save('some content');

  my $file2 = file('t/tmp/find/other.txt');
     $file2->save('other content');

  my @files = $dir->find('*.txt');
  ok @files == 2, $class->message('found two files');

  ok( (grep { $_->isa('Path::Extended::File') } @files) == 2,
    $class->message('both files are Path::Extended::File objects'));

  my @should_not_be_found = $dir->find('*.jpeg');
  ok @should_not_be_found == 0, $class->message('found nothing');

  my @filtered = $dir->find('*.txt',
    callback => sub { grep { $_ =~ /some/ } @_ }
  );
  ok @filtered == 1 && $filtered[0]->basename eq 'some.txt',
    $class->message('found some.txt');

  $dir->rmdir;
}

sub find_dir : Tests(4) {
  my $class = shift;

  my $dir  = dir('t/tmp/find_dir');
  my $dir1 = dir('t/tmp/find_dir/found')->mkdir;
  my $dir2 = dir('t/tmp/find_dir/not_found')->mkdir;

  my @dirs = $dir->find_dir('*');
  ok @dirs == 2, $class->message('found two directories');

  ok( (grep { $_->isa('Path::Extended::Dir') } @dirs) == 2,
    $class->message('both directories are Path::Extended::Dir objects'));

  my @should_not_be_found = $dir->find('yes');
  ok @should_not_be_found == 0, $class->message('found nothing');

  my @filtered = $dir->find_dir('*',
    callback => sub { grep { $_ =~ /not/ } @_ }
  );
  ok @filtered == 1, $class->message('found ' . $filtered[0]->relative);

  $dir->rmdir;
}

sub private_error : Test {
  my $class = shift;

  my $dir = dir('t/tmp');
  ok !$dir->_find( dir => '*' ), $class->message('invalid type');
}

1;
