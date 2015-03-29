#!perl -T
use 5.006;
use strict;
use warnings;
use Test::Most;


# use Log::Any::Adapter ('Stderr'); # Activate to get all log messages.

require Git::Mailmap;
my $mailmap = Git::Mailmap->new();

# This is from Git git-check-mailmap manual (with slight changes):
# http://man7.org/linux/man-pages/man1/git-check-mailmap.1.html
## no critic (ValuesAndExpressions/ProhibitImplicitNewlines)
my $given_mailmap_file = '<cto@company.xx> <cto@coompany.xx>
Some Dude <some@dude.xx> nick1 <bugs@company.xx>
Other Author <other@author.xx> nick2 <bugs@company.xx>
Other Author <other@author.xx> <nick2@company.xx>
Santa Claus <santa.claus@northpole.xx> <me@company.xx>

';
$mailmap->from_string( 'mailmap' => $given_mailmap_file );


#verify
my $verified = $mailmap->verify(    'proper-email' => '<santa.claus@northpole.xx>');
is( $verified, 1, 'Proper email verified.' );
$verified = $mailmap->verify(    'proper-email' => '<Santa.Claus@northpole.xx>');
is( $verified, 0, 'Proper email verified (not found).' );
$verified = $mailmap->verify(    'commit-email' => '<me@company.xx>');
is( $verified, 1, 'Commit email verified.' );
$verified = $mailmap->verify(    'commit-email' => '<Me@company.xx>');
is( $verified, 0, 'Commit email verified (not found).' );
$verified = $mailmap->verify(    'proper-email' => '<cto@company.xx>');
is( $verified, 1, 'Proper email verified.' );
$verified = $mailmap->verify(    'proper-name' => 'Some Dude', 'proper-email' => '<some@dude.xx>');
is( $verified, 1, 'Proper email verified.' );
$verified = $mailmap->verify(    'proper-name' => 'SOME Dude', 'proper-email' => '<some@dude.xx>');
is( $verified, 0, 'Proper email verified (not found).' );

$verified = $mailmap->verify(
    'proper-name' => 'Some Dude With Wrong Name',
    'proper-email' => '<some@dude.xx>',
    );
is( $verified, 0, 'Proper email verified. No match when wrong name.');
$verified = $mailmap->verify(
    # No proper-name this time!
    'proper-email' => '<some@dude.xx>',
    );
is( $verified, 1, 'Proper email verified. Match when no name is given.' );


# map
# my $proper_email;
# my $proper_name;
# ($proper_email,$proper_name) = 
my @proper;
@proper = $mailmap->map( 'email' => '<cto@company.xx>' );
is_deeply( \@proper, [undef,'<cto@company.xx>'], 'Mapped <cto@company.xx> to <cto@company.xx>.' );
@proper = $mailmap->map( 'email' => '<cto@coompany.xx>' );
is_deeply( \@proper, [undef,'<cto@company.xx>'], 'Mapped <cto@coompany.xx> to <cto@company.xx>.' );
@proper = $mailmap->map( 'email' => '<some@dude.xx>' );
is_deeply( \@proper, ['Some Dude','<some@dude.xx>'], 'Mapped <some@dude.xx> to Some Dude.' );
@proper = $mailmap->map( 'email' => '<bugs@company.xx>' );
is_deeply( \@proper, ['Some Dude','<some@dude.xx>'], 'Mapped <bugs@company.xx> to Some Dude (when no name, maps to first found email).' );
@proper = $mailmap->map( 'name' => 'nick2', 'email' => '<bugs@company.xx>' );
is_deeply( \@proper, ['Other Author','<other@author.xx>'], 'Mapped <other@author.xx> to Other Author (with name maps to another).' );
@proper = $mailmap->map( 'email' => '<nick2@company.xx>' );
is_deeply( \@proper, ['Other Author','<other@author.xx>'], 'Mapped <nick2@company.xx> to Other Author (found the second alias).' );
@proper = $mailmap->map( 'email' => '<not_mapped_address@address>' );
is_deeply( \@proper, [undef,undef], 'Not mapped <not_mapped_address@address>.' );
@proper = $mailmap->map( 'email' => 'faulty_email_address>' );
is_deeply( \@proper, [undef,undef], 'Not mapped "faulty_email_address>".' );
dies_ok { @proper = $mailmap->map( 'email' => '' ) } 'Failed when empty email address string.';

done_testing();
__END__
<cto@company.xx>                                <cto@coompany.xx>
Some Dude <some@dude.xx>                  nick1 <bugs@company.xx>
Other Author <other@author.xx>            nick2 <bugs@company.xx>
Other Author <other@author.xx>                  <nick2@company.xx>
Santa Claus <santa.claus@northpole.xx>          <me@company.xx>

