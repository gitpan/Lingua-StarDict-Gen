package Lingua::StarDict::Gen;

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

our $VERSION = '0.02_3';


my $nome; my %dic; 
sub carregaDic {
  my %opt =(type=> "default");
  local $/;
  if(ref($_[0]) eq "HASH") {%opt = (%opt , %{shift(@_)}) } ;

  if ($opt{type} eq "default"){ $/ = "\n"; }
  if ($opt{type} eq "term")   { $/ = "";   }

  my $file = shift;
  my %dic;
  open IN,"<$file" or die "Can load $file\n";
  while (<IN>) {
      chomp;
      if (m!^%enc(oding)? ([a-zA-Z0-9-]+)!) {
         binmode IN, ":$2";
         next
      } elsif ($opt{type} eq "term") {
        $opt{lang} = $1 if(!$opt{lang} &&  m((\w+)));

        my $inf={};
        my @ls = split (/\n(?=\S)/,$_);  
        for (@ls){
          if(/(\w+)\s+(.*)/s){ push( @{$inf->{$1}}, split (/\s*[;,]\s*/,$2));} 
        }
        for(@{$inf->{$opt{lang}}}){ 
          $dic{$_} = $inf;
        }
      } elsif ($opt{type} eq "default" && /(.*?)\s*\{\s*(.*?)\s*\}/) {
        my @palavras = split (/\s*;\s*/,$2);  
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
    print IFO "date=", 1900+$t[5], "-" , $t[4]+1 , "-" , $t[3],"\n";
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

  use Lingua::Stardict::Gen;

  $dic = { word1 => ...
           word2 => ...
         }

  Lingua::Stardict::Gen::escreveDic($dic,"dicname" [,"dirpath"]);

  $dic=Lingua::Stardict::Gen::carregaDic("file");

=head1 DESCRIPTION

This module generates StarDict dictionaries from HASH references (function C<escreveDic>).

This module also imports a simple dictionary (lines with C<word {def1; def2...}>)(function
C<carragaDic>).


=head1 ABSTRACT

C<Lingua::StarDict::Gen> generates Stardict dictionaries from perl Hash

=head1 FUNCTIONS

=head2 escreveDic

  Lingua::StarDict::Gen::escreveDic($dic,"dicname");
  Lingua::StarDict::Gen::escreveDic($dic,"dicname", dir);

Write the necessary files StarDict files for dictionary in $dic HASH reference.

C<dir> is the directory where the StarDict files are written.

If no C<dir> is provided,  Lingua::StarDict::Gen will try to write it in
C</usr/share/stardict/dic/...> (the default path for StarDict dictionaries).
In this case the dictionary will be automatically installed.


=head2 carregaDic

This function loads a simple dictionary to a HASH reference.

  $dic=Lingua::StarDict::Gen::carregaDic("file");

Where file has the following sintax:

  word{def 1; def 2;... ;def n}

Example (default format):

 %encoding utf8
 cat{gato; tareco; animal com quatros patas e mia}
 dog{...}

Example2 (terminology format):

 %encoding utf8

 EN cat ; feline
 PT gato ; tareco
 DEF animal com 4 patas e que mia

 EN house; building; appartment 
 PT house
 FR maison
 ...

In this case we must say the type used:

  $dic=Lingua::StarDict::Gen::carregaDic({type=>"term"},"file");

or even specify the language:

  $dic=Lingua::StarDict::Gen::carregaDic(
        {type=>"term", lang=>"PT"},"file");

See also the script C<term2stardic> in the destribution.

=head2 mostraDic

 mostraDic($hash);

Prints to stdio the information in the hash in the form

 word -> definition

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

1; # End of Lingua::StarDict::Gen
