#!/usr/bin/perl

use strict;
use warnings;

use Net::FTP;

my $ftp = Net::FTP->new("ftp.dm2usa.org", Debug => 0) or die "Cannot connect to ftp.dm2usa.org: $@";
print "Pass: ";
my $pass = <STDIN>;
chomp $pass;
$ftp->login("bmem", $pass) or die "Cannot login ", $ftp->message;

for my $file (qw(
    drill.pl
    generate-personal-link.pl
    index.pl
    memorize.pl
    new-passage.pl
    new-passage2.pl
    new-passage-paste.pl
    page-template.html
    Versions.pm
    Passage.pm
    Blowfish.js
    new-passage-save.pl
    .htaccess
)) {
    $ftp->put($file) or die "put($file) failed ", $ftp->message;
}

$ftp->quit;
