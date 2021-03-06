package AmuseWikiFarm::Schema::ResultSet::TitleStat;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

=head1 NAME

AmuseWikiFarm::Schema::ResultSet::TitleStat - TitleStat resultset

=head1 METHODS

=cut


use DateTime;
use AmuseWikiFarm::Log::Contextual;

=head2 popular_texts

=cut

sub popular_texts {
    my ($self, $page, $items) = @_;
    unless ($page and $page =~ m/\A[1-9][0-9]*\z/) {
        $page = 1;
    }
    unless ($items and $items =~ m/\A[1-9][0-9]*\z/) {
        $items = 10;
    }
    my $me = $self->current_source_alias;
    my $dtf = $self->result_source->schema->storage->datetime_parser;
    my $since = DateTime->now->subtract(days => 30);
    return $self->search({
                          'title.f_class' => 'text',
                          'title.status' => 'published',
                          "$me.accessed" => { '>' => $dtf->format_datetime($since) },
                         },
                         {
                          columns => [],
                          prefetch => [qw/title/],
                          '+select' => [{
                                         count => 'title.id',
                                         -as => 'countpopular'
                                        }],
                          '+as' => [qw/title.popular/],
                          group_by => [qw/title.id/],
                          order_by => [
                                       { -desc => 'countpopular' },
                                       { -asc => 'title.sorting_pos' },
                                      ],
                          page => $page,
                          rows => $items,
                         });
}

sub delete_old {
    my $self = shift;
    my $me = $self->current_source_alias;
    my $dtf = $self->result_source->schema->storage->datetime_parser;
    my $since = DateTime->now->subtract(days => 30);
    log_info { "Removing stats older than $since" };
    $self->search({ "$me.accessed" => { '<' => $dtf->format_datetime($since) } })->delete;
}


1;
