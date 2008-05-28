#!/usr/bin/perl -w

use Lingua::Stardict::Gen;
use Biblio::Thesaurus;

$obj = thesaurusLoad('animal.the');

Lingua::Stardict::Gen::escreveDic($obj->{$obj->{baselang}}, "thesaurus-animal");
