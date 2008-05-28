#!/usr/bin/perl -w
use Lingua::Stardict::Gen;

my $dic=Lingua::Stardict::Gen::carregaDic("microEN-PT.dic");
Lingua::Stardict::Gen::escreveDic($dic,"microEN-PT");
