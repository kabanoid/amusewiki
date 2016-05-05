#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 4;
use AmuseWikiFarm::Utils::Paginator;
use Data::Dumper;
use Data::Page;

my $pager = Data::Page->new;
$pager->total_entries(40);
$pager->entries_per_page(3);
$pager->current_page(1);

my $sub = sub {
    return '/latest/' . $_[0];
};

my $pages = AmuseWikiFarm::Utils::Paginator::create_pager($pager, $sub);

is_deeply($pages, [
                   {
                    'label' => 1,
                    'active' => 1,
                    'uri' => '/latest/1'
                   },
                   {
                    'uri' => '/latest/2',
                    'label' => 2
                   },
                   {
                    'uri' => '/latest/3',
                    'label' => 3
                   },
                   {
                    label => '...',
                   },
                   {
                    'uri' => '/latest/13',
                    'label' => 13
                   },
                   {
                    'uri' => '/latest/14',
                    'label' => 14
                   },
                   {
                    'label' => "\x{bb}\x{bb}\x{bb}",
                    'uri' => '/latest/2'
                   }
                  ]);

$pager->current_page(8);

$pages = AmuseWikiFarm::Utils::Paginator::create_pager($pager, $sub);

is_deeply($pages, 
          [
           {
            'label' => "\x{ab}\x{ab}\x{ab}",
            'uri' => '/latest/7'
           },
           {
            'label' => 1,
            'uri' => '/latest/1'
           },
           {
            'uri' => '/latest/2',
            'label' => 2
           },
           {
            'label' => '...'
           },
           {
            'label' => 6,
            'uri' => '/latest/6'
           },
           {
            'uri' => '/latest/7',
            'label' => 7
           },
           {
            'label' => 8,
            'active' => 1,
            'uri' => '/latest/8'
           },
           {
            'label' => 9,
            'uri' => '/latest/9'
           },
           {
            'uri' => '/latest/10',
            'label' => 10
           },
           {
            'label' => '...'
           },
           {
            'uri' => '/latest/13',
            'label' => 13
           },
           {
            'uri' => '/latest/14',
            'label' => 14
           },
           {
            'uri' => '/latest/9',
            'label' => "\x{bb}\x{bb}\x{bb}"
           }
          ]);



          

$pager->current_page(9);

$pages = AmuseWikiFarm::Utils::Paginator::create_pager($pager, $sub);

is_deeply($pages, 
          [
           {
            'label' => "\x{ab}\x{ab}\x{ab}",
            'uri' => '/latest/8'
           },
           {
            'label' => 1,
            'uri' => '/latest/1'
           },
           {
            'uri' => '/latest/2',
            'label' => 2
           },
           {
            'label' => '...'
           },
           {
            'label' => 7,
            'uri' => '/latest/7'
           },
           {
            'label' => 8,
            'uri' => '/latest/8'
           },
           {
            'label' => 9,
            'active' => 1,
            'uri' => '/latest/9'
           },
           {
            'uri' => '/latest/10',
            'label' => 10
           },
           {
            'label' => 11,
            'uri' => '/latest/11',
           },
           {
            'label' => '...',
           },
           {
            'uri' => '/latest/13',
            'label' => 13
           },
           {
            'uri' => '/latest/14',
            'label' => 14
           },
           {
            'uri' => '/latest/10',
            'label' => "\x{bb}\x{bb}\x{bb}"
           }
          ]) or diag Dumper($pages);

$pager->current_page(14);

$pages = AmuseWikiFarm::Utils::Paginator::create_pager($pager, $sub);
is_deeply($pages, 
          [
           {
            'label' => "\x{ab}\x{ab}\x{ab}",
            'uri' => '/latest/13'
           },
           {
            'label' => 1,
            'uri' => '/latest/1'
           },
           {
            'uri' => '/latest/2',
            'label' => 2
           },
           {
            'label' => '...'
           },
           {
            'uri' => '/latest/12',
            'label' => 12
           },
           {
            'uri' => '/latest/13',
            'label' => 13
           },
           {
            'uri' => '/latest/14',
            'label' => 14,
            active => 1,
           },
          ]) or diag Dumper($pages);