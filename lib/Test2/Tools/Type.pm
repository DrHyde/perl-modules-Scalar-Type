package Test2::Tools::Type;

use strict;
use warnings;

use base qw(Exporter);

our $VERSION = '1';

use Carp qw(croak);

use Test2::API qw(context);
use Test2::Compare::Type ();

use Scalar::Type qw(bool_supported);

our @EXPORT = qw(is_integer is_number is_bool bool_supported type);

sub import {
    if($_[1] && $_[1] eq 'show_types') {
        print "Supported types:\n";
        print "  ".substr($_, 3)."\n" foreach(grep { /^is_/ } @EXPORT);
        exit;
    }
    goto &Exporter::import;
}

sub is_integer { _checker(\&Scalar::Type::is_integer, @_); }
sub is_number  { _checker(\&Scalar::Type::is_number,  @_); }

sub is_bool {
    croak("You need perl 5.36 or higher to use is_bool")
        unless(bool_supported());
    _checker(\&Scalar::Type::is_bool, @_);
}

sub _checker {
    my($checker, $candidate, $name) = @_;

    my $result = $checker->($candidate);

    # if we're coming from Test2::Compare::Type just do the check, don't
    # get/twiddle/release a context
    return $result if($Test2::Compare::Type::verifying);

    my $ctx = context();
    return $ctx->pass_and_release($name) if($result);
    return $ctx->fail_and_release($name);
}

sub type {
    my @caller = caller;
    return Test2::Compare::Type->new(
        file  => $caller[1],
        lines => [$caller[2]],
        type  => $_[0],
    );
}

1;

=head1 NAME

Test2::Tools::Type - Tools for checking data types

=head1 SYNOPSIS

    use Test2::V0;
    use Test2::Tools::Type;

    is_integer(1, "is 1 integer?");         # pass, yes it is
    is_integer('1', "is '1' an integer?");  # fail, no it's a string

    SKIP: {
        skip "Your perl is too old" unless(bool_supported());
        is_bool(1 == 2, "is false a Boolean?");   # pass, yes it is
        is_bool(3.1415, "is pi a Boolean?");      # fail, no it isn't
    }

    like
        { should_be_int => 1, other_stuff => "we don't care about this" },
        hash {
            field should_be_int => type('integer');
        },
        "is the should_be_int field an integer?";

=head1 OVERVIEW

Sometimes you don't want to be too precise in your tests, you just want to
check that your code returns the right type of result but you don't care whether
it's returning 192 or 193 - just checking that it returns an integer is good
enough.

=head1 FUNCTIONS

All these are exported by default.

=head2 bool_supported

Returns true if your perl is recent enough to have the Boolean type, false
otherwise. It will be true if your perl is version 5.35.7 or higher.

=head2 is_bool

Emits a test pass if its argument is a Boolean - ie is the result of a comparison -
and a fail otherwise.

It is a fatal error to call this on a perl that is too old. If your tests need
to run on perl 5.35.6 or earlier then you will need to check C<bool_supported>
before using it. See the L</SYNOPSIS> above.

=head2 is_integer

Emits a test pass if its argument is an integer and a fail otherwise. Note that it
can tell the difference between C<1> (an integer) and C<'1'> (a string).

=head2 is_number

Emits a test pass if its argument is a number and a fail otherwise. Note that it
can tell the difference between C<1> (a number), C<1.2> (also a number) and
C<'1'> (a string).

=head2 type

Returns a check that you can use in a test such as:

    like
        { int => 1 },
        hash { field int => type('integer'); },
        "the 'int' field is an integer";

You can negate the test with a C<!> thus. This test will fail:

    like
        { int => 1 },
        hash { field int => !type('integer'); },
        "the 'int' field is an integer";

Valid arguments are any of the C<is_*> methods' names, with the leading C<is_> removed.
You can see a list of supported types thus:

    $ perl -MTest2::Tools::Type=show_types -e0

=head1 CAVEATS

The definitions of Boolean, integer and number are exactly the same as those in
L<Scalar::Type>, which this is a thin wrapper around.

=head1 SEE ALSO

L<Scalar::Type>

L<Test2>

=head1 BUGS

If you find any bugs please report them on Github, preferably with a test case.

=head1 FEEDBACK

I welcome feedback about my code, especially constructive criticism.

=head1 AUTHOR, COPYRIGHT and LICENCE

Copyright 2024 David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

This software is free-as-in-speech software, and may be used,
distributed, and modified under the terms of either the GNU
General Public Licence version 2 or the Artistic Licence. It's
up to you which one you use. The full text of the licences can
be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut
