package Lingua::Stardict::Gen;

use warnings;
use strict;
use Data::Dumper;
use locale;
use Encode;
use utf8;
#use POSIX qw(locale_h);
#setlocale(LC_ALL,"C");

$Data::Dumper::Indent=1;
$Data::Dumper::Terse=1;

our $VERSION = '0.02_1';

my $nome;
my %dic;

sub carregaDic {
    my $file = shift;
    my %dic;
    open IN,"<$file" or die "Can load $file\n";
    while (<IN>) {
        if (m!^%enc(oding)? ([a-zA-Z0-9-]+)!) {
           binmode IN, ":$2";
           next
        } elsif (/(.*?)\s*\{\s*(.*?)\s*\}/) {
          my @palavras = split (';',$2);  
          $dic{$1} = [@palavras];
        }
    }
    close IN;
    \%dic
}

sub mostraDic {
    $nome = shift;
    %dic = %{$nome};
    for my $chave (sort (keys %dic)) {
        for (@{$dic{$chave}}) {
            print "$chave -> $_\n";
        }
    }
}

sub escreveDic {
    my $hash= shift;
    my $dic = shift;
    my $dirpath=shift;
    $dirpath ||= "/usr/share/stardict/dic/" if -d "/usr/share/stardict/dic/";
    $dirpath ||= "/usr/local/share/stardict/dic/" if -d "/usr/local/share/stardict/dic/";
    unless(-d "$dirpath$dic"){
      mkdir($dirpath.$dic,0755) or die "Cant create directory $dirpath$dic\n";
    }
    chdir($dirpath.$dic);

    open DICT,">$dic.dict" or die ("Cant create $dic.dict\n");
    binmode(DICT,":utf8");
    open IDX,">$dic.idx"   or die ("Cant create $dic.idx\n");
    open IFO,">$dic.ifo"   or die ("Cant create $dic.ifo\n");
    my @keys =();
    { no locale;
      @keys = sort (keys %{$hash});
    }
    my $byteCount = 0;
    for my $chave (@keys) {
        my $posInicial = $byteCount;
        if (utf8::is_utf8($chave)) {
          print IDX pack('a*x',$chave);
        } else {
          my $string = encode_utf8($chave);
          print IDX pack('a*x',$string);
        }
        print IDX pack('N',$byteCount);
        ###  print "$chave \@ $byteCount\n";
        print DICT "$chave\n";
        $byteCount += (_len2($chave) + 1);

        if(ref($hash->{$chave}) eq "ARRAY"){
           for (@{$hash->{$chave}}) {
              print DICT "\t$_\n";
              $byteCount += (_len2($_) + 2);
           } }
        elsif(ref($hash->{$chave})) {
           my $a= _dumperpp(Dumper($hash->{$chave}));
           ###  print "DEBUG: $chave\n";
           print DICT "  $a\n";
           $byteCount += (_len2($a) +3); }
        else {
           my $a=$hash->{$chave};
           $a =~ s/\s*$//;
	   $a =~ s/\n/\n\t/g;
           ###  print "DEBUG: $chave\n\t$a\n";
           print DICT "\t$a\n";
           $byteCount += (_len2($a) +2); 
        }
        print DICT "\n\n";
        $byteCount +=2;
        print IDX pack('N',$byteCount-$posInicial);
        ###  print "length: ",($byteCount-$posInicial),"\n";
    }
    my $nword = scalar (keys %{$hash});
    my @t= gmtime(time);
    print IFO "StarDict's dict ifo file\n";
    print IFO "version=2.4.2\n";
    print IFO "wordcount=$nword\n";
    print IFO "bookname=$dic\n";
    ## print IFO "dictfilesize=$byteCount\n";
    print IFO "idxfilesize=", tell(IDX),"\n";
    print IFO "date=", 1900+$t[5], "-" , $t[4]+1 , "-" , $t[3];
    print IFO "sametypesequence=x\n";
    close(IFO);
    close(DICT);
    close(IDX);
}

sub _len2{ 
   my $string = shift;
   $string = encode_utf8($string) unless utf8::is_utf8($string);
   do { use bytes; length($string) } 
}
#sub len2{ do { length($_[0]) } }

sub _dumperpp{
   my $a = shift;
   $a =~ s/.*'_NAME_' .*\n// ;
#   $a =~ s/\$VAR\d*\s*=(\s|[\{\[])*//;
   $a =~ s/^(\s|[\{\[])*//;
   $a =~ s/[\}\]]?\s*$//;
   ## $a =~ s/\n        /\n\t/g;
   $a =~ s/\s*(\[|\]|\{|\}),?\s*\n/\n/g;
   $a =~ s/\\x\{(.*?)\}/chr(hex("$1"))/ge;
   $a =~ s/'(.*?)'/$1/g;
   $a =~ s/"(.*?)"/$1/g;
   $a;
}

1;


=head1 NAME

Lingua::Stardict::Gen - Stardict dictionary generator

=head1 SYNOPSIS

Este módulo é responsável pela criação de dicionários formatados para o Stardict, a partir de dicionários de entrada simples,do tipo palavra{definição1;definição2..} ou recorrendo à escrita de um dicionário carregado numa hash. 

  use Lingua::Stardict::Gen;

  $dic = { word1 => ...
           word2 => ...
         }

  Lingua::Stardict::Gen::escreveDic($dic,"dicname" [,"dirpath"]);

  $dic=Lingua::Stardict::Gen::carregaDic("file");

=head1 ABSTRACT

This module generates Stardict dictionaries from perl Hash

=head1 FUNCTIONS

=head2 escreveDic

Dado uma hash com o dicionário, o nome do dicionário, e a path onde será colocado, este procedimento é responsável por gerar os ficheiros necessários, de modo a que o dicionário seja compativel com o stardict, e que por ele possa ser carregado.

Se não passada  a path como argumento, os ficheiros são criados automáticamente no directóro do stardict, de modo a que o dicionário gerado, fique de imediato disponível.

=head2 carregaDic

Esta é a função responsável pelo carregamento de um dicionário (com o formato por nós escolhido) para um hash.

O ficheiro do dicionário é um ficheiro de texto com o seguinte formato

 palavra{definição1;definição2;..;definição n}

 %encoding utf8
 a{dentro de;em alguém;algum}

=head2 mostraDic

 mostraDic($hash);

Imprime para o ecrã, o dicionário carregado para a hash;

Imprime sobre a forma de palavra -> definição


=head1 Authors

José João Almeida

Alberto Simões

Paulo Silva

Paulo Soares

=head1 SEE ALSO

stardict

perl


=head1 COPYRIGHT & LICENSE

Copyright 2008 J.Joao, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Lingua::Stardict::Gen
