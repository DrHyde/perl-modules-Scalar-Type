use Test2::V0;
use Test2::Tools::Type;
use Test2::API qw/intercept/;

my $events = intercept {
    is_integer(1,   "wow, a pass!");
    is_integer(1.2);
    is_integer("1", "fail");

    is_number(1,   "pass");
    is_number(1.2, "pass");
    is_number("1", "fail");

    if(bool_supported()) {
        is_bool(1==1, "pass");
        is_bool(1==2, "pass");
        is_bool(1,    "fail");
        is_integer(1==1, "fail");
        is_number(1==1, "fail");
        is_integer(1==2, "fail");
        is_number(1==2, "fail");
    }
};

is($events->[0]->facet_data->{assert}->{details}, "wow, a pass!", "test names emitted correctly when supplied");
is($events->[1]->facet_data->{assert}->{details}, undef, "no name supplied? no name emitted");

foreach my $test (
    { result => 'Pass', name => 'is_integer(1)'   },
    { result => 'Fail', name => 'is_integer(1.2)' },
    { result => 'Fail', name => 'is_integer("1")' },
    { result => 'Pass', name => 'is_number(1)'    },
    { result => 'Pass', name => 'is_number(1.2)'  },
    { result => 'Fail', name => 'is_number("1")'  },
    { result => 'Pass', name => 'is_bool(1==1)',    bool_required => 1 },
    { result => 'Pass', name => 'is_bool(1==2)',    bool_required => 1 },
    { result => 'Fail', name => 'is_bool(1)',       bool_required => 1 },
    { result => 'Fail', name => 'is_integer(1==1)', bool_required => 1 },
    { result => 'Fail', name => 'is_number(1==1)',  bool_required => 1 },
    { result => 'Fail', name => 'is_integer(1==2)', bool_required => 1 },
    { result => 'Fail', name => 'is_number(1==2)',  bool_required => 1 },
) {
    SKIP: {
        skip "Your perl doesn't support the Boolean type"
            if($test->{bool_required} && !bool_supported());
        isa_ok(
            shift(@{$events}),
            ["Test2::Event::".$test->{result}],
            $test->{name}."\t".$test->{result}
        );
    }
}

done_testing;
