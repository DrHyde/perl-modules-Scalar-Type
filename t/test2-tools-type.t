use Test2::V0;
use Test2::Tools::Type;
use Test2::API qw/intercept/;

use Capture::Tiny qw(capture);
use Config;

subtest "is_* tests" => sub {
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

    is($events->[0]->name, "wow, a pass!", "test names emitted correctly when supplied");
    is($events->[1]->name, undef, "no name supplied? no name emitted");

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
        my $event = shift(@{$events});
        SKIP: {
            skip "Your perl doesn't support the Boolean type"
                if($test->{bool_required} && !bool_supported());
            isa_ok(
                $event,
                ["Test2::Event::".$test->{result}],
                $test->{name}."\t".$test->{result}
            );
        }
    }

    if(!bool_supported()) {
        like
            dies { is_bool(1==1) },
            qr/You need perl 5.38/,
            "is_bool: perl too old, exception";
    }
};

subtest "type() tests" => sub {
    my $events = intercept {
        is(1,   type('integer'));  # pass
        is(1.2, type('integer'));  # fail
        is(1,   !type('integer')); # fail
        is(1.2, !type('integer')); # pass
        is(1.2, type('number'));   # pass
        if(bool_supported()) {
            is(1==1, type('bool')); # pass
            is(1==2, type('bool')); # pass
            is(1.2,  type('bool')); # fail
        }
    };

    like(
        $events->[1]->info->[0]->details,
        qr/is of type/,
        "fail, test not negated, OP emitted in diagnostics is correct"
    );
    like(
        $events->[2]->info->[0]->details,
        qr/is not of type/,
        "fail, test negated, OP emitted in diagnostics is correct"
    );
    foreach my $test (
        { result => "Ok",   name => "is(1,    type('integer'))"  },
        { result => "Fail", name => "is(1.2,  type('integer'))"  },
        { result => "Fail", name => "is(1,    !type('integer'))" },
        { result => "Ok",   name => "is(1.2,  !type('integer'))" },
        { result => "Ok",   name => "is(1.2,  type('number'))"   },
        { result => "Ok",   name => "is(1==1, type('bool'))", bool_required => 1 },
        { result => "Ok",   name => "is(1==2, type('bool'))", bool_required => 1 },
        { result => "Fail", name => "is(1.2,  type('bool'))", bool_required => 1 },
    ) {
        my $event = shift(@{$events});
        SKIP: {
            skip "Your perl doesn't support the Boolean type"
                if($test->{bool_required} && !bool_supported());
            isa_ok(
                $event,
                ["Test2::Event::".$test->{result}],
                $test->{name}."\t".$test->{result}
            );
        }
    }

    if(!bool_supported()) {
        like
            dies { is(1, type('bool')) },
            qr/You need perl 5.38/,
            "type('bool'): perl too old, exception";
    }
    like
        dies { type('mammal') },
        qr/'mammal' is not a valid type/,
        "Invalid type, exception";
};

subtest "show supported types" => sub {
    like
        capture { system(
            $Config{perlpath}, (map { "-I$_" } (@INC)),
            qw(-MTest2::Tools::Type=show_types -e0)
        ) },
        qr/\n  bool\n/,
        "groovy";
};

done_testing;
