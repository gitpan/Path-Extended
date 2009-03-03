package Path::Extended::Class::File;

use strict;
use warnings;
use base qw( Path::Extended::File );

sub _initialize {
  my ($self, @args) = @_;

  my $file = File::Spec->catfile( @args );
  $self->{path}      = $self->_unixify( File::Spec->rel2abs($file) );
  $self->{_compat}   = 1;
  $self->{_absolute} = File::Spec->file_name_is_absolute( $file );

  $self;
}

sub is_dir     { 0 }
sub dir        { shift->parent }
sub volume     { shift->parent->volume }
sub cleanup    { shift } # is always clean
sub as_foreign { shift } # does nothing

1;

__END__

=head1 NAME

Path::Extended::Class::File

=head1 DESCRIPTION

L<Path::Extended::Class::File> behaves pretty much like L<Path::Class::File> and can do some extra things. See appropriate pods for details.
=head1 COMPATIBLE METHODS

=head2 is_dir

is just a convenient flag which is always false for L<Path::Extended::Class::File>.

=head2 dir

returns a parent L<Path::Extended::Class::Dir> object of the file.

=head2 volume

returns a volume of the path (if any).

=head1 INCOMPATIBLE METHODS

=head2 cleanup

does nothing but returns the object to chain. L<Path::Extended::Class> should always return a canonical path.

=head2 as_foreign

does nothing but returns the object to chain. L<Path::Extended::Class> doesn't support foreign path expressions.

=head1 MISSING METHOD

As of writing this, following method is missing.

=over 4

=item new_foreign

=back

=head1 SEE ALSO

L<Path::Extended::Class>, L<Path::Extended::File>, L<Path::Class::File>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
