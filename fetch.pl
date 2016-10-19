#!/usr/bin/perl

use strict;
use warnings;

use Net::FTP;

my $ftp = Net::FTP->new("ftp.dm2usa.org", Debug => 0) or die "Cannot connect to ftp.dm2usa.org: $@";
print "Pass: ";
my $pass = <STDIN>;
chomp $pass;
$ftp->login("bmem", $pass) or die "Cannot login ", $ftp->message;

chdir 'users/6526806dca/passages' or die "Could not switch to local dir";
$ftp->cwd('users/6526806dca/passages') or die "Could not switch to remote dir", $ftp->message;

for my $file ($ftp->ls) {
    $ftp->get($file) or die "get(*) failed ", $ftp->message;
}

$ftp->quit;
