package App::ZofCMS::Plugin::FormMailer;

use warnings;
use strict;

our $VERSION = '0.0201';

use base 'App::ZofCMS::Plugin::Base';
require File::Spec;
sub _key { 'plug_form_mailer' }
sub _defaults {
    return (
        trigger => [ qw/d plug_form_mailer/ ],
        subject => 'FormMailer',
        ok_key  => 't',
    );
}

sub _do {
    my ( $self, $conf, $template, $query, $config ) = @_;

    my $trigger = $template;
    for ( @{ $conf->{trigger} || [] } ) {
        $trigger = $trigger->{$_};
    }
    return
        unless $trigger;

    my %query = %$query;
    defined or $_ = ''
        for values %query;

    my $format = $conf->{format};
    {
        if ( ref $format ) {
            my $file_name = File::Spec->catfile( $config->conf->{templates}, $$format );
            my $fh;
            unless ( open $fh, '<', $file_name ) {
                $template->{t}{plug_form_mailer_error} = "Failed to open $file_name [$!]";
                $format = '';
                last;
            }

            $format = do { local $/; <$fh> };
        }
    }

    my %specials = (
        time => scalar localtime(),
        host => $config->cgi->remote_host,
    );
    $format =~ s/{:{([^}]+)}:}/$query{$1}/g;
    $format =~ s/{:\[(time|host)\]:}/$specials{$1}/g;

    require Mail::Send;

    $conf->{to} = [ $conf->{to} ]
        unless ref $conf->{to};

    my $msg = Mail::Send->new;
    $msg->to( @{ $conf->{to} } );
    $msg->subject( $conf->{subject} );

    $Mail::Mailer::testfile::config{outfile} = 'mailer.testfile';
    my $fh = $msg->open( $conf->{mailer} ? $conf->{mailer} : () );
    print $fh $format;
    $fh->close;

    $template->{ $conf->{ok_key} }{plug_form_mailer_ok} = 1;
    if ( defined $conf->{ok_redirect} ) {
        print $config->cgi->redirect( $conf->{ok_redirect} );
        exit;
    }
}

1;
__END__

=head1 NAME

App::ZofCMS::Plugin::FormMailer - plugin for e-mailing forms

=head1 SYNOPSIS

In your Main Config File or ZofCMS Template file:

    plug_form_mailer => {
        trigger => [ qw/ d   plug_form_checker_ok / ],
        subject => 'Zen of Design Account Request',
        to      => 'foo@bar.com',
        mailer  => 'testfile',
        format  => <<'END',
The following account request has been submitted:
First name: {:{first_name}:}
Time:       {:[time]:}
Host:       {:[host]:}
END
    },

In your L<HTML::Template> file:

    <tmpl_if name="plug_form_mailer_ok">
        <p>Your request has been successfully submitted.</p>
    <tmpl_else>
        <form action="" method="POST" id="form_account_request">
            <input type="text" name="first_name">
            <input type="submit" value="Request account">
        </form>
    </tmpl_if>

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS> that
provides means to easily e-mail query parameters.

This documentation assumes you've read L<App::ZofCMS>, L<App::ZofCMS::Config> and
L<App::ZofCMS::Template>

=head1 MAIN CONFIG FILE AND ZofCMS TEMPLATE FIRST-LEVEL KEYS

=head2 C<plugins>

    plugins => [ qw/FormMailer/ ],

You need to add the plugin in the list of plugins to execute. Generally you'd want to check
query parameters first with, e.g. L<App::ZofCMS::Plugin::FormChecker>. If that's what you're
doing then make sure to set the correct priority:

    plugins => [ { FormChecker => 1000 }, { FormMailer => 2000 }, ],

=head2 C<plug_form_mailer>

        plug_form_mailer => {
            trigger     => [ qw/ d   plug_form_checker_ok / ],
            subject     => 'Zen of Design Account Request',
            to          => 'foo@bar.com',
            ok_redirect => 'http://google.com/',
            mailer      => 'testfile',
            format      => <<'END',
    The following account request has been submitted:
    First name: {:{first_name}:}
    Time:       {:[time]:}
    Host:       {:[host]:}
    END
        },

The plugin will not run unless C<plug_form_mailer> first-level key is set in either Main
Config File or ZofCMS Template file. The C<plug_form_mailer> first-level key takes a hashref
as a value. Keys that are set in both Main Config File and ZofCMS Template file will take on
their values from ZofCMS Template. Possible keys/values are as follows:

=head3 C<format>

        format  => \'file_name_relative_to_templates',

        # or

        format  => <<'END',
    The following account request has been submitted:
    First name: {:{first_name}:}
    Time:       {:[time]:}
    Host:       {:[host]:}
    END
        },

B<Mandatory>. The C<format> key takes a scalar or a scalarref as a value.
When the value is a B<scalarref> then it is interpreted as a file name relative to the
"templates" dir; this file will be read and its contents will serve as a value for C<format>
argument (i.e. same as specifying contents of the file to C<format> as scalar value).
If an error occured when opening the file, the plugin will set the C<plug_form_mailer_error>
in the C<{t}> special key to the error message and will set the C<format> to an empty string.

When value is a B<scalar>, it represents the body
of the e-mail that plugin will send. In this scalar you can use special "tags" that will
be replaced with data. The tag format is C<{:{TAG_NAME}:}>. Tag name cannot contain a closing
curly bracket (C<}>) in it. Two special tags are C<{:[time]:}> and C<{:[host]:}> (note
a slightly different tag format) that will
be replaced with current time and user's host respectively.

=head3 C<to>

    to => 'foo@bar.com',
    to => [ qw/foo@bar.com  foo2@bar.com/ ],

B<Mandatory>. Specifies the e-mail address(es) to which to send the e-mails. Takes either
an arrayref or a scalar as a value. Specifying a scalar is the same as specifying
an arrayref with just that scalar in it. Each element of that arrayref must be a valid
e-mail address.

=head3 C<trigger>

    trigger => [ qw/ d   plug_form_checker_ok / ],

B<Optional>. The plugin will not do anything until its "trigger" is set to a true value.
The C<trigger> argument takes an arrayref as a value. Each element of this arrayref represent
a B<hashref> key in which to find the trigger. In other words, if C<trigger> is set to
C<[ qw/ d   plug_form_checker_ok / ]> then the plugin will check if the C<plug_form_checker_ok>
key I<inside> C<{d}> ZofCMS Template special key is set to a true value. You can nest as
deep as you want, however only hashref keys are supported. B<Defaults to:>
C<[ qw/d plug_form_mailer/ ]> (C<plug_form_mailer> key inside C<d> first-level key).

=head3 C<subject>

    subject => 'Zen of Design Account Request',

B<Optional>. The C<subject> key takes a scalar as a value. This value will be the "Subject"
line in the e-mails sent by the plugin. B<Defaults to:> C<FormMailer>

=head3 C<mailer>

    mailer  => 'testfile',

B<Optional>. Specfies the "mailer" to use for e-mailing. See DESCRIPTION of L<Mail::Mailer>
for possible values and their meanings. If this value is set to a false value (or not
specified at all) then plugin will try all available mailers until one succeeds. Specifying
C<testfile> as a mailer will cause the plugin to "e-mail" data into C<mailer.testfile> file
in the same directory as your C<index.pl> file.

=head3 C<ok_key>

    ok_key  => 't',

B<Optional>. After sending an e-mail the plugin will set key C<plug_form_mailer_ok>
in one of the first-level
keys of ZofCMS Template hashref. The C<ok_key> specifies the name of that first-level key.
Note that that key's must value must be a hashref. B<Defaults to:> C<t> (thus you can
readily use the C<< <tmpl_if name="plug_form_mailer_ok"> >> to check for success (or rather
display some messages).

=head3 C<ok_redirect>

    ok_redirect => 'http://google.com/',

B<Optional>. Takes a string with a URL in it. When specified the plugin will redirect the
user to the page specified in C<ok_redirect> after sending the mail. B<By default> is not
specified.

=head1 AUTHOR

'Zoffix, C<< <'zoffix at cpan.org'> >>
(L<http://zoffix.com/>, L<http://haslayout.net/>, L<http://zofdesign.com/>)

Patches from Jon Smith aka jonsmith1982

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-zofcms-plugin-formmailer at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-ZofCMS-Plugin-FormMailer>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::ZofCMS::Plugin::FormMailer

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-ZofCMS-Plugin-FormMailer>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-ZofCMS-Plugin-FormMailer>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-ZofCMS-Plugin-FormMailer>

=item * Search CPAN

L<http://search.cpan.org/dist/App-ZofCMS-Plugin-FormMailer>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 'Zoffix, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

