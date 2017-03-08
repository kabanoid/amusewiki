package AmuseWikiFarm::Controller::Tasks;
use Moose;
with 'AmuseWikiFarm::Role::Controller::HumanLoginScreen';
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

AmuseWikiFarm::Controller::Tasks - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 root

Deny access to not-human

=cut

use DateTime;
use AmuseWikiFarm::Log::Contextual;

sub root :Chained('/site_human_required') :PathPart('tasks') :CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash(full_page_no_side_columns => 1);
}

sub status :Chained('root') :CaptureArgs(1) {
    my ($self, $c, $id) = @_;
    my $job = $c->stash->{site}->jobs->find($id);
    unless ($job) {
        $c->detach('/not_found');
        return;
    }

    # here we inject the message, depending on the task

    my $data = $job->as_hashref;
    $data->{status_loc} = $c->loc($data->{status});

    if ($data->{produced}) {
        $data->{produced_uri} = $c->uri_for($data->{produced})->as_string;
    }
    if ($data->{sources}) {
        $data->{sources} = $c->uri_for($data->{sources})->as_string;
    }
    if (my $msg = $data->{message}) {
        # $c->loc('Your file is ready');
        # $c->loc('Changes applied');
        # $c->loc('Done');
        $data->{message} = $c->loc($msg);
    }
    $c->stash(
              job => $data,
              page_title => $c->loc('Queue'),
             );
}

sub display :Chained('status') :PathPart('') :Args(0) {
    # empty to close the chain
}

sub ajax :Chained('status') :PathPart('ajax') :Args(0) {
    my ($self, $c, $job) = @_;
    $c->stash(json => delete($c->stash->{job}));
    $c->detach($c->view('JSON'));
}

sub bulks :Chained('root') :PathPart('') :CaptureArgs(0) {
    my ($self, $c) = @_;
    # let the logged access the bulk jobs (show only).
    $self->check_login($c) or die;
    my $bulk_jobs = $c->stash->{site}->bulk_jobs;
    $c->stash(bulk_jobs => $bulk_jobs);
    my $now = DateTime->now(locale => $c->stash->{current_locale_code});
    $c->stash(now_datetime => $now->format_cldr($now->locale->datetime_format_full));
}

sub rebuild :Chained('bulks') :PathPart('rebuild') :Args(0) {
    my ($self, $c) = @_;
    # job control reserved to admin
    unless ($c->check_any_user_role(qw/admin root/)) {
        $c->detach('/not_permitted');
        return;
    }
    my $bulks = delete $c->stash->{bulk_jobs};
    my $all = $bulks->rebuilds;
    my $rs = $all->active_bulk_jobs;
    if ($c->request->body_params->{rebuild}) {
        $rs->abort_all;
        my $job = $c->stash->{site}->rebuild_formats;
        $c->response->redirect($c->uri_for_action('/tasks/show_bulk_job', [ $job->bulk_job_id ]));
        $c->detach;
        return;
    }
    elsif ($c->request->body_params->{cancel}) {
        $rs->abort_all;
    }
    $c->stash(bulk_jobs => [ $rs->all ],
              last_job => $all->completed_jobs->first);
}

sub get_bulk_job :Chained('bulks') :PathPart('job') :CaptureArgs(1) {
    my ($self, $c, $id) = @_;
    if ($id =~ m/\A[1-9][0-9]*\z/) {
        my $rs = delete $c->stash->{bulk_jobs};
        if (my $bulk = $rs->find($id)) {
            $c->stash(bulk_job => $bulk,
                      ajax_job_details_url => $c->uri_for_action('/tasks/show_bulk_job_ajax', [ $id ]),
                      all_jobs => [$bulk->jobs
                                   ->search(undef,
                                            {
                                             columns => [qw/id produced status completed errors/],
                                             result_class => 'DBIx::Class::ResultClass::HashRefInflator',
                                             order_by => [qw/id/],
                                            })->all]);
            return;
        }
    }
    $c->detach('/not_found');
}

sub show_bulk_job :Chained('get_bulk_job') :PathPart('show') :Args(0) {
    my ($self, $c) = @_;
}

sub show_bulk_job_ajax :Chained('get_bulk_job') :PathPart('ajax') :Args(0) {
    my ($self, $c) = @_;
    my $job = $c->stash->{bulk_job};
    my $locale = $c->stash->{current_locale_code} || 'en';
    my %data = (
                completed => ($job->completed ? $job->completed_locale($locale) : undef),
                total_failed => $job->total_failed_jobs,
                total_completed => $job->total_completed_jobs,
                total_jobs => $job->total_jobs,
                started => $job->created_locale($locale),
                eta => $job->eta_locale($locale) || $c->loc("N/A"),
                status => $job->status,
               );
    $c->stash(json => {
                       job => \%data,
                       all_jobs => $c->stash->{all_jobs},
                      });
    $c->detach($c->view('JSON'));
}

=head1 AUTHOR

Marco Pessotto <melmothx@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
