package Test2::Tools::Type;

use strict;
use warnings;

use base 'Exporter';

use Test2::API qw/context/;

use Scalar::Type qw(bool_supported);

our @EXPORT = qw(is_integer is_number is_bool bool_supported);

sub is_integer { _checker(\&Scalar::Type::is_integer, @_); }
sub is_number  { _checker(\&Scalar::Type::is_number,  @_); }

sub is_bool {
    die("You need perl 5.38 or higher to use is_bool")
        unless(bool_supported());
    _checker(\&Scalar::Type::is_bool, @_);
}

sub _checker {
    my($checker, $candidate, $name) = @_;

    my $ctx = context();
    return $ctx->pass_and_release($name) if($checker->($candidate));
    return $ctx->fail_and_release($name);
}

1;
