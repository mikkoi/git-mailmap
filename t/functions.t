#!perl -T
use 5.006;
use strict; use warnings;
use Test::Most;
die_on_fail;

use Log::Any::Adapter ('Stderr'); # Activate to get all log messages.
#diag("Testing Git::Mailmap $Git::Mailmap::VERSION, Perl $], $^X");

require Git::Mailmap;
my $mailmap = Git::Mailmap->new();

my %expected_mailmap = ( 'committers' => [ ] );
is_deeply($mailmap, \%expected_mailmap, 'Object internal data is empty.');

$mailmap->add('proper-email' => '<cto@company.xx>');
push @{$expected_mailmap{'committers'}}, { 'proper-email' => '<cto@company.xx>', 'aliases' => [ ], };
is_deeply($mailmap, \%expected_mailmap, 'Object has one committer.');

$mailmap->add(
    'proper-email' => '<some@dude.xx>',
    'proper-name' => 'Some Dude',
    'commit-email' => '<bugs@company.xx>',
    'commit-name' => 'nick1',
);
push @{$expected_mailmap{'committers'}}, {
    'proper-email' => '<some@dude.xx>',
    'proper-name' => 'Some Dude',
    'aliases' => [ {
        'commit-email' => '<bugs@company.xx>',
        'commit-name' => 'nick1',
    }, ],
};
is_deeply($mailmap, \%expected_mailmap, 'Object has two committers.');


my %mailmap_data = (
    'committers' => [
        {
            'proper-name' => undef, # CTO
            'proper-email' => '<cto@company.xx>',
	    'aliases' => [
                { 'commit-name' => { }, 'commit-email' => { }, },
            ]
        },
        {
            'proper-name' => 'Some Dude',
            'proper-email' => '<some@dude.xx>',
	    'aliases' => [
		{ 'commit-name' => 'nick1', 'commit-email' => '<bugs@company.xx>', },
            ]
        },
    ],
);
my $mailmap_file_contents =
'<cto@company.xx>                       <cto@coompany.xx>
Some Dude <some@dude.xx>         nick1 <bugs@company.xx>
Other Author <other@author.xx>   nick2 <bugs@company.xx>
Other Author <other@author.xx>         <nick2@company.xx>
Santa Claus <santa.claus@northpole.xx> <me@company.xx>
';
# $mailmap->read();

done_testing();

