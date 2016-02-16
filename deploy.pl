#!/usr/bin/perl

use strict;
use warnings;

use Net::FTP;

my $ftp = Net::FTP->new("ftp.dm2usa.org", Debug => 0) or die "Cannot connect to ftp.dm2usa.org: $@";
$ftp->login("bret", 'ya01nofi#') or die "Cannot login ", $ftp->message;
$ftp->cwd("/biblememory") or die "Cannot change working directory ", $ftp->message;

for my $file (qw(
    drill.pl
    generate-personal-link.pl
    index.pl
    memorize.pl
    new-passage.pl
    new-passage2.pl
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
