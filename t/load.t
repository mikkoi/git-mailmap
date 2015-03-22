#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

require Git::Mailmap;

plan tests => 4;

BEGIN {
	use_ok('Git::Mailmap') || print "Bail out!\n";
	can_ok('Git::Mailmap', '');
	can_ok('Git::Mailmap', 'ironmq');
	can_ok('Git::Mailmap', 'ironworker');
}

#use Log::Any::Adapter ('Stderr'); # Activate to get all log messages.

diag("Testing Git::Mailmap $Git::Mailmap::VERSION, Perl $], $^X");

__END__
read_file(filename => '')
write_file(filename => '')

read(filename => '', string => '')
string = write(filename => '')

add(proper-name => '', proper-email => '') (if no proper name, create pseudo!
add(proper-email => '', alias-email => '')
add(proper-name, proper-email,alias-name,alias-email)

remove(proper-name, proper-email,alias-name,alias-email)

