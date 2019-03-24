#!/usr/local/bin/perl

use strict;
use warnings;

use CGI;

my $q = CGI->new;
my $u = $q->param('u') || '';
my $filename = $q->param('f') || '';
my $is_learn = $q->param('is_learn'); # true if lots was unknown

open my $f, ">>users/$u/passages/$filename.log";
print $f time." ".($is_learn ? 'learn' : 'review')."\n";

print "Content-type: text/html\n\n";
