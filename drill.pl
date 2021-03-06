#!/usr/local/bin/perl

use strict;
use warnings;

use CGI;
use Passage;
our $VAR1;

my $q = CGI->new;
my $u = $q->param('u') || '';
my $filename = $q->param('f') || '';

open my $f, "<users/$u/passages/$filename";
my $contents = do { local $/; <$f> };
my $spec = do { local $VAR1; eval $contents; $VAR1 };
my $linewords = $spec->{linewords};
my $version = $spec->{version};
my $passage = $spec->{passage};

$passage =~ /(.*) (\d+):(\d+)-(\d+)/;
my ($book, $chapter, $first_verse, $last_verse) = ($1, $2, $3, $4);

my @phrases = $spec->{text}
    ?   Passage::get_passage_raw($spec->{text}, $linewords, 'html')
    :   Passage::get_passage(
            version          => $version,
            book             => $book,
            chapter          => $chapter,
            first_verse      => $first_verse,
            last_verse       => $last_verse,
            words_per_phrase => $linewords,
            format           => 'html',
        );

my $i = 1;
my $lines = join ',', map "['Card ".$i++.": ',\"$_\"]", map { s/"/\\"/g; s/\n/\\n/g; $_ } @phrases;
$lines =~ s/'\?'/'$passage?'/;

print "Content-type: text/html\n\n";
print <<HTML;
<html>
<head>
<meta http-equiv="content-type" content="text/html; charset=UTF-8">
<title>$passage - $version</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<script src="https://ajax.googleapis.com/ajax/libs/jquery/2.1.4/jquery.min.js"></script>
<script>
var lines = [
$lines
];
var set;
var state; /* enum(prompting, awaitinganswer, pausing) */
var current_item;
var displayed_time;

function time() { return Date.now() / 1000 | 0; }

function prompt() {
    if (!current_item)
        current_item = select_item();

    var wait = current_item.due - time();

    if (wait > 0) {
        \$('#memwindow').children().hide();
        \$('#memmessage').html(wait + '-second pause');
        \$('#memmessage').show();
        setTimeout(function() {
            \$('#memmessage').hide('');
            prompt();
        }, 1000 * wait);
        button_state('disabled');
        state = 'pausing';
        return;
    }

    button_state('reveal');
    state = 'prompting';

    for (var i = 0; i < set.length; i++) {
        if (i < current_item.id) {
            \$('#line_' + i).show();
        }
        else if (i == current_item.id) {
            \$('#title_' + i).show();
            \$('#line_' + i).hide();
        }
        else {
            \$('#title_' + i).hide();
            \$('#line_' + i).hide();
        }
    }

    var div = \$('#memwindow');
    div.animate({ scrollTop: div.prop("scrollHeight")}, 1000);

    displayed_time = time();
}

function button_state(state) {
    if (state == 'good_bad') {
        \$('#reveal-button').hide();
        \$('#good-button').show();
        \$('#repeat-button').show();
        \$('#save-button-learn').hide();
        \$('#save-button-review').hide();
    }
    else if (state == 'disabled') {
        \$('#reveal-button').hide();
        \$('#good-button').hide();
        \$('#repeat-button').hide();
        \$('#save-button-learn').show();
        \$('#save-button-review').show();
    }
    else if (state == 'reveal') {
        \$('#reveal-button').show();
        \$('#good-button').hide();
        \$('#repeat-button').hide();
        \$('#save-button-learn').hide();
        \$('#save-button-review').hide();
    }
}

function reveal() {
    \$('#title_' + current_item.id).hide();
    \$('#line_' + current_item.id).show();

    var div = \$('#memwindow');
    div.animate({ scrollTop: div.prop("scrollHeight")}, 1000);

    button_state('good_bad');
    state = 'awaitinganswer';
}

function handle_keydown(keydown) {
    return handle_input(keydown.which || keydown.keyCode);
}

function save_session(is_learn) {
    \$.post("save.pl", { u: '$u', f: '$filename', is_learn: is_learn });
    \$('body').html('<div style="color: white">Saved Review Session</div>');
}

function handle_input(key, keydown) {
    if (state == 'prompting') {
        if (key != 13) return false;
        if (keydown) keydown.preventDefault();
        reveal();
    }
    else if (state == 'awaitinganswer') {
        if (key != 13 && key != 8) return false;
        if (keydown) keydown.preventDefault();

        on_reviewed({
            displayed_time: displayed_time,
            answered_time: time(),
            correct_answer: (key == 13),
        });

        prompt();
    }

    return false;
}

function on_reviewed(params) {
    var item = current_item;
    current_item = null;

    var interval = params.correct_answer
        ? ((params.displayed_time - item.last_review) * item.ease) || 2
        : 0;

    item.due = params.answered_time + interval;
    item.last_review = params.answered_time;

    if (typeof Storage !== "undefined") {
        console.log('Saving to drill-$u-$filename');
        localStorage.setItem("drill-$u-$filename", JSON.stringify({
            "set": set,
            "state": state,
            "current_item": current_item,
            "displayed_time": displayed_time,
        }));
    }
}

function select_item() {
    var now = time();

    /* pass 1: find any 'learning' lines */
    for (var i = 0; i < set.length; i++) {
        if (set[i].due - set[i].last_review > 8)
            continue;
        if (set[i].due - now > 8)
            continue;
        return set[i];
    }

    /* pass 2: find any that is due */
    for (var i = 0; i < set.length; i++) {
        if (set[i].due <= now)
            return set[i];
    }

    var soonest = set[0];
    var least_wait_period = 86400 * 365;
    for (var i = set.length - 1; i >= 0; i--) {
        if (least_wait_period > set[i].due - now) {
            least_wait_period = set[i].due - now;
            soonest = set[i];
        }
    }

    return soonest;
}

function load() {
    var id = 0;
    var now = time();
    var memwindow = \$('#memwindow');

    set = [];

    var saved;

    if (typeof Storage !== "undefined") {
        var saved = localStorage.getItem("drill-$u-$filename");
        if (saved) {
          saved = JSON.parse(saved);
          set            = saved.set;
          state          = saved.state;
          current_item   = saved.current_item;
          displayed_time = saved.displayed_time;
        }
    }

    for (var i = 0; i < lines.length; i++) {
        memwindow.append(
            '<span id="title_' + id + '">' +
            lines[i][0] + ' ' +
            '</span>' +
            '<span id="line_' + id + '">' +
            lines[i][1] +
            '<br></span>');

        if (!saved)
          set.push({
              'due': now - 1,
              'last_review': now - 86400,
              'ease': 2,
              'id': id,
          });

        id += 1;
    }

    memwindow.children().hide();
}
</script>
</head>

<body onload="load(); prompt();"
    onkeydown="handle_keydown(event);"
    style="
        margin: 0;
        background-color: black;
    ">
<div id="memmessage" style="
    position: absolute;
    top: 1em;
    left: 1em;
    font-size: 1.5em;
    display: none;
    color: gray;
"></div>
<div id="memwindow" style="
    height: 90%;
    width: 100%;
    overflow-y: scroll;
    font-family: Sans-Serif;
    font-size: 1.5em;
    color: #aacc77;
    margin: 0;
"></div>
<button id="reveal-button" onclick="handle_input(13); return false" style="
    display: block;
    height: 10%;
    width: 100%;
    margin: 0;
    font-size: 1.5em;
">Reveal</button>
<button id="good-button" onclick="handle_input(13); return false" style="
    display: none;
    float: left; 
    height: 10%;
    width: 50%;
    margin: 0;
    font-size: 1.5em;
">Good</button>
<button id="repeat-button" onclick="handle_input(8); return false" style="
    display: none;
    float: right; 
    height: 10%;
    width: 50%;
    margin: 0;
    font-size: 1.5em;
">Repeat</button>
<button id="save-button-learn" onclick="save_session(1); return false" style="
    display: none;
    float: left;
    height: 10%;
    width: 50%;
    margin: 0;
    font-size: 1.5em;
">Save as 'Learn'</button>
<button id="save-button-review" onclick="save_session(0); return false" style="
    display: none;
    float: right;
    height: 10%;
    width: 50%;
    margin: 0;
    font-size: 1.5em;
">Save as 'Review'</button>
</body>
</html>
HTML
