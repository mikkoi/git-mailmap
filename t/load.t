#!perl -T
use 5.006;
use strict;
use warnings;
use Test::Most;
die_on_fail;

require Git::Mailmap;

BEGIN {
	use_ok('Git::Mailmap') || print "Bail out!\n";
	can_ok('Git::Mailmap', 'new');
	can_ok('Git::Mailmap', 'add');
	can_ok('Git::Mailmap', 'remove');
	can_ok('Git::Mailmap', 'write');
	can_ok('Git::Mailmap', 'read');
}

#use Log::Any::Adapter ('Stderr'); # Activate to get all log messages.

diag("Testing Git::Mailmap $Git::Mailmap::VERSION, Perl $], $^X");

done_testing();

__END__
read_file(filename => '')
write_file(filename => '')

read(filename => '', string => '')
string = write(filename => '')

add(proper-name => '', proper-email => '') (if no proper name, create pseudo!
add(proper-email => '', alias-email => '')
add(proper-name, proper-email,alias-name,alias-email)

remove(proper-name, proper-email,alias-name,alias-email)

