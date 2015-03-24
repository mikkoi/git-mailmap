#!perl -T
use 5.006;
use strict; use warnings;
use Test::Most;
die_on_fail;

# use Log::Any::Adapter ('Stderr'); # Activate to get all log messages.
#diag("Testing Git::Mailmap $Git::Mailmap::VERSION, Perl $], $^X");

require Git::Mailmap;
my $mailmap = Git::Mailmap->new();

# This is from Git git-check-mailmap manual:
# http://man7.org/linux/man-pages/man1/git-check-mailmap.1.html
## no critic (ValuesAndExpressions/ProhibitImplicitNewlines)
my $given_mailmap_file =
'<cto@company.xx>                       <cto@coompany.xx>
Some Dude <some@dude.xx>         nick1 <bugs@company.xx>
Other Author <other@author.xx>   nick2 <bugs@company.xx>
Other Author <other@author.xx>         <nick2@company.xx>
Santa Claus <santa.claus@northpole.xx> <me@company.xx>
';
$mailmap->from_string('mailmap' => $given_mailmap_file);

my %expected_mailmap = ( 'committers' => [ ] );
push @{$expected_mailmap{'committers'}}, {
    'proper-email' => '<cto@company.xx>',
    'aliases' => [ {
        'commit-email' => '<cto@coompany.xx>',
    } ],
};
push @{$expected_mailmap{'committers'}}, {
    'proper-email' => '<some@dude.xx>',
    'proper-name' => 'Some Dude',
    'aliases' => [ {
        'commit-email' => '<bugs@company.xx>',
        'commit-name' => 'nick1',
    }, ],
};
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
push @{$expected_mailmap{'committers'}}, {
    'proper-email' => '<santa.claus@northpole.xx>',
    'proper-name' => 'Santa Claus',
    'aliases' => [ {
        'commit-email' => '<me@company.xx>',
    }, ],
};
# explain($mailmap);
# explain(\%expected_mailmap);
is_deeply($mailmap, \%expected_mailmap, 'Object internal data is populated correctly.');

done_testing();

