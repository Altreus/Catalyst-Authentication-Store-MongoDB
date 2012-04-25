package Catalyst::Authentication::Store::MongoDB;

use 5.006;
use strict;
use warnings;

=head1 NAME

Catalyst::Authentication::Store::MongoDB - L<MongoDB> backend for
Catalyst::Plugin::Authentication

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This module links a subclass of MongoDB to your Catalyst application as a user
store for the Authentication plugin.

    <Plugin::Authentication>
        <default>
            <credential>
                class Password
                password_type self_check
            </credential>
            <store>
                class MongoDB
                user_collection user
                model MongoDB
                database db
            </store>
        </default>
    </Plugin::Authentication>

Then use it as normal

    sub login : Local {
        my ($self, $c) = @_;
        $c->authenticate({
            username => $username,
            password => $password
        });
    }

=head1 CONFIGURATION

=head2 class

The configuration required by L<Catalyst::Plugin::Authentication> to load this
store in the first place.

=head2 user_collection

The collection in your database that holds users.

=head2 model

The model name that you'd give to $c->model. It is expected that your model
is a L<MongoDB> subclass.

=head2 database

The database that your user_collection is a collection in.

=cut

sub new {
    my ($class, $config, $app) = @_;

    $config->{user_class} //= 'Catalyst::Authentication::User::Hash';

    my $self = {
        config => $config
    };

    bless $self, $class;
}

sub from_session {
    my ($self, $c, $frozen) = @_;

    $c->model($self->config->{model})
        ->connection
        ->get_database($self->config->{database})
        ->get_collection($self->config->{user_collection})
        ->find({
            _id => MongoDB::OID->new(value => $frozen)
        });
}

sub for_session {
    my ($self, $c, $user) = @_;

    return $user->{_id}->{value};
}

sub find_user {
    my ($self, $authinfo, $c) = @_;

    # note to self before I forget: password is deleted from $authinfo by the
    # realm when finding the user. kthx
    my $user = $c->model($self->config->{model})
        ->connection
        ->get_database($self->config->{database})
        ->get_collection($self->config->{user_collection})
        ->find($authinfo);
    
    return undef unless $user;

    bless $user, $self->config->{user_class};
}

sub user_supports {
    my $self = shift;
    $self->config->{user_class}->supports( @_ );
}

=head1 AUTHOR

Altreus, C<< <altreus at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-authentication-store-mongodb at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Authentication-Store-MongoDB>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Authentication::Store::MongoDB


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Authentication-Store-MongoDB>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Authentication-Store-MongoDB>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Authentication-Store-MongoDB>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Authentication-Store-MongoDB/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Altreus.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Catalyst::Authentication::Store::MongoDB
