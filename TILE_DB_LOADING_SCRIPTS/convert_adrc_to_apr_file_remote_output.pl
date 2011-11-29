#!/usr/bin/perl


use File::Basename;


$FILE_IMAGE_TYPE = "ndpi" ;  ## ITS EITHER SVS OR NDPI

$img_extension_type = "tif";

@FILES_TO_GLOB = glob("*.$img_extension_type");


my %X_HASH;
my %Y_HASH;


$MAX_X_VALUE= 0;
$MAX_Y_VALUE = 0;

$TILE_SIZE = 2048;

$IMAGE_OUTPUT_DIRECTORY = "/IMAGING_SCRATCH/ADRC/PYRAMIDS/ADRC/TO_CONVERT";

$blank_tile = "/home/dgutman/Dropbox/GIT_ROOT/TILE_DB_LOADING_SCRIPTS/" . "blank${TILE_SIZE}x${TILE_SIZE}.tif";




$file_to_parse = $FILES_TO_GLOB[0];
if ( $file_to_parse =~ m/(.*)\.$FILE_IMAGE_TYPE-(\d+)-(\d+)/ ) { print "Going to process $1 ..\n";		}
else { print "unable to file an appropriate svs file... exiting.. .\n"; }

### I should probably also check each image is the same name.. .hmm may want to double check the hash table and see if more than one root id exists......


$command = sprintf "%s;%d;%d;%s",$FILES_TO_GLOB[$i],$2,$3,$1;

$TILE_ROOT = $1;

$STRIP_OUTPUT_ROOT =  $IMAGE_OUTPUT_DIRECTORY  . "/" . $TILE_ROOT ."/";

print "Strip output root is $STRIP_OUTPUT_ROOT\n";

if( ! -d $STRIP_OUTPUT_ROOT ) { `mkdir $STRIP_OUTPUT_ROOT`; }

for($i=0;$i<=$#FILES_TO_GLOB;$i++)
	{

print $FILES_TO_GLOB[$i] . "\n";

$file_to_parse = $FILES_TO_GLOB[$i];

$file_to_parse =~ m/(.*)\.$FILE_IMAGE_TYPE-(\d+)-(\d+)/;

#print "X y are $2 $3 \n";

$command = sprintf "%s;%d;%d;%s",$FILES_TO_GLOB[$i],$2,$3,$1;
$TILE_ROOT = $1;

#print $command . "\n";

if(int($2) > $MAX_X_VALUE)  { $MAX_X_VALUE = int($2) };
if(int($3) > $MAX_Y_VALUE)  { $MAX_Y_VALUE = int($3) };
	}

print "MAX X AND Y are $MAX_X_VALUE and $MAX_Y_VALUE \n";


if(!open(FP_APR,">$STRIP_OUTPUT_ROOT//$TILE_ROOT.apr") )
	{
	print "Unable top open APR root file... hmm \n";
	}

### NOW BUILDING STRIPS.....


	for($y=0;$y<=$MAX_Y_VALUE;$y+=$TILE_SIZE)
		{
$statement  = "convert  ";


for($x=0;$x<=$MAX_X_VALUE;$x+=$TILE_SIZE)
	{
### had a ppm in there too--- this is an artifact


		$current_jpg_file = sprintf "%s.ndpi-%010d-%010d.tif", $TILE_ROOT,$x,$y,$img_extension_type;
#		print "This jpg... does it exist?  $current_jpg_file .. \n";
		if( -e $current_jpg_file ) {
				$statement .= $current_jpg_file ." ";
#				 print "found it... \n"; 
				}
				 else 
				{
				 print "uhoh \n";
				$statement .= $blank_tile ." ";
				}

		}

	$statement .= " +append $STRIP_OUTPUT_ROOT/" . "strip$y.tif ";
	print $statement . "\n";
`$statement`;
printf FP_APR "strip$y.tif 0 $y \n";

	}



### need toa dd logic to look for missing tiles
