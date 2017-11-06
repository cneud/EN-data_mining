#!/usr/bin/perl -w

# document metadata generation from METS/ALTO :
# 1st parameter : document file to be processed
# following parameters : output formats
# perl extractMD.pl DOCS xml json

# use strict;
use warnings;
use 5.010;
#use LWP::Simple;
use Data::Dumper;
#use XML::Twig;
use Path::Class;
use Benchmark qw(:all) ;
use utf8::all;

$t0 = Benchmark->new;


# use UTF-8 for correct display on STDOUT
binmode(STDOUT, ":utf8");

$DPI=300;

# repository for extracted metadata
$OUT = "STATS";
if(-d $OUT){
		say "Writing to $OUT...";
	} else
	{
    mkdir ($OUT) || die ("Error creating directory \n");
    say "Creating $OUT...";
	}


# output format
@FORMATS = ();

# repository for extracted metadata
$DOCS = "DOCS";

# number of documents processed
$nbDoc=0;

# current ALTO page
$numPageALTO=1;


# metadata/values hash table
%hash = ();

# filter on METS sections
$handlerMETS = {
	#'mets:dmdSec[@ID="MODSMD_ISSUE1"]'  => \&getMD,   # bibliographical metadata
  #'mets:structMap[@TYPE="PHYSICAL"]'  => \&getNbPages,
  'mets:structMap[@TYPE="LOGICAL"]'  => \&getNbArticles,  # number of articles
};

# filter on ALTO files
$handlerALTO = {
	'/alto/Layout' => \&getALTO,
};


# ----------------------
# retrieving bibliographical metadata
sub getMD {my ($t, $elt) = @_;
	   #my $id = $elt->att('id');
	   $hash{"title"} = $elt->child(0)->child(0)->child(0)->child(0)->child(0)->text();
	   $hash{"date"} = $elt->child(0)->child(0)->child(0)->child(2)->child(0)->text();
	   $t -> purge();
	}

# retrieving pages
sub getNbPages {my ($t, $elt) = @_;
	   $hash{"pages"} = scalar($elt->child(0)->children);
	   $t -> purge();
	}


# retrieving articles
sub getNbArticles {my ($t, $elt) = @_;
	   $hash{"articles"} = scalar($elt->get_xpath('//mets:div[@TYPE="ARTICLE"]'));
	   $t -> purge();
	}

# retrieving infos from ALTO file
sub getALTO {my ($t, $elt) = @_;

	   #my $page = $elt->child(0)->att(PHYSICAL_IMG_NR);
	   if ($numPageALTO == 1) {
	     $hash{"largeur"} = int($elt->child(0)->att(WIDTH)*25.4/$DPI);
	     $hash{"hauteur"} = int($elt->child(0)->att(HEIGHT)*25.4/$DPI);
	     }
	   # obtained by match
	   #$hash{$page."_words"} = scalar($elt->get_xpath('//String'));
	   #$hash{$page."_textBlocks"} = scalar($elt->get_xpath('//TextBlock'));
	   #$hash{$page."_adBlocks"} = scalar($elt->get_xpath('//ComposedBlock[(@TYPE="Advertisement")]'));
	   #$hash{$numPageALTO."_tabBlocks"} = scalar($elt->get_xpath('//ComposedBlock[(@TYPE="Table")]'));
	   #$hash{$numPageALTO."_illustrationBlocks"} = scalar($elt->get_xpath('//Illustration'));

	   $t -> purge();
	}



####################################
## START
if(scalar(@ARGV)<2){
	die "Mandatory argument :
	1 - file to be processed
	2 - output format : csv json xml txt
	";
}

$DOCS=shift @ARGV;
if(-e $DOCS){
		say "Reading $DOCS...";
	}
	else{
		die "$DOCS does not exist !\n";
	}

while(@ARGV){
	push @FORMATS, shift;
}


my $dir = dir($DOCS);
say "--- documents : ".$dir->children(no_hidden => 1);

$dir->recurse(depthfirst => 1, callback => sub {
	my $obj = shift;

	if ($obj->is_dir) {
		if ($obj->basename ne "ALTO") {
		   $id = $obj->basename;
		   print "\n".$id."... ";
		   $nbDoc=$nbDoc + generateMD($obj,$id,$handlerMETS);

		 } else {
		 	#print "ALTO...\n";
		 	generateMDALTO($obj,$obj->parent->basename,$handlerALTO);
		 	$hash{"pages"} = $numPageALTO-1;

		 	foreach my $f (@FORMATS) {
  			writeMD($f);}
			}
	}
});

say "\n\n=============================";
say "$nbDoc documents processed";
say "=============================";

$t1 = Benchmark->new;
$td = timediff($t1, $t0);
say "the code took:",timestr($td);

########### END ##################



#open(FIC, "$fic") or say "No file found !\n";
#print "...\n";

#my $txt;
#while(<FIC>){
	#$txt=$_;
  #$nbURL++;
	#print "\n$nbURL : ";
	#$nbDoc=$nbDoc + generateMD($txt,$handlerRefnum);
#}
#close FI;


# ----------------------
# processing documents metadata from METS
sub generateMD {
	my $rep=shift;
	my $idDoc=shift;
  my $handler=shift;


	my $ficMETS = $rep->file($idDoc."-METS.xml");
	  if(-e $ficMETS){
		   return readMD($ficMETS,$idDoc,$handler);
	     }
	   else{
		   say "$ficMETS does not exist !";
		   return 0;
	   }
}


# ----------------------
# parsing a METS file and writing the metadata
sub readMD {
	my $ficMETS=shift;
	my $idDoc=shift; # ID document
	my $handler=shift;

	my $t;
	my $articles = 0;
	my $title = "unknown";
	my $date = "unknown";

	# raz hash
	%hash = ();

	print "Loading $ficMETS...\n";
  #$t = XML::Twig -> new(output_filter=>'safe');
  #$t = XML::Twig -> new();
  #$t -> setTwigHandlers($handlerMETS); # parse with a gestionnaire
  #$t -> parsefile($ficMETS);
  #$t -> purge(); # unload the parsed content

  # extract by regex (fast)
  open my $fh, '<', $ficMETS or die "Cannot open : $ficMETS !";
  if ($articles==0) {
  	local $/;
  	( $title ) = <$fh> =~ m/\<title\>(.+)\<\/title\>/;
 	  seek $fh, 0, 0;
  	( $date ) = <$fh> =~ m/\>(.+)\<\/mods:dateIssued/;
  	seek $fh, 0, 0;
  	$hash{"title"} = $title;
		$hash{"date"} = $date;
		$hash{"supplement"}=(length($idDoc)>10); # supplements have the extension _02_1
		if (length($idDoc)>10) {
		 $hash{"supplement"}="TRUE";}
		 	else {$hash{"supplement"}="FALSE";}
  }

  while (my $line = <$fh>) {
   $articles++  if $line =~ /ARTICLE/;   # TYPE="ARTICLE"
  }
	$hash{"articles"} = $articles;

	return 1;
}

# processing document metadata from ALTO
sub generateMDALTO {
	my $rep=shift;
	my $idDoc=shift;
  my $handler=shift;

  #print "REP :".$rep;
  #print "  ID : ". $idDoc."  ";
  $numPageALTO=1;

  # process all ALTO files and add the output to the metadata
	while (my $file = $rep->next) {
			if (index($file, ".xml") != -1) {
		    print $numPageALTO."\n";
		    readMDALTO($file,$numPageALTO,$idDoc,$handler);
		    $numPageALTO++;
		  }
}}


# analysis of an ALTO file and writing the metadata file
sub readMDALTO {
	my $file=shift;
	my $numPage=shift;
	my $idDoc=shift; # ID document
	my $handler=shift;

	#my $t;

  my $words = 0;
  my $texts = 0;
  my $ads = 0;
  my $ills = 0;
  my $tabs = 0;


	# raz hash
	#%hash = ();

	#  extract by parsing (slow)
	#$t = XML::Twig -> new(output_filter=>'safe');
  #$t -> setTwigHandlers($handlerALTO); # parsing with a gestionnaire
  #$t -> parsefile($file);
  #$t -> purge(); # unload the parsed content

  # extract by regex (fast)
  open my $fh, '<', $file or die "Cannot open : $fichier !";

  if ($numPage == 1) {
  	local $/;
  	my ( $width ) = <$fh> =~ m/WIDTH=\"(\d+)\"/;
  	#my $width  = extractChain("WIDTH=\"(\d+)\"",$fh);
  	seek $fh, 0, 0;
    my ( $height ) = <$fh> =~ m/HEIGHT=\"(\d+)\"/;

    $hash{"width"} = int($width*25.4/$DPI); # conversion to mm
    $hash{"height"} = int($height*25.4/$DPI);
    seek $fh, 0, 0;
}

  while (my $line = <$fh>) {
   $words++  if $line =~ /<String/;
   $texts++ if $line =~ /<TextBlock/;
   $ads++ if $line =~ /\"Advertisement/;
   $ills++ if $line =~ /\"Illustration/;
   $tabs++ if $line =~ /\"Table/;
  }

  $hash{$numPage."_words"} = $words;
  $hash{$numPage."_textBlocks"} = $texts;
  $hash{$numPage."_adBlocks"} = $ads;
  $hash{$numPage."_illustrationBlocks"} = $ills;
  $hash{$numPage."_tabBlocks"} = $tabs;

  close $fh;
}





# ----------------------
# writing the metadata
sub writeMD {
	my $format=shift;;

  my $ficOut = $OUT."/".$id.".".$format;

  # delete if already exists
  if(-e $ficOut){
		unlink $ficOut;
	}

  if ((keys %hash)==0) {
  	say "HASH EMPTY !";
  	  }
  # metadata output file
  open my $fh, '>>', $ficOut;

  if ($format eq "csv") {
  	print "csv...";
  	print {$fh} $hash{"title"}.";";
  	print {$fh} $hash{"date"}.";";
  	print {$fh} $hash{"pages"}.";";
  	print {$fh} $hash{"articles"}.";";
  	print {$fh} $hash{"width"}.";";  # in mm
    print {$fh} $hash{"height"}.";";
    print {$fh} $hash{"supplement"}.";";
    for($p = 1; $p <= $hash{"pages"}; $p++) {
      print {$fh} $hash{$p."_words"}.";";
      print {$fh} $hash{$p."_textBlocks"}.";";
      print {$fh} $hash{$p."_tabBlocks"}.";";
      print {$fh} $hash{$p."_adBlocks"}.";";
      print {$fh} $hash{$p."_illustrationBlocks"}.";";
      	}
     print {$fh} "\n";
  }
  elsif ($format eq "xml") {
  	print "xml...";
  	print {$fh} "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<analyseAlto>\n<metad>";
  	print {$fh} "<title>".$hash{"title"}."</title>";
  	print {$fh} "<dateEdition>".$hash{"date"}."</dateEdition>";
  	print {$fh} "<nbPage>".$hash{"pages"}."</nbPage>";
  	print {$fh} "<suppl>".$hash{"supplement"}."</suppl></metad>";
  	print {$fh} "<contents>";
  	print {$fh} "<nbArticle>".$hash{"articles"}."</nbArticle>";
  	print {$fh} "<width>".$hash{"width"}."</width>";  # in mm
    print {$fh} "<height>".$hash{"height"}."</height>";
    for($p = 1; $p <= $hash{"pages"}; $p++) {
      print {$fh} "<page>";
      print {$fh} "<nbWord>".$hash{$p."_words"}."</nbWord>";
      print {$fh} "<textBlocks>".$hash{$p."_textBlocks"}."</textBlocks>";
      print {$fh} "<tabBlocks>".$hash{$p."_tabBlocks"}."</tabBlocks>";
      print {$fh} "<adBlocks>".$hash{$p."_adBlocks"}."</adBlocks>";
      print {$fh} "<illustrationBlocks>".$hash{$p."_illustrationBlocks"}."</illustrationBlocks>";
      print {$fh} "</page>";
      }
    print {$fh} "</contents></analyseAlto>\n";
  }
  elsif ($format eq "json") {
  	print "json...";
  	print {$fh} "{ \"metad\":\n";
  	print {$fh} " { \"title\": \"".$hash{"title"}."\",\n";
  	print {$fh} "   \"dateEdition\": \"".$hash{"date"}."\",\n";
  	print {$fh} "   \"nbPage\": ".$hash{"pages"}.",\n";
  	print {$fh} "     \"suppl\": \"".$hash{"supplement"}."\"},\n";
  	print {$fh} "  \"contenus\": {\n";
  	print {$fh} "     \"nbArticle\": ".$hash{"articles"}.",\n";
  	print {$fh} "     \"width\": ".$hash{"width"}.",\n";  # in mm
    print {$fh} "     \"height\": ".$hash{"height"}.",\n";
    print {$fh} "  \"page\": [\n";
    for($p = 1; $p <= $hash{"pages"}; $p++) {
      print {$fh} "    {\"nbWord\": ".$hash{$p."_words"}.",";
      print {$fh} " \"textBlocks\": ".$hash{$p."_textBlocks"}.",";
      print {$fh} " \"tabBlocks\": ".$hash{$p."_tabBlocks"}.",";
      print {$fh} " \"adBlocks\": ".$hash{$p."_adBlocks"}.",";
      print {$fh} " \"illustrationBlocks\": ".$hash{$p."_illustrationBlocks"}."}";
      if ($p<$hash{"pages"}) { print {$fh} ",\n";}
      }
    print {$fh} "]}}";}
  else {  # TXT
  	#say Dumper(\%hash);
  	print "txt...";
  	while (my ($cle,$value)=each %hash) {
  	print {$fh} $cle.":".$value."\n";
  }}
  close $fh;
}


# ----------------------
# calculate ARK based on BNF document ID
sub calculateArk {my $id=shift;

    	my $ark="1";
    	my $type="NUMM"; #

    	print substr($id, 0, 5);
    	print  "\n";
    	if ($type ne "IFN"){
    		$ark="ark:/12148/".$id.arkControle("bpt6k".$id);
    	} else
    	{
    	  $ark="ark:/12148/".$id.arkControle("btv1b".$id);
    	}

    	return $ark;

    }

# calculate ARK control character based on ARK name
sub arkControle {my $txt=shift;

	my $ctrl="";
	my $tableCar="0123456789bcdfghjkmnpqrstvwxz";


     return 1;
}