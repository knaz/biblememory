#!/usr/local/bin/perl

use strict;
use warnings;
use lib ".";

use CGI;
use Passage;

my $q = CGI->new;

my $u = $q->param('u') || '';
my $passage = $q->param('passage') || '';
my $paste = $q->param('paste') || '';

my $html = do { local $/; open my $f, "<page-template.html"; <$f> };

$html =~ s/{title}/Peronal Memory URL/;

my @lines = Passage::get_passage_raw($paste, 1);

my $javascript =
    "var lines = [".
    join(', ', map { chomp; s/"/\\"/g; qq{"$_"} } @lines).
    "];\n";
$javascript .= <<EOF;
    var words = [];
    var phrases = [];
    var num_words_picked = 0;
    \$(document).ready(function() {
        for (var i = 0; i < lines.length; i++) {
            words.push(lines[i]);
        }
    });

    function on_click_word(which) {
        var phrase = [];
        for (var i = num_words_picked; i <= which; i++) {
            \$('#word-' + i).hide();
            phrase.push(words[i]);
            num_words_picked += 1;
        }
        \$('.indexcard:last').html(phrase.join(' '));
        \$('#cards').append('<div class="indexcard">&nbsp;</div>');
        \$('#hiddens').append(
            '<input type="hidden" name="linewords" value="' + phrase.length + '">'
        );
        if (num_words_picked == words.length)
            \$('#save').show();
    }
EOF

my $text_to_select = '';
for my $i (0..$#lines) {
    $text_to_select .= qq{<span id="word-$i" onclick="on_click_word($i)">$lines[$i]</span> };
}

my $style = qq{
    .indexcard {
        display: inline-block;
        background-image: url(indexcard.png);
        background-size: cover;
        height: 9em;
        width: 15em;
        padding-top: 1.5em;
        border: 1px solid black;
        text-align: center;
        vertical-align: middle;
        font-weight: bold;
        font-family: sans-serif;
        line-height: normal;
        font-size: 0.8em;
    }
};

$html =~ s~{javascript}~ */ $javascript /* ~;
$html =~ s~{style}~ */ $style /* ~;

my $body = <<EOF;
<p>$passage</p>
<p>You will be quizzed phrase-by-phrase.  Choose which words should constitute each phrase below:</p>
<div id="cards"><div class="indexcard">&nbsp;</div></div>
<p>$text_to_select</p>
<form method="post" action="new-passage-save.pl">
<div style="display:none" id="hiddens"></div>
<input type="hidden" name="u" value="$u">
<input type="hidden" name="text" value="$paste">
<input type="hidden" name="passage" value="$passage">
<button id="save" style="display:none" type="submit">Save</button>
</form>
EOF

$html =~ s/{contentarea}/$body/;

print "Content-type: text/html\n\n";
print $html;
