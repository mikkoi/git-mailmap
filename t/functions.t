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

$mailmap->add(
    'proper-email' => '<other@author.xx>',
    'proper-name' => 'Other Author',
    'commit-email' => '<bugs@company.xx>',
    'commit-name' => 'nick2',
);
$mailmap->add(
    'proper-email' => '<other@author.xx>',
    'proper-name' => 'Other Author',
    'commit-email' => '<nick2@company.xx>',
);
push @{$expected_mailmap{'committers'}}, {
    'proper-email' => '<other@author.xx>',
    'proper-name' => 'Other Author',
    'aliases' => [ {
        'commit-email' => '<bugs@company.xx>',
        'commit-name' => 'nick2',
    }, {
        'commit-email' => '<nick2@company.xx>',
    }, ],
};
is_deeply($mailmap, \%expected_mailmap, 'Object has three committers, one has two emails.');

$mailmap->add(
    'proper-email' => '<santa.claus@northpole.xx>',
    'proper-name' => 'Santa Claus',
    'commit-email' => '<me@company.xx>',
);
push @{$expected_mailmap{'committers'}}, {
    'proper-email' => '<santa.claus@northpole.xx>',
    'proper-name' => 'Santa Claus',
    'aliases' => [ {
        'commit-email' => '<me@company.xx>',
    }, ],
};
is_deeply($mailmap, \%expected_mailmap, 'Object has four committers, one has two emails.');

my $mailmap_file = $maipmap->write();
is :
my $expected_mailmap_file =
'<cto@company.xx>                       <cto@coompany.xx>
Some Dude <some@dude.xx>         nick1 <bugs@company.xx>
Other Author <other@author.xx>   nick2 <bugs@company.xx>
Other Author <other@author.xx>         <nick2@company.xx>
Santa Claus <santa.claus@northpole.xx> <me@company.xx>
';
# $mailmap->read();

done_testing();

