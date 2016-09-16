#!/usr/bin/perl -w

use Test::More;
use File::Temp;
use File::Slurper;

use lib '.';
use Test_Greylist;
use Test_Whitelists;

plan tests => 4 + $Test_Greylist::tests;

my $tmpdir = File::Temp->newdir();
my $sock_path = "$tmpdir/postgrey.sock";
my $pid_path = "$tmpdir/postgrey.pid";

# Start postgrey
system("./test-wrapper.sh -d --pidfile=$pid_path " .
           "--dbdir=$tmpdir --unix=$sock_path " .
           "--whitelist-clients=../postgrey_whitelist_clients " .
           "--whitelist-recipients=../postgrey_whitelist_recipients " .
           "--delay=1",
           );
ok($? == 0, "start postgrey");
sleep(1);

# Verify that it is running
my $pid; open(PID, $pid_path) and $pid = <PID>; close(PID);
ok(defined $pid, "pid file generated") or done_testing, exit;
chomp($pid);
ok(kill(0, $pid), "postgrey is running") or done_testing, exit;

# Run tests in modules
Test_Greylist::run_tests($sock_path);
#Test_Whitelists::run_tests($sock_path);

# Stop postgrey and verify that it stopped
kill('TERM', $pid);
for(my $i=0; $i<10; $i++) {
    if(kill(0, $pid)==0) { last; }
    kill('TERM', $pid);
    print "# waiting for postgrey to stop (pid=$pid)\n";
    sleep(1);
}
ok(kill(0, $pid) == 0, "postgrey is stopped");