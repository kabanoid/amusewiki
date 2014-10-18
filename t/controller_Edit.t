#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::More tests => 30;
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Test::WWW::Mechanize::Catalyst;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";


my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0edit1';
my $site = create_site($schema, $site_id);
ok ($site);
my $host = $site->canonical;
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $host);

$mech->get_ok('/action/text/new');
ok($mech->form_id('login-form'), "Found the login-form");
$mech->set_fields(username => 'root',
                  password => 'root');
$mech->click;
$mech->content_contains('You are logged in now!');

diag "Uploading a text";
my $title = 'test-fixes';
ok($mech->form_id('ckform'), "Found the form for uploading stuff");
$mech->set_fields(author => 'pippo',
                  title => $title,
                  textbody => "\n");

$mech->click;

$mech->content_contains('Created new text');

diag "In " . $mech->response->base->path;

$mech->form_id('museform');

my %expected = (
                en => q{“hello” l’albero l’“adesso” ‘adesso’},
                fi => q{”hello” l’albero l’”adesso” ’adesso’},
                it => q{“hello” l’albero l’“adesso” ‘adesso’},
                hr => q{„hello” l’albero l’„adesso” ‘adesso’},
                mk => q{„hello“ l’albero l’„adesso“ ’adesso‘},
                sr => q{„hello“ l’albero l’„adesso“ ’adesso’},
                es => q{«hello» l’albero l’«adesso» ‘adesso’},
                ru => q{«hello» l’albero l’«adesso» ‘adesso’},
               );

$mech->tick(fix_links => 1);
$mech->tick(fix_typography => 1);
$mech->tick(fix_footnotes => 1);
$mech->tick(fix_nbsp => 1);
$mech->tick(remove_nbsp => 1);

foreach my $lang (keys %expected) {
    my $body =<<"EOF";
#title $title
#lang $lang

"hello" l'albero l'"adesso" 'adesso' [2]

[3] footnote http://amusewiki.org nbsp nbsp removed
EOF
    $mech->field(body => $body);
    $mech->click('preview');
    $mech->form_id('museform');
    my $got_body = $mech->value('body');
    like $got_body, qr/\Q$expected{$lang}\E \[1\]/;
    $mech->content_contains($expected{$lang} . ' [1]');
    my $exp_string =
      q{[1] footnote [[http://amusewiki.org][amusewiki.org]] nbsp nbsp removed};
    like $got_body, qr/\Q$exp_string\E/, "links, nbsp, footnotes fixed";
}
    
