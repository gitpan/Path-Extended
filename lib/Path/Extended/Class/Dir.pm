package Path::Extended::Class::Dir;

use strict;
use warnings;
use base qw( Path::Extended::Dir );

sub _initialize {
  my ($self, @args) = @_;

  my $dir = @args ? File::Spec->catdir( @args ) : File::Spec->curdir;

  $self->{path}      = $self->_unixify( File::Spec->rel2abs($dir) );
  $self->{_compat}   = 1;
  $self->{_absolute} = File::Spec->file_name_is_absolute( $dir );

  $self;
}

sub is_dir     { 1 }
sub cleanup    { shift } # is always clean
sub as_foreign { shift } # does nothing

sub file   { shift->_related( file => @_ ); }
sub subdir { shift->_related( dir  => @_ ); }

sub dir_list {
  my $self = shift;

  my @parts = $self->_parts;
  return @parts unless @_;

  my $offset = shift;
  $offset = @parts + $offset if $offset < 0;

  return wantarray ? @parts[$offset .. $#parts] : $parts[$offset] unless @_;

  my $length = shift;
  $length = @parts + $length - $offset if $length < 0;
  return @parts[$offset .. $length + $offset - 1];
}

sub _parts {
  my ($self, $abs) = @_;

  my $path = $abs ? $self->absolute : $self->_path;
  my ($vol, $dir, $file) = File::Spec->splitpath( $path );
  return split '/', "$dir$file";
}

sub volume {
  my $self = shift;

  my ($vol) = File::Spec->splitpath( $self->_path );
  return $vol;
}

sub subsumes {
  my ($self, $other) = @_;

  die "No second entity given to subsumes()" unless $other;
  $other = __PACKAGE__->new($other) unless UNIVERSAL::isa($other, __PACKAGE__);
  $other = $other->dir unless $other->is_dir;

  if ( $self->volume ) {
    return 0 if $other->volume eq $self->volume;
  }

  my @my_parts    = $self->_parts(1);
  my @other_parts = $other->_parts(1);

  return 0 if @my_parts > @other_parts;

  my $i = 0;
  while ( $i < @my_parts ) {
    return 0 unless $my_parts[$i] eq $other_parts[$i];
    $i++;
  }
  return 1;
}

sub contains {
  my ($self, $other) = @_;
  return !!(-d $self and (-e $other or -l $other) and $self->subsumes($other));
}

sub children {
  my ($self, %options) = @_;

  my $dh = $self->open or die "Can't open directory $self: $!";

  my @children;
  while ( my $entry = readdir $dh ) {
    next if (!$options{all} && ( $entry eq '.' || $entry eq '..' ));
    push @children,
      ( -d $entry ) ? $self->subdir($entry) : $self->file($entry);
  }
  return @children;
}

1;

__END__

=head1 NAME

Path::Extended::Class::Dir

=head1 DESCRIPTION

L<Path::Extended::Class::Dir> behaves pretty much like L<Path::Class::Dir> and can do some extra things. See appropriate pods for details.

=head1 COMPATIBLE METHODS

=head2 is_dir

is just a convenient flag which is always true for L<Path::Extended::Class::Dir>.

=head2 children

returns a list of L<Path::Extended::Class::File> and/or L<Path::Extended::Class::Dir> objects listed in the directory. See L<Path::Class::Dir> for details.

=head2 file, subdir

returns a child L<Path::Extended::Class::File>/L<Path::Extended::Class::Dir> object in the directory. See L<Path::Class::Dir> for details.

=head2 volume

returns a volume of the path (if any).

=head2 dir_list

returns parts of the path. See L<Path::Class::Dir> for details.

=head2 subsumes, contains

returns if the path belongs to the object, or vice versa. See L<Path::Class::Dir> for details.

=head1 INCOMPATIBLE METHODS

=head2 cleanup

does nothing but returns the object to chain. L<Path::Extended::Class> should always return a canonical path.

=head2 as_foreign

does nothing but returns the object to chain. L<Path::Extended::Class> doesn't support foreign path expressions.

=head1 MISSING METHODS

As of writing this, following methods are missing.

=over 4

=item new_foreign

=item recursive

=back

=head1 SEE ALSO

L<Path::Extended::Class>, L<Path::Extended::Dir>, L<Path::Class::Dir>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
