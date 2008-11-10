#!/usr/bin/env perl

use Test::More tests => 4;

BEGIN {
    use_ok('App::ZofCMS');
    use_ok('App::ZofCMS::Plugin::Base');
    use_ok('Mail::Send');
	use_ok( 'App::ZofCMS::Plugin::FormMailer' );
}

diag( "Testing App::ZofCMS::Plugin::FormMailer $App::ZofCMS::Plugin::FormMailer::VERSION, Perl $], $^X" );
