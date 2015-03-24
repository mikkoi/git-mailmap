## no critic (Modules::RequireVersionVar)
## no critic (Documentation::RequirePodAtEnd)
## no critic (Documentation::RequirePodSections)
## no critic (Subroutines::RequireArgUnpacking)

package Git::Mailmap;

use strict;
use warnings;
use 5.010_000;

# Global creator
BEGIN {
    use parent qw( Exporter );
    our ( @EXPORT_OK, %EXPORT_TAGS );
    %EXPORT_TAGS = ();
    @EXPORT_OK   = qw();
}
our @EXPORT_OK;

# Global destructor
END {
}

# ABSTRACT: Construct and read/write Git mailmap file.

# VERSION: generated by DZP::OurPkgVersion

=head1 STATUS

Package Git::Mailmap is currently being developed so changes in the API and functionality are possible, though not likely.


=head1 SYNOPSIS

    require Git::Mailmap;
    my $mailmap = Git::Mailmap->new();

=head1 REQUIREMENTS

The Git::Mailmap package requires the following packages (in addition to normal Perl core packages):

=over 8

=item Carp::Assert

=item Carp::Assert::More

=item Params::Validate

=item Readonly

=back

=cut

use Log::Any qw{$log};
use Hash::Util 0.06 qw{lock_keys lock_keys_plus unlock_keys};
use Carp::Assert;
use Carp::Assert::More;

use Params::Validate qw(:all);
use Readonly;

# CONSTANTS
Readonly::Scalar my $EMPTY_STRING => q{};
Readonly::Scalar my $LF           => qq{\n};
Readonly::Scalar my $EMAIL_ADDRESS_REGEXP =>
  q{<[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+.>};    ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)

=head1 SUBROUTINES/METHODS

=head2 new

Creator function.

=cut

sub new {
    my $class  = shift;
    my %params = validate(
        @_, {},                              # No parameters when creating object!
    );

    $log->tracef( 'Entering new(%s, %s)', $class, \%params );
    my $self      = {};
    my @self_keys = (
        'committers',                        # Object's data.
    );
    bless $self, $class;
    $self->{'committers'} = [];
    lock_keys( %{$self}, @self_keys );
    $log->tracef( 'Exiting new: %s', $self );
    return $self;
}

=head2 add

Add new committer. Add all other information.

=over 8

=item Parameters:

=over 8

=item I<proper-email>, mandatory

=item I<proper-name>, not mandatory

=item I<commit-email>, not mandatory

=item I<commit-name>, not mandatory

=back

=item Return: [NONE]

=back

=cut

sub add {
    my $self   = shift;
    my %params = validate(
        @_,
        {
            'proper-email' => { type => SCALAR, },
            'proper-name'  => { type => SCALAR, optional => 1, depends => ['proper-email'], },
            'commit-email' => { type => SCALAR, optional => 1, },
            'commit-name'  => { type => SCALAR, optional => 1, depends => ['commit-email'], },
        }    # TODO -emails check with regexp, are "<XX@XX>"
    );
    $log->tracef( 'Entering add(%s)', \%params );
    assert_nonblank( $params{'proper-email'}, 'Parameter \'proper-email\' is a non-blank string.' );
    my $committer;
    foreach my $for_committer ( @{ $self->{'committers'} } ) {
        if ( $for_committer->{'proper-email'} eq $params{'proper-email'} ) {
            if ( $params{'proper-name'} ) {
                $for_committer->{'proper-name'} = $params{'proper-name'};
            }
            assert_listref( $for_committer->{'aliases'}, 'Item \'aliases\' exists.' );
            my $aliases = $for_committer->{'aliases'};
            my $alias;
            foreach my $for_alias ( @{$aliases} ) {
                if ( $for_alias->{'commit-email'} eq $params{'commit-email'} ) {
                    $for_alias->{'commit-name'} = $params{'commit-name'};
                    $for_alias = $for_alias;
                    last;
                }
            }
            if ( !defined $alias ) {
                $alias = { 'commit-email' => $params{'commit-email'} };
                if ( $params{'commit-name'} ) {
                    $alias->{'commit-name'} = $params{'commit-name'};
                }
                push @{$aliases}, $alias;
            }
            $committer = $for_committer;
            last;
        }
    }
    if ( !defined $committer ) {
        $committer = { 'proper-email' => $params{'proper-email'} };
        if ( $params{'proper-name'} ) {
            $committer->{'proper-name'} = $params{'proper-name'};
        }
        $committer->{'aliases'} = [];
        my $alias;
        if ( $params{'commit-email'} ) {
            $alias = { 'commit-email' => $params{'commit-email'} };
            if ( $params{'commit-name'} ) {
                $alias->{'commit-name'} = $params{'commit-name'};
            }
            push @{ $committer->{'aliases'} }, $alias;
        }
        push @{ $self->{'committers'} }, $committer;
    }
    $log->tracef( 'Exiting add: %s', $self );
    return;
}

=head2 remove

Remove committer information. Remove as much information as you can.

=over 8

=item Parameters:

=over 8

=item I<proper-email>, mandatory. If you specify only this, the whole entry (with proper-name and aliases) will be removed. Other combinations are not supported.

=item I<proper-name>, not mandatory. Not supported.

=item I<commit-email>, not mandatory. If you specify only this, every entry will be checked, and all aliases with this commit email will be removed. If you specify this together with proper-email, only the alias in the entry with that proper-email will be removed.

=item I<commit-name>, not mandatory. Not supported.

=item I<all>, not mandatory. Cannot be used together with other parameters. Removes all committers.

=back

=item Return: [NONE]

=back

=cut

sub remove {    ## no critic (Subroutines/ProhibitExcessComplexity)
    my $self   = shift;
    my %params = validate(
        @_,
        {
            'proper-email' => { type => SCALAR,  optional => 1, },
            'proper-name'  => { type => SCALAR,  optional => 1, },
            'commit-email' => { type => SCALAR,  optional => 1, },
            'commit-name'  => { type => SCALAR,  optional => 1, },
            'all'          => { type => BOOLEAN, optional => 1, },
        }
    );
    $log->tracef( 'Entering remove(%s)', \%params );
    assert(
        (
                 defined $params{'all'}
              && !defined $params{'proper-email'}
              && !defined $params{'proper-name'}
              && !defined $params{'commit-email'}
              && !defined $params{'commit-name'}
        )
          || (
            !defined $params{'all'}
            && (   defined $params{'proper-email'}
                || defined $params{'proper-name'}
                || defined $params{'commit-email'}
                || defined $params{'commit-name'} )
          ),
        'Parameter \'all\' is only present without other parameters.'
    );
    if ( defined $params{'all'} && $params{'all'} eq '1' ) {
        @{ $self->{'committers'} } = [];
    }
    else {
        my $committers = $self->{'committers'};
        for ( my $i = 0 ; $i < scalar @{ $committers } ; ) {    ## no critic (ControlStructures::ProhibitCStyleForLoops)
            my $for_committer = $committers->[$i];
            if ( $for_committer->{'proper-email'} eq $params{'proper-email'}
                || !defined $params{'commit-email'} )
            {
                if ( !defined $params{'commit-email'} ) {

                    # Cut away the whole list entry.
                    splice @{ $committers }, $i, 1;
                }
                else {
                    # Don't cut away the whole entry, just the matching aliases.
                    assert_arrayref( $for_committer->{'aliases'}, 'Item \'aliases\' exists.' );
                    my $aliases = $for_committer->{'aliases'};
                    my $alias;
                    for ( my $j = 0 ; $j < scalar @{$aliases} ; ) {    ## no critic (ControlStructures::ProhibitCStyleForLoops)
                        my $for_alias = $aliases->[$i];
                        if ( $for_alias->{'commit-email'} eq $params{'commit-email'} ) {
                            splice @{$aliases}, $i, 1;
                            last;
                        }
                        else {
                            $i++;
                        }
                    }
                }
            }
            else {
                $i++;
            }
        }
    }
    $log->tracef( 'Exiting remove: %s', $self );
    return;
}

=head2 from_string

Read the committers from a string.

=over 8

=item Parameters:

=over 8

=item I<mailmap>, mandatory. This is the mailmap file as a string.

=back

=item Return: [NONE].

=back

=cut

sub from_string {
    my $self   = shift;
    my %params = validate(
        @_,
        {
            'mailmap' => { type => SCALAR, },
        }
    );
    $log->tracef( 'Entering from_string(%s)', \%params );
    assert_defined( $params{'mailmap'}, 'Parameter \'mailmap\' is a defined string.' );
    foreach my $row ( split qr/\n/msx, $params{'mailmap'} ) {
        $log->debug( 'from_string: reading row:\'%s\'.', $row );
        if ( $row !~ /^[[:space:]]*\#/msx ) {    # Skip comment rows.
            my ( $proper_name, $proper_email, $commit_name, $commit_email ) =
              $row =~ /^(.*)($EMAIL_ADDRESS_REGEXP)(.+)($EMAIL_ADDRESS_REGEXP)[[:space:]]*$/msx;

            # Remove beginning and end whitespace.
            $proper_name =~ s/^\s+|\s+$//sxmg;
            $commit_name =~ s/^\s+|\s+$//sxmg;

            $log->debugf(
                'clean_mailmap_file(parsing):proper_name=\'%s\', proper_email=\'%s\', commit_name=\'%s\', commit_email=\'%s\'.',
                $proper_name, $proper_email, $commit_name, $commit_email );
            my %add_params = ( 'proper-email' => $proper_email );
            if ( length $proper_name > 0 ) {
                $add_params{'proper-name'} = $proper_name;
            }
            if ( length $commit_email > 0 ) {
                $add_params{'commit-email'} = $commit_email;
            }
            if ( length $commit_name > 0 ) {
                $add_params{'commit-name'} = $commit_name;
            }
            $self->add(%add_params);
        }
    }

    $log->tracef( 'Exiting from_string: %s', $self );
    return;
}

=head2 to_string

Return a string. If you give the parameter I<filename>,
the mailmap will be written directly to file. If you give no parameters,
this method will return a string consisting of the same text which otherwise
would have been written to a file.

=over 8

=item Parameters:

=over 8

=item [NONE]

=back

=item Return: string.

=back

=cut

sub to_string {
    my $self   = shift;
    my %params = validate(
        @_, {},    # No parameters!
    );
    $log->tracef( 'Entering to_string(%s)', \%params );

    # proper_part + alias_part
    # if !alias_parts, proper_part + proper_part
    my $file       = $EMPTY_STRING;
    my $committers = $self->{'committers'};
    foreach my $committer ( @{$committers} ) {
        assert_nonblank( $committer->{'proper-email'}, 'Committer has nonblank item \'proper-email}\'.' );
        my $proper_part = $EMPTY_STRING;
        if ( defined $committer->{'proper-name'} ) {
            $proper_part .= $committer->{'proper-name'} . q{ };
        }
        $proper_part .= $committer->{'proper-email'};
        assert_listref( $committer->{'aliases'}, 'Item \'aliases\' exists.' );
        my $aliases = $committer->{'aliases'};
        if ( scalar @{$aliases} > 0 ) {
            foreach my $alias ( @{$aliases} ) {
                assert_nonblank( $alias->{'commit-email'}, 'Alias has nonblank item \'commit-email}\'.' );
                my $alias_part = $EMPTY_STRING;
                if ( defined $alias->{'commit-name'} ) {
                    $alias_part .= $alias->{'commit-name'} . q{ };
                }
                $alias_part .= $alias->{'commit-email'};
                $file .= $proper_part . q{ } . $alias_part . "\n";
            }
        }
        else {
            $file .= $proper_part . q{ } . $proper_part . "\n";
        }
    }
    $log->tracef( 'Exiting to_string: %s', $file );
    return $file;
}

=head2 clean_mailmap_file

Arrange the parameter I<mailmap> (the mailmap file) into an order where
the last part of the string (the alias/committer email address)
is left justified. Return the arranged mailmap as string.

This function is currently in development. Do not use!

=over 8

=item Parameters:

=over 8

=item mailmap, mandatory.

=back

=item Return: string.

=back

=cut

sub clean_mailmap_file {
    my $self   = shift;
    my %params = validate(
        @_,
        {
            'mailmap' => { type => SCALAR, },
        }
    );
    $log->tracef( 'Entering clean_mailmap_file(%s)', \%params );
    my $file                    = $EMPTY_STRING;
    my $offset_for_commit_email = 70;              # Just a hat-value to test.
    foreach my $row ( split qr/\n/msx, $params{'mailmap'} ) {
        if ( $row =~ /^[[:space:]]*\#/msx ) {      # Skip comment rows.
            $file .= $row . $LF;
        }
        else {
            my ( $proper_name, $proper_email, $commit_name, $commit_email ) =
              $row =~ /^(.*)($EMAIL_ADDRESS_REGEXP)(.+)($EMAIL_ADDRESS_REGEXP)[[:space:]]*$/msx;

            # $proper_name =~ 3 Remove whitespace from the beginning.
            $log->debugf(
                'clean_mailmap_file(parsing):proper_name=\'%s\', proper_email=\'%s\', commit_name=\'%s\', commit_email=\'%s\'.',
                $proper_name, $proper_email, $commit_name, $commit_email );

        }
    }

    my $committers = $self->{'committers'};
    foreach my $committer ( @{$committers} ) {
        assert_nonblank( $committer->{'proper-email'}, 'Committer has nonblank item \'proper-email}\'.' );
        my $proper_part = $EMPTY_STRING;
        if ( defined $committer->{'proper-name'} ) {
            $proper_part .= $committer->{'proper-name'} . q{ };
        }
        $proper_part .= $committer->{'proper-email'};
        assert_listref( $committer->{'aliases'}, 'Item \'aliases\' exists.' );
        my $aliases = $committer->{'aliases'};
        if ( scalar @{$aliases} > 0 ) {
            foreach my $alias ( @{$aliases} ) {
                assert_nonblank( $alias->{'commit-email'}, 'Alias has nonblank item \'commit-email}\'.' );
                my $alias_part = $EMPTY_STRING;
                if ( defined $alias->{'commit-name'} ) {
                    $alias_part .= $alias->{'commit-name'} . q{ };
                }
                $alias_part .= $alias->{'commit-email'};
                $file .= $proper_part . q{ } . $alias_part . "\n";
            }
        }
        else {
            $file .= $proper_part . q{ } . $proper_part . "\n";
        }
    }
    $log->tracef( 'Exiting clean_mailmap_file: %s', $file );
    return $file;
}

1;

__END__

