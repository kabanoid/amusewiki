#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use Text::Amuse::Compile::Utils qw/write_file read_file/;

use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;

use AmuseWikiFarm::Archive::StaticIndexes;
use Data::Dumper;
use Test::More tests => 58;
use DateTime;
use Path::Tiny;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = $schema->resultset('Site')->find('0blog0');
ok(-d $site->root_install_directory);
diag $site->root_install_directory;
my $indexes = $site->static_indexes_generator;

ok -d $site->templates_location;
diag $site->templates_location;

ok -d $site->mkits_location;
diag $site->mkits_location;

{
    my $lh = $site->localizer;
    ok is $lh->loc("Titles"), "Naslovi";
    ok is $lh->loc_html("Titles"), "Naslovi";
    my $mailer = $site->mailer;
    ok $mailer->mailer;
    ok $mailer->transport;

}
ok($indexes);

my $static_path = AmuseWikiFarm::Utils::Paths::static_file_location();
foreach my $f ($indexes->javascript_files,
               $indexes->css_files,
               $indexes->font_files) {
    my $src = path($static_path, $f);
    ok $src->exists, "$src exists";
}

my $ftarget = $indexes->target_subdir;
$ftarget->remove_tree;
ok !$ftarget->exists;

my @targets = (qw/titles topics authors/);

my @files;
foreach my $method (map { $_ . '_file' } @targets) {
    my $file = $indexes->$method;
    ok ($file);
    diag $file;
    if (-f $file) {
        diag "removing $file";
        unlink $file or die "Cannot remove $file $!";
    }
    push @files, $file;
}

$indexes->generate;

foreach my $file (@files) {
    ok (-f $file, "$file was generated");
    my $content = read_file($file);
    unlike $content, qr{\[\%}, "No opening TT tokens found in $file";
    unlike $content, qr{\%\]}, "No closing TT tokens found in $file";
    like $content, qr{<html lang="hr">}, "Found html tag in $file";
    like $content, qr/<div id="page"/, "Found container in $file";
    like $content, qr/My first test/, "Found text in $file";
    like $content, qr/first-test/, "Found text in $file";
}

foreach my $f ($indexes->javascript_files,
               $indexes->css_files,
               $indexes->font_files) {
    my $done = path($ftarget, $f);
    ok $done->exists, "$done exists";
}

ok !$indexes->copy_static_files;
# change the them

my $oldtheme = $site->theme;
$site->update({ theme => 'lumen' });

is $site->static_indexes_generator->copy_static_files, 1;
$site->static_indexes_generator->generate;
is $site->static_indexes_generator->copy_static_files, 0;
$site->update({ theme => $oldtheme });

