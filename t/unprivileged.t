use strict;
use warnings;
use Test::More;
use Unix::Groups::FFI qw(getgroups setgroups initgroups);
use Errno 'EPERM';

my @current_groups = split ' ', $);
shift @current_groups;
is_deeply {map { ($_ => 1) } getgroups}, {map { ($_ => 1) } @current_groups},
  'Retrieved supplementary groups';

SKIP: {
  skip 'These tests are for unprivileged users', 4 if eval { setgroups(getgroups); 1 };
  
  ok !eval { setgroups; 1 }, 'Failed to set supplementary groups';
  cmp_ok 0+$!, '==', EPERM, 'Insufficient privilege';
  
  my $username = getpwuid $>;
  ok !eval { initgroups($username); 1 }, 'Failed to initialize supplementary groups';
  cmp_ok 0+$!, '==', EPERM, 'Insufficient privilege';
}

done_testing;
