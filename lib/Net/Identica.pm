package Net::Identica;

use 5.008008;
use strict;
use warnings;
use HTML::Parser;
use LWP::UserAgent;
use Carp;

our $VERSION = '0.01';

my ($Attr, $i, @contents, $login) = (undef, -1);
my $ua = LWP::UserAgent->new;
$ua->agent('Mozilla');
$ua->cookie_jar({ file => 'cookies.txt' });


sub new {
    my $pkg   = shift;
    my $self  = {};
    @contents = ();
    $i        = -1;
    $login    = 1;

    my $p = HTML::Parser->new(api_version => 3);
    $p->handler(start => \&_start_handler, "self,tagname,attr");
    $p->handler(end   => sub {
        return unless defined $Attr;
        return if $Attr eq 'content' && shift eq 'a';
        $Attr = undef;
    }, 'tagname');

    $p->utf8_mode(1);

    my $nickname = shift;
    if($nickname) {
        if(@_ == 1) {
            my $password = shift;
            $self->{login} = 1;
            my $response = $ua->post('http://identi.ca/main/login', [nickname => $nickname, password => $password]);
            $p->parse($response->content);
            if($login == 1) {
                $self->{login} = 1
            } else {
                $self->{login} = 0
            }
        } else {
            $self->{login} = 0;
        }

        my $response = $ua->get("http://identi.ca/$nickname/all");
        $p->parse($response->content);
        $self->{contents} = [@contents];

        $self->{nickname} = $nickname;

        bless($self, $pkg);
        return $self;
    } else {
        croak 'Invalid username';
    }
}

sub get {
    my $self = shift;

    return @{$self->{contents}};
}

sub post {
    my ($self, $message) = @_;

    if($self->{login}) {
        my $response = $ua->post('http://identi.ca/notice/new', [status_textarea => $message, returnto => 'all']);
    } else {
        croak 'Not logged in';
    }

    # Check if successful or not
}

sub _start_handler {
    my $self = shift;

    return unless exists $_[1]->{class};
    if($_[1]->{class} eq 'nickname') {
        $Attr = 'nickname';
        $i++;
    } elsif($_[1]->{'class'} eq 'content') {
        $Attr = 'content';
    } elsif($_[1]->{'class'} eq 'error') {
        $Attr = 'error';
    }

    $self->handler(text => sub {
        return unless defined $Attr;
        if($Attr eq 'content') {
            $contents[$i] .= shift;
        } elsif($Attr eq 'nickname') {
            shift;
        } elsif($Attr eq 'error') {
            $login = 0;
            my $error = shift;
            if($error eq 'Incorrect username or password.' || $error eq 'No such user.') {
                croak 'Incorrect username or password';
            }
        }
    }, 'dtext');
}

1;
__END__

=head1 NAME

Net::Identica - Perl extension for fetching from, and posting notices/messages to Identi.ca

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

  use Net::Identica;

  # If you just want to get() the notices, then there is no need to provide a password.
  # my $identi = Net::Identica->new('username');

  my $identi = Net::Identica->new('username', 'password');
  my @messages = $identi->get;

  print map { $_, "\n" } @messages;
  $identi->post('Hello world');

=head1 DESCRIPTION

The module logs in to http://identi.ca and allows to fetch latest notices as well as allows to post notices.

=head1 METHODS

The implemented methods are :

=over 4

=item C<new>


Creates the object.

It accepts username and password of which password is required only if post() method is to be used.

=over 4

=item C<USERNAME>

Your (or another person's) Identi.ca username.

=item C<PASSWORD>

Your Identi.ca password. Password is required only if you need to post messages using the module's post() method.

Example:

  my $identi = Net::Identica->new('alanhaggai', 'topsecret');
  # or
  my $identi = Net::Identica->new('alanhaggai');

=back 4

=item C<get>


Returns an array of messages.

Example:

  my @messages = $identi->get;
  print map { $_, "\n" } @messages;

=item C<post>


Posts a notice in a string to your Identi.ca account.

Example:

  $identi->post('Hello world');

=back 4

=head1 AUTHOR

Alan Haggai Alavi, C<< <alanhaggai at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-identica at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Identica>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Alan Haggai Alavi, all rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
