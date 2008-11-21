use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'App::ZofCMS::Plugin::FormMailer',
    license             => 'perl',
    dist_author         => q|Zoffix <'zoffix@cpan.org'>|,
    dist_version_from   => 'lib/App/ZofCMS/Plugin/FormMailer.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'File::Spec' => 3.2701,
        'App::ZofCMS'               => 0.0108,
        'App::ZofCMS::Plugin::Base' => 0.0102,
        'Mail::Send'                => 2.04,
    },
    add_to_cleanup      => [ 'App-ZofCMS-Plugin-FormMailer-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
