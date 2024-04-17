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

        is_positive(1.2,   "pass");
        is_positive(-1.2,  "fail");
        is_negative(-1.2,  "pass");
        is_negative(1.2,   "fail");

        is_positive("1.2",  "pass");
        is_negative("-1.2", "pass");

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

        { result => 'Pass', name => 'is_positive(1.2)'   },
        { result => 'Fail', name => 'is_positive(-1.2)'  },
        { result => 'Pass', name => 'is_negative(-1.2)'  },
        { result => 'Fail', name => 'is_negative(1.2)'   },

        { result => 'Pass', name => 'is_positive("1.2")'  },
        { result => 'Pass', name => 'is_negative("-1.2")' },

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
            qr/You need perl 5.36/,
            "is_bool: perl too old, exception";
    }
};

subtest "type() tests" => sub {
    my $events = intercept {
        # NB order is important! if you insert or remove tests, some of the checks
        # that failure messages are correct in like()s below may fail!
        is(1,   type('integer'));  # pass
        is(1.2, type('integer'));  # fail
        is(1,   !type('integer')); # fail
        is(1.2, !type('integer')); # pass

        is(1.2, type('number'));   # pass

        is('1.2', !type('positive', 'number')); # pass
        is('1.2', type('positive', 'number')); # fail
        is(1.2,   type('positive', 'number')); # pass
        is(-1.2,  type('positive', 'number')); # fail
        is(-1.2,  type('negative', 'number')); # pass
        is(-1.2,  type('negative', 'integer')); # fail

        is(-1.2,  type('number', -1.1)); # fail
        is(-1.2,  type('number', -1.2)); # pass

        is(4, type(integer => in_set(1, 5, 8))); # fail
        is(4, type(integer => in_set(1, 4, 8))); # pass

        if(bool_supported()) {
            is(1==1, type('bool')); # pass
            is(1==2, type('bool')); # pass
            is(1.2,  type('bool')); # fail
        }
    };

    like(
        $events->[1]->info->[0]->details,
        qr/\bis of type .* integer\b/,
        "failed test, op and name emitted in diagnostics are correct"
    );
    like(
        $events->[2]->info->[0]->details,
        qr/is not of type/,
        "failed negated test, op emitted in diagnostics is correct"
    );
    like(
        $events->[6]->info->[0]->details,
        qr/\bis of type .* positive and number\b/,
        "failed test, op and multi-name emitted in diagnostics are correct"
    );
    like(
        $events->[11]->info->[0]->details,
        qr/\bis of type .* number and has value\b/,
        "failed test, op and name with 'has value' emitted in diagnostics are correct"
    );
    like(
        $events->[13]->info->[0]->details,
        qr/\bis of type .* integer and Test2::Compare::Set /,
        "failed test, op and name with another checker emitted in diagnostics are correct"
    );
    foreach my $test (
        { result => "Ok",   name => "is(1,    type('integer'))"  },
        { result => "Fail", name => "is(1.2,  type('integer'))"  },
        { result => "Fail", name => "is(1,    !type('integer'))" },
        { result => "Ok",   name => "is(1.2,  !type('integer'))" },

        { result => "Ok",   name => "is(1.2,  type('number'))"   },

        { result => "Ok",   name => "is('1.2', !type('positive', 'number'))"  },
        { result => "Fail", name => "is('1.2', type('positive', 'number'))"   },
        { result => "Ok",   name => "is(1.2,   type('positive', 'number'))"   },
        { result => "Fail", name => "is(-1.2,  type('positive', 'number'))"   },
        { result => "Ok",   name => "is(-1.2,  type('negative', 'number'))"   },
        { result => "Fail", name => "is(-1.2,  type('negative', 'integer'))"   },

        { result => "Fail", name => "is(-1.2,  type('number', -1.1))" },
        { result => "Ok",   name => "is(-1.2,  type('number', -1.2))" },

        { result => "Fail", name => "is(4, type(integer => in_set(1, 5, 8)))" },
        { result => "Ok",   name => "is(4, type(integer => in_set(1, 4, 8)))" },

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
            qr/You need perl 5.36/,
            "type('bool'): perl too old, exception";
    }

    like
        dies { type() },
        qr/'type' requires at least one argument/,
        "argument is mandatory";
    like
        dies { type('mammal') },
        qr/'mammal' is not a valid type/,
        "Invalid type, exception";
};

subtest "checks don't mess with types" => sub {
    my $events = intercept {
        my $integer = 1;
        is_integer($integer);    # pass
        is_positive($integer);   # pass
        is_negative($integer);   # fail
        is_zero($integer);       # fail
        is($integer, !type(qw(integer positive negative zero))); # LOL
        is_integer($integer);    # pass
    };
    isa_ok(
        $events->[0],
        ['Test2::Event::Pass'],
        "starting with an int"
    );
    isa_ok(
        $events->[-1],
        ['Test2::Event::Pass'],
        "is_{positive,negative,zero} don't accidentally un-intify an int"
    );

    $events = intercept {
        my $number = 1.1;
        is_integer($number);   # fail
        is_positive($number);  # pass
        is_negative($number);  # fail
        is_zero($number);      # fail
        is($number, type(qw(integer positive negative zero))); # LOL
        is_number($number);    # pass
    };
    isa_ok(
        $events->[0],
        ['Test2::Event::Fail'],
        "starting with a float"
    );
    isa_ok(
        $events->[-1],
        ['Test2::Event::Pass'],
        "is_{positive,negative,zero} don't accidentally intify a float"
    );

    $events = intercept {
        my $string = "1.1";
        is_number($string);    # fail
        is_positive($string);  # pass
        is_negative($string);  # fail
        is_zero($string);      # fail
        is($string, type(qw(integer positive negative zero))); # LOL
        is_number($string);    # fail
    };
    isa_ok(
        $events->[0],
        ['Test2::Event::Fail'],
        "starting with a string"
    );
    isa_ok(
        $events->[-1],
        ['Test2::Event::Fail'],
        "is_{positive,negative,zero} don't accidentally numify a string"
    );
};

subtest "show supported types" => sub {
    my $types_supported = capture { system(
        $Config{perlpath}, (map { "-I$_" } (@INC)),
        qw(-MTest2::Tools::Type=show_types -e0)
    ) };
    like
        $types_supported,
        qr/\n  negative\n/,
        "found 'negative'";
};

done_testing;
