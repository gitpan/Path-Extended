package Path::Extended::Entity;

use strict;
use warnings;
use File::Spec;
use Scalar::Util qw( blessed );

use overload
  '""'  => sub { shift->_path },
  'cmp' => sub { return "$_[0]" cmp "$_[1]" },
  '*{}' => sub { shift->_handle };

sub new {
  my $class = shift;
  my $self  = bless {}, $class;

  $self->_initialize(@_);

  $self;
}

sub _initialize {}

sub _path   { shift->{path} }
sub _handle { shift->{handle} }

sub is_open { shift->{handle} ? 1 : 0 }

sub logger {
  my $class = shift;
  @_ ? $class->{logger} = shift : $class->{logger};
}

sub log {
  my $self = shift;

  if ( blessed $self->logger and $self->logger->can('log') ) {
    $self->logger->log(@_);
  }
  elsif ( defined $self->{logger} and !$self->{logger} ) {
    return;
  }
  else {
    my $level = shift;

    require Data::Dump;
    my $msg = join '', map { ref $_ ? Data::Dump::dump($_) : $_ } @_;

    if ( $level eq 'fatal' ) {
      require Carp;
      Carp::croak "[$level] $msg";
    }
    elsif ( $level eq 'error' or $level eq 'warn' ) {
      require Carp;
      Carp::carp "[$level] $msg";
    }
    else {
      print STDERR "[$level] $msg\n";
    }
  }
}

sub absolute {
  my ($self, %options) = @_;

  my $path = File::Spec->canonpath( $self->{path} );
     $path = $self->_unixify($path) unless $options{native};

  $path;
}

sub relative {
  my ($self, %options) = @_;

  my $path = File::Spec->abs2rel( $self->{path}, $options{base} );
     $path = $self->_unixify($path) unless $options{native};

  $path;
}

sub unlink {
  my $self = shift;

  $self->close if $self->is_open;
  unlink $self->absolute if $self->exists;
}

sub exists {
  my $self = shift;

  -e $self->absolute ? 1 : 0;
}

sub copy_to {
  my ($self, $destination) = @_;

  unless ( $destination ) {
    $self->log( fatal => 'requires destination' );
    return;
  }

  my $class = ref $self;
  $destination = $class->new( "$destination" );

  require File::Copy::Recursive;
  File::Copy::Recursive::rcopy( $self->absolute, $destination->absolute )
    or do { $self->log( error =>  $! ); return; };

  $self;
}

sub move_to {
  my ($self, $destination) = @_;

  unless ( $destination ) {
    $self->log( fatal => 'requires destination' );
    return;
  }

  my $class = ref $self;
  $destination = $class->new( "$destination" );

  $self->close if $self->is_open;

  require File::Copy::Recursive;
  File::Copy::Recursive::rmove( $self->absolute, $destination->absolute )
    or do { $self->log( error =>  $! ); return; };

  $self->{path} = $destination->absolute;

  $self;
}

sub rename_to {
  my ($self, $destination) = @_;

  unless ( $destination ) {
    $self->log( fatal => 'requires destination' );
    return;
  }

  my $class = ref $self;
  $destination = $class->new( "$destination" );

  $self->close if $self->is_open;

  rename $self->absolute => $destination->absolute
    or do { $self->log( error => $! ); return; };

  $self->{path} = $destination->absolute;

  $self;
}

sub _unixify {
  my ($self, $path) = @_;

  $path =~ s{\\}{/}g if $^O eq 'MSWin32';

  return $path;
}

sub parent {
  my $self = shift;

  require Path::Extended::Dir;
  Path::Extended::Dir->new_from_file( $self->absolute );
}

1;

__END__

=head1 NAME

Path::Extended::Entity

=head1 SYNOPSIS

  use Path::Extended::File;
  my $file = Path::Extended::File->new('path/to/some.file');

=head1 DESCRIPTION

This is a base class for L<Path::Extended::File> and L<Path::Extended::Dir>.

=head1 METHODS

=head2 new

creates an appropriate object. Note that this base class itself doesn't hold anything.

=head2 absolute

may take an optional hash, and returns an absolute path of the file/directory. Note that back slashes in the path will be converted to forward slashes unless you explicitly set a C<native> option to true.

=head2 relative

may take an optional hash, and returns a relative path of the file/directory (compared to the current directory (Cwd::cwd) by default, but you may change this bahavior by passing a C<base> option). Note that back slashes in the path will be converted to forward slashes unless you explicitly set a C<native> option to true.

=head2 copy_to

copies the file/directory to the destination by File::Copy::copy.

=head2 move_to

moves the file/directory to the destination by File::Copy::move. If the file/directory is open, it'll automatically close.

=head2 rename_to

renames the file/directory. If the file/directory is open, it'll automatically close. If your OS allows rename of an open file, you may want to use built-in C<rename> function for better atomicity.

=head2 unlink

unlinks the file/directory. The same thing can be said as for the C<rename_to> method.

=head2 exists

returns true if the file/directory exists.

=head2 is_open

returns true if the file/directory is open.

=head2 parent

returns a Path::Extended::Dir object that points to the parent directory of the file/directory.

=head2 logger

You may optionally pass a logger object with C<log> method that accepts C<( loglevel => @log_messages )> array arguments to notifty when some (usually unfavorable) thing occurs. By default, a built-in L<Carp> logger will be used. If you want to disable log, set a false value to C<logger>.

=head2 log

You can pass a loglevel and arbitrary messages to the logger. References will be dumped with L<Data::Dump> by default.

=head1 SEE ALSO

L<Path::Extended>, L<Path::Extended::File>, L<Path::Extended::Dir>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
