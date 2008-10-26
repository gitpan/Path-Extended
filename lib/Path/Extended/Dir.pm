package Path::Extended::Dir;

use strict;
use warnings;
use base qw( Path::Extended::Entity );
use Path::Extended::File;

sub _initialize {
  my ($self, @args) = @_;

  unless ( @args ) {
    @args = Cwd::cwd();
  }
  my $dir = $self->_unixify(
    File::Spec->rel2abs( File::Spec->catdir( @args ) )
  );

  $self->{path} = $dir;

  $self;
}

sub new_from_file {
  my ($class, $file) = @_;

  require File::Basename;
  my $dir = File::Basename::dirname( $file );

  my $self = $class->new( $dir );
}

sub open {
  my $self = shift;

  $self->close if $self->is_open;

  opendir my $dh, $self->absolute
    or do { $self->log( error => $! ); return; };

  $self->{handle} = $dh;

  $self;
}

sub close {
  my $self = shift;

  if ( my $dh = delete $self->{handle} ) {
    closedir $dh;
  }
}

sub read {
  my $self = shift;

  return unless $self->is_open;

  my $dh = $self->_handle;
  readdir $dh;
}

sub seek {
  my ($self, $pos) = @_;

  return unless $self->is_open;

  my $dh = $self->_handle;
  seekdir $dh, $pos || 0;
}

sub tell {
  my $self = shift;

  return unless $self->is_open;

  my $dh = $self->_handle;
  telldir $dh;
}

sub rewind {
  my $self = shift;

  return unless $self->is_open;

  my $dh = $self->_handle;
  rewinddir $dh;
}

sub find {
  my ($self, $rule, %options) = @_;

  $self->_find( file => $rule, %options );
}

sub find_dir {
  my ($self, $rule, %options) = @_;

  $self->_find( directory => $rule, %options );
}

sub _find {
  my ($self, $type, $rule, %options) = @_;

  return unless $type =~ /^(?:directory|file)$/;

  require File::Find::Rule;
  my $package = 'Path::Extended::' . ($type eq 'file' ? 'File' : 'Dir' );

  my @items = grep { $_ !~ m{/\.} }
              map  { $self->_unixify($_) }
              File::Find::Rule->$type->name($rule)->in($self->absolute);

  if ( $options{callback} ) {
    @items = $options{callback}->( @items );
  }

  return grep { defined } map { $package->new($_) } @items;
}

sub rmdir {
  my $self = shift;

  if ( $self->exists ) {
    require File::Path;
    eval { File::Path::rmtree( $self->absolute ) };
    do { $self->log( error => $@ ); return; } if $@;
  }
  $self;
}

sub mkdir {
  my $self = shift;

  unless ( $self->exists ) {
    require File::Path;
    eval { File::Path::mkpath( $self->absolute ) };
    do { $self->log( error => $@ ); return; } if $@;
  }
  $self;
}

1;

__END__

=head1 NAME

Path::Extended::Dir

=head1 SYNOPSIS

  use Path::Extended::Dir;

  my $dir = Path::Extended::Dir->new('path/to/somewhere');
  my $parent_dir = Path::Extended::Dir->new_from_file('path/to/some.file');

  foreach my $file ( $dir->find('*.txt') ) {
    print $file->relative, "\n";  # each $file is a L<Path::Extended::File> object.
  }

=head1 DESCRIPTION

This class implements several directory-specific methods. See also L<Path::Class::Entity> for common methods like copy and move.

=head1 METHODS

=head2 new, new_from_file

takes a path or parts of a path of a directory (or a file in the case of C<new_from_file>), and creates a L<Path::Extended::Dir> object. If the path specified is a relative one, it will be converted to the absolute one internally. 

=head2 open, close, read, seek, tell, rewind

are simple wrappers of the corresponding built-in functions (with the trailing 'dir').

=head2 mkdir

makes the directory via C<File::Path::mkpath>.

=head2 rmdir

removes the directory via C<File::Path::rmtree>.

=head2 find, find_dir

takes a L<File::Find::Rule>'s rule and a hash option, and returns C<Path::Extended::*> objects of the matched files (C<find>) or directories (C<find_dir>) under the directory the $self object points to. Options are:

=over 4

=item callback

You can pass a code reference to filter the objects.

=back

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
