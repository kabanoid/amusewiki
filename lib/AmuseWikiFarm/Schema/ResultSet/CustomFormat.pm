package AmuseWikiFarm::Schema::ResultSet::CustomFormat;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

sub active_only {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.active" => 1 },
                         { order_by => [
                                        "$me.format_priority",
                                        "$me.format_name",
                                        "$me.custom_formats_id",
                                       ] });
}

sub with_alias {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.format_alias" => { '!=' => '' } }),
}

sub standards {
    return shift->active_only->with_alias;
}

1;
