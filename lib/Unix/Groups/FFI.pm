package Unix::Groups::FFI;

use strict;
use warnings;
use Errno 'EINVAL';
use Exporter 'import';
use FFI::Platypus;

use constant MAX_NGROUPS_MAX => 65536;

our $VERSION = '0.001';

our @EXPORT_OK = qw(getgroups setgroups initgroups);

my $ffi = FFI::Platypus->new(lib => [undef], ignore_not_found => 1);

$ffi->attach(getgroups => ['int', 'gid_t[]'] => 'int', sub {
  my ($xsub) = @_;
  my $count = $xsub->(0, []);
  die "$!" if $count < 0;
  return () if $count == 0;
  my @groups = (0)x$count;
  my $rc = $xsub->($count, \@groups);
  if ($rc < 0 and $! == EINVAL) {
    @groups = (0)x(MAX_NGROUPS_MAX);
    $rc = $xsub->(MAX_NGROUPS_MAX, \@groups);
  }
  die "$!" if $rc < 0;
  return @groups[0..$rc-1];
});

$ffi->attach(setgroups => ['size_t', 'gid_t[]'] => 'int', sub {
  my ($xsub, @groups) = @_;
  my $rc = $xsub->(scalar(@groups), \@groups);
  die "$!" if $rc < 0;
  return 0;
});

$ffi->attach(initgroups => ['string', 'gid_t'] => 'int', sub {
  my ($xsub, $user, $group) = @_;
  $group = (getpwnam($user))[3] unless defined $group;
  my $rc = $xsub->($user, $group);
  die "$!" if $rc < 0;
  return 0;
});

1;

=head1 NAME

Unix::Groups::FFI - Interface to Unix group syscalls

=head1 SYNOPSIS

  use Unix::Groups::FFI qw(getgroups setgroups initgroups);

  my @gids = getgroups;
  setgroups(@gids);
  initgroups($username, $gid);

=head1 DESCRIPTION

This module provides a FFI interface to several syscalls related to Unix
groups, including L<getgroups(2)>, L<setgroups(2)>, and L<initgroups(3)>. As
such it will only work on Unix-like operating systems.

=head1 EXCEPTION HANDLING

All functions will throw an exception containing the syscall error message on
error. L<perlvar/"$!"> will also have been set by the syscall, so you could
check it after trapping the exception for finer exception handling:

  use Unix::Groups::FFI 'setgroups';
  use Syntax::Keyword::Try;
  use Errno qw(EINVAL EPERM ENOMEM);

  try { setgroups((0)x2**16) }
  catch {
    if ($! == EINVAL) {
      die 'Tried to set too many groups';
    } elsif ($! == EPERM) {
      die 'Insufficient privileges to set groups';
    } elsif ($! == ENOMEM) {
      die 'Out of memory';
    } else {
      die $@;
    }
  }

=head1 FUNCTIONS

All functions are exported individually on demand. A function will not be
available for export if the system does not implement the corresponding
syscall.

=head2 getgroups

  my @gids = getgroups;

Returns the supplementary group IDs of the current process, as in
L<getgroups(2)>.

=head2 setgroups

  setgroups(@gids);

Sets the supplementary group IDs for the current process, as in
L<setgroups(2)>.

=head2 initgroups

  initgroups($username, $gid);
  initgroups($username);

Initializes the supplementary group access list for the current process to all
groups of which C<$username> is a member, also including C<$gid>, as in
L<initgroups(3)>. As a special case, the primary group ID of the given username
is included if C<$gid> is not defined.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<POSIX>, L<credentials(7)>
