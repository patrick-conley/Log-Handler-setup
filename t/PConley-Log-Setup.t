# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl PConley-Log-Setup.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Log::Handler;
use File::Temp;

use Test::More tests => 23;
BEGIN { use_ok('PConley::Log::Setup') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok( PConley::Log::Setup::log_setup( Log::Handler->new() ), 'log_setup runs' );
ok( PConley::Log::Setup::log_setup( Log::Handler->new(), verbosity => 1 ), 
   "runs with verbosity arg" );
ok( PConley::Log::Setup::log_setup( Log::Handler->new(), logfile => 'test' ),
   "runs with logfile arg" );

isa_ok( my $log = PConley::Log::Setup::log_setup( Log::Handler->new() ), 'Log::Handler',
   'returns a Log::Handler object' );

# Testing logger state
is( $log->is_emerg(), 0, "emerg never displays" );
is( $log->is_error(), 1, "error displays" );
is( $log->is_notice(), 1, "notice displays" );
is( $log->is_info(), 0, "info doesn't display" );

$log = PConley::Log::Setup::log_setup( Log::Handler->new(), verbosity => 1 );
is( $log->is_error(), 1, "error displays on verbose" );
is( $log->is_info(), 1, "info displays" );
is( $log->is_debug(), 0, "debug doesn't display" );

$log = PConley::Log::Setup::log_setup( Log::Handler->new(), verbosity => 2,
   silent => 1 );
is( $log->is_error(), 1, "error displays on very verbose" );
is( $log->is_info(), 1, "info displays" );
is( $log->is_debug(), 1, "debug displays" );

$log = PConley::Log::Setup::log_setup( Log::Handler->new(), verbosity => -1 );
is( $log->is_emerg(), 0, "emerg doesn't display  on quiet" );
is( $log->is_error(), 0, "error display" );
is( $log->is_notice(), 0, "notice doesn't display" );
is( $log->is_debug(), 0, "debug doesn't display" );

my ( $tempfh, $tempfile ) = File::Temp::tempfile();
$log = PConley::Log::Setup::log_setup( Log::Handler->new(), verbosity => -1,
   logfile => $tempfile );
is( $log->is_emerg(), 1, "emerg displays on quiet with logfile" );
is( $log->is_error(), 1, "error displays" );
is( $log->is_notice(), 0, "notice doesn't display" );
is( $log->is_debug(), 0, "debug doesn't display" );

unlink "test.debug";
