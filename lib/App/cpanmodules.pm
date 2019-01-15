package App::cpanmodules;

# DATE
# VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'The Acme::CPANModules CLI',
};

sub _complete_module {
    require Complete::Module;
    my %args = @_;

    Complete::Module::complete_module(
        %args,
        ns_prefix => 'Acme::CPANModules',
    );
}

my %arg0_module = (
    module => {
        schema => 'perl::modname*',
        cmdline_aliases => {m=>{}},
        completion => \&_complete_module,
        req => 1,
        pos => 0,
    },
);

my %args_filtering = (
    module => {
        schema => 'perl::modname*',
        cmdline_aliases => {m=>{}},
        completion => \&_complete_module,
        tags => ['category:filtering'],
    },
    mentions => {
        schema => ['perl::modname*'],
        tags => ['category:filtering'],
    },
);

my %args_related_and_alternate = (
    related => {
        summary => 'Filter based on whether entry is in related',
        'summary.alt.bool.yes' => 'Only list related entries',
        'summary.alt.bool.not' => 'Do not list related entries',
        schema => 'bool',
    },
    alternate => {
        summary => 'Filter based on whether entry is in alternate',
        'summary.alt.bool.yes' => 'Only list alternate entries',
        'summary.alt.bool.not' => 'Do not list alternate entries',
        schema => 'bool',
    },
);

my %arg_detail = (
    detail => {
        name => 'Return detailed records instead of just module name',
        schema => 'bool',
        cmdline_aliases => {l=>{}},
    },
);

$SPEC{list_acmemods} = {
    v => 1.1,
    summary => 'List all installed Acme::CPANModules modules',
    args => {
        %args_filtering,
        %arg_detail,
    },
};
sub list_acmemods {
    require PERLANCAR::Module::List;

    my %args = @_;

    my $res = PERLANCAR::Module::List::list_modules(
        'Acme::CPANModules::', {list_modules=>1, recurse=>1});

    my @res;
    for my $e (sort keys %$res) {
        my $list;
      READ: {
            last unless $args{detail} || $args{mentions};
            (my $e_pm = "$e.pm") =~ s!::!/!g;
            require $e_pm;
            $list = ${"$e\::LIST"};
        }
        $e =~ s/^Acme::CPANModules:://;
      FILTER: {
            if ($args{module}) {
                next unless $args{module} eq $e;
            }
            if ($args{mentions}) {
                my @mods_in_list =
                    grep {defined}
                    map {($_->{module}, @{$_->{related_modules} || []}, @{$_->{alternate_modules} || []}, )}
                    @{$list->{entries}};
                next unless grep { $_ eq $args{mentions} } @mods_in_list;
            }
        }
        if ($args{detail}) {
            push @res, {
                acmemod => $e,
                summary => $list->{summary},
            };
        } else {
            push @res, $e;
        }
    }

    [200, "OK", \@res];
}

$SPEC{get_acmemod} = {
    v => 1.1,
    summary => 'Get contents of an Acme::CPANModules module',
    args => {
        %arg0_module,
    },
};
sub get_acmemod {
    my %args = @_;

    my $mod = "Acme::CPANModules::$args{module}";
    (my $mod_pm = "$mod.pm") =~ s!::!/!g;
    require $mod_pm;

    my $list = ${"$mod\::LIST"};

    [200, "OK", $list];
}

$SPEC{view_acmemod} = {
    v => 1.1,
    summary => 'View an Acme::CPANModules module as rendered POD',
    args => {
        %arg0_module,
    },
};
sub view_acmemod {
    require Pod::From::Acme::CPANModules;

    my %args = @_;

    my $res = get_acmemod(%args);
    return $res unless $res->[0] == 200;

    my %podargs;
    $podargs{list} = $res->[2];
    my $podres = Pod::From::Acme::CPANModules::gen_pod_from_acme_cpanmodules(
        %podargs);

    my $pod = $podres->{pod}{DESCRIPTION} . $podres->{pod}{'INCLUDED MODULES'};
    [200, "OK", $pod, {
        "cmdline.page_result"=>1,
        "cmdline.pager"=>"pod2man | man -l -"}];
}

$SPEC{list_entries} = {
    v => 1.1,
    summary => 'List entries from an Acme::CPANModules module',
    args => {
        %arg0_module,
        %arg_detail,
        with_attrs => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'with_attr',
            summary => 'Include additional attributes from each entry',
            schema => ['array*', of=>'str*'],
        },
    },
};
sub list_entries {
    my %args = @_;

    my $res = get_acmemod(%args);
    return $res unless $res->[0] == 200;
    my $list = $res->[2];

    my $attrs = $args{with_attrs} // [];

    my @rows;
    for my $e (@{ $list->{entries} }) {
        my $mod = $e->{module};
        my $row = {
            module => $mod,
            summary => $e->{summary},
            rating => $e->{rating},
        };
        for (@$attrs) {
            $row->{$_} = $e->{$_};
        }
        push @rows, $row;
    } # for each entry

    my $detail = $args{detail} || @$attrs;

    unless ($detail) {
        @rows = map {$_->{module}} @rows;
    }

    [200, "OK", \@rows];
}


1;
#ABSTRACT:

=head1 SYNOPSIS

Use the included script L<cpanmodules>.
