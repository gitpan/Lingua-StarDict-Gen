use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Lingua::Stardict::Gen',
    AUTHOR              => 'J.Joao <jjoao@cpan.org>',
    VERSION_FROM        => 'lib/Lingua/Stardict/Gen.pm',
    ABSTRACT_FROM       => 'lib/Lingua/Stardict/Gen.pm',
    EXE_FILES           => [ "example/thesaurus2stardict"],
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Lingua-Stardict-Gen-*' },
);
