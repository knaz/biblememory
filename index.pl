#!/usr/bin/perl

use strict;
use warnings;

my $html = do { local $/; open my $f, "<page-template.html"; <$f> };

$html =~ s/{title}/Bible Memory/;

my $body = <<EOF;
    <h1>Memory</h1>

    <p>In order to begin, please click the following link to generate your personal memory URL.</p>
    <p>If you have already done this step, please use the URL that you already generated. (You should have it bookmarked.)</p>
    <p>If you have not yet generated a personalized memory URL, or if you need a new one, click the button below.</p>
    <form action="generate-personal-link.pl">
    <div style="text-align: center; margin-bottom: 3em">
        <button type="submit" style="height: 4em">Generate Personal Memory URL</button>
    </div>
    </form>
EOF

$html =~ s/{contentarea}/$body/;

print "Content-type: text/html\n\n";
print $html;
