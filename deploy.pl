#!/usr/local/bin/perl

use strict;
use warnings;

use Net::FTP;

my $ftp = Net::FTP->new("ftp.keithnaz.com", Debug => 0) or die "Cannot connect to ftp.keithnaz.com: $@";
print "Pass: ";
my $pass = <STDIN>;
chomp $pass;
$ftp->login("bmem", $pass) or die "Cannot login ", $ftp->message;

for my $file (qw(
    drill.pl
    delete.pl
    save.pl
    generate-personal-link.pl
    index.pl
    memorize.pl
    new-passage.pl
    new-passage-paste.pl
    page-template.html
    Versions.pm
    Passage.pm
    new-passage-save.pl
    .htaccess
)) {
    $ftp->put($file) or die "put($file) failed ", $ftp->message;
}

$ftp->quit;
