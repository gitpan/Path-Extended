package Path::Extended::Test::Compatibility::Filesystem;

use strict;
use warnings;
use Test::Classy::Base;
use Path::Extended::Class;

# ripped from Path::Class' t/03-filesystem.t

sub tests00_file : Tests(9) {
  my $class = shift;

  my $file = file('t', 'testfile');
  ok $file, $class->message("test 02");

  {
    my $fh = $file->open('w');
    ok $fh, $class->message("test 03");
    ok( (print $fh "Foo\n"), $class->message("test 04"));
  }

  ok -e $file, $class->message("test 05");

  {
    my $fh = $file->open;
    is scalar <$fh>, "Foo\n", $class->message("test 06");
  }

  my $stat = $file->stat;
  ok $stat, $class->message("test 07");
  cmp_ok $stat->mtime, '>', time() - 20, $class->message("test 08");

  $stat = $file->dir->stat;
  ok $stat, $class->message("test 09");

  1 while unlink $file;
  ok( (not -e $file), $class->message("test 10"));
}

sub tests01_dir : Tests(26) {
  my $class = shift;

  my $dir = dir('t', 'testdir');
  ok $dir, $class->message("test 11");

  $dir->remove if $dir->exists;

  ok mkdir($dir, 0777), $class->message("test 12");
  ok -d $dir, $class->message("test 13");

  my $file = $dir->file('foo.x');
  $file->touch;
  ok -e $file, $class->message("test 14");

  {
    my $dh = $dir->open;
    ok $dh, $class->message("test 15");

    my @files = readdir $dh;
    is scalar @files, 3, $class->message("test 16");
    ok( (scalar grep { $_ eq 'foo.x' } @files), $class->message("test 17"));
  }

  ok $dir->rmtree, $class->message("test 18");
  ok !-e $dir, $class->message("test 19");

  $dir = dir('t', 'foo', 'bar');
  ok $dir->mkpath, $class->message("test 20");
  ok -d $dir, $class->message("test 21");

  $dir = $dir->parent;
  ok $dir->rmtree, $class->message("test 22");
  ok !-e $dir, $class->message("test 23");

  $dir = dir('t', 'foo');
  ok $dir->mkpath, $class->message("test 24");
  ok $dir->subdir('dir')->mkpath, $class->message("test 25");
  ok -d $dir->subdir('dir'), $class->message("test 26");

  ok $dir->file('file.x')->open('w'), $class->message("test 27");
  ok $dir->file('0')->open('w'), $class->message("test 28");

  my @contents;
  while (my $file = $dir->next) {
    push @contents, $file;
  }
  is scalar @contents, 5, $class->message("test 29");

  my $joined = join ' ', map $_->basename, sort grep {-f $_} @contents;
  is $joined, '0 file.x', $class->message("test 30");
  my ($subdir) = grep {$_ eq $dir->subdir('dir')} @contents;
  ok $subdir, $class->message("test 31");
  is -d $subdir, 1, $class->message("test 32");

  ($file) = grep {$_ eq $dir->file('file.x')} @contents;
  ok $file, $class->message("test 33");
  is -d $file, '', $class->message("test 34");

  ok $dir->rmtree, $class->message("test 35");
  ok !-e $dir, $class->message("test 36");
}

sub tests02_slurp : Tests(6) {
  my $class = shift;

  my $file = file('t', 'slurp');
  ok $file, $class->message("test 37");

  my $fh = $file->open('w') or die "Can't create $file: $!";
  print $fh "Line1\nLine2\n";
  close $fh;
  ok -e $file, $class->message("test 38");

  my $content = $file->slurp;
  is $content, "Line1\nLine2\n", $class->message("test 39");

  my @content = $file->slurp;
  is_deeply \@content, ["Line1\n", "Line2\n"], $class->message("test 40");

  @content = $file->slurp(chomp => 1);
  is_deeply \@content, ["Line1", "Line2"], $class->message("test 41");

  $file->remove;
  ok((not -e $file), $class->message("test 42"));
}

sub test03_absolute_relative : Test Skip('known incompatibility') {
  my $class = shift;

  my $cwd = dir();
  is $cwd, $cwd->absolute->relative, $class->message("test 43");
}

sub tests04_subsumes : Tests(4) {
  my $class = shift;

  my $t = dir('t');
  my $foo_bar = $t->subdir('foo','bar');
  $foo_bar->rmtree;

  ok  $t->subsumes($foo_bar), $class->message("test 44");
  ok !$t->contains($foo_bar), $class->message("test 45");

  $foo_bar->mkpath;
  ok  $t->subsumes($foo_bar), $class->message("test 46");
  ok  $t->contains($foo_bar), $class->message("test 47");

  $t->subdir('foo')->rmtree;
}

sub tests05_children : Tests(1) {
  my $class = shift;

  (my $abe = dir(qw(a b e)))->mkpath;
  (my $acf = dir(qw(a c f)))->mkpath;
  file($acf, 'i')->touch;
  file($abe, 'h')->touch;
  file($abe, 'g')->touch;
  file('a', 'b', 'd')->touch;

  my $a = dir('a');
  my @children = $a->children;

  is_deeply \@children, ['a/b', 'a/c'];

  $a->rmtree;
}

sub END {
  my $class = shift;

  dir('a')->rmtree;
  dir('t/foo')->remove;
  dir('t/testdir')->remove;
  file('t/testfile')->remove;
}

1;
