#!/usr/bin/env perl

use Test::More tests => 5;

BEGIN {
    use_ok('File::Spec');
    use_ok('App::ZofCMS');
    use_ok('App::ZofCMS::Plugin::Base');
    use_ok('Mail::Send');
	use_ok( 'App::ZofCMS::Plugin::FormMailer' );
}

diag( "Testing App::ZofCMS::Plugin::FormMailer $App::ZofCMS::Plugin::FormMailer::VERSION, Perl $], $^X" );
