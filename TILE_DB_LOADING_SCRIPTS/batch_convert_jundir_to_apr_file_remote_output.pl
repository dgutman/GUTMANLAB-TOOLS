#!/usr/bin/perl


use File::Basename;


$FILE_IMAGE_TYPE = "svs" ;  ## ITS EITHER SVS OR NDPI
$BASE_IMAGE_INPUT_DIRECTORY = "/drobo/TCGA_IMAGE_MIRROR/NUCLEAR_MORPH_JUN/NUCL*/*/*";

### all of the directories that contain tiled images I want to turn into strips
@DIRS_TO_PARSE = glob($BASE_IMAGE_INPUT_DIRECTORY);


$IMAGE_OUTPUT_DIRECTORY = "/IMAGING_SCRATCH/ZOOMIFY_ANNOTATIONS/JUN_MORPH_RESULTS/TO_CONVERT";


foreach $dir_to_convert  ( @DIRS_TO_PARSE )
	{
	if( -d $dir_to_convert)
		{
#		print "This is a directory... $dir_to_convert \n";

		$dir_copy = $dir_to_convert;
		@PATH_SPLIT = split(/\//,$dir_copy);

		$output_directory = $IMAGE_OUTPUT_DIRECTORY . "/"  . $PATH_SPLIT[$#PATH_SPLIT-1] . "/";

if( ! -d $output_directory) { `mkdir $output_directory`;}

# . $PATH_SPLIT[$#PATH_SPLIT-0] ."/";
#		print "should be moving files to $output_directory ... \n";

		convert_a_directory( $dir_to_convert, $output_directory);
exit;

		}
	}

exit;


sub convert_a_directory( $input_target_directory, $output_directory)
	{

$input_dir = $_[0] . "/";
$output_dir = $_[1];

#print "scanning $input_dir ... \n";
#print "output dir should be $output_dir ... \n";
@FILES_TO_GLOB = glob("${input_dir}*.tiff");

my %X_HASH;
my %Y_HASH;
$MAX_X_VALUE= 0;
$MAX_Y_VALUE = 0;


$TILE_SIZE = 4096;
#$IMAGE_OUTPUT_DIRECTORY = "/IMAGING_SCRATCH/ZOOMIFY_ANNOTATIONS/JUN_MORPH_RESULTS/TO_CONVERT";
$IMAGE_OUTPUT_DIRECTORY = $output_dir;


$file_to_parse = $FILES_TO_GLOB[0];
print "first file should be $file_to_parse";
print  "-------------------\n";

($file_to_parse,$dir) = fileparse($file_to_parse);

if ( $file_to_parse =~ m/(.*)\.$FILE_IMAGE_TYPE-(\d+)-(\d+)/ ) { print "Going to process $1 ..\n";		}
else { print "unable to file an appropriate svs file... exiting.. .\n"; return;}

### I should probably also check each image is the same name.. .hmm may want to double check the hash table and see if more than one root id exists......

$command = sprintf "%s;%d;%d;%s",$FILES_TO_GLOB[$i],$2,$3,$1;

$TILE_ROOT = $1;

#$STRIP_OUTPUT_ROOT =  $IMAGE_OUTPUT_DIRECTORY  .  $TILE_ROOT;
$STRIP_OUTPUT_ROOT =  $output_dir  .  $TILE_ROOT;

print "Strip output root is $STRIP_OUTPUT_ROOT\n"; 
if( ! -d $STRIP_OUTPUT_ROOT ) { `mkdir $STRIP_OUTPUT_ROOT`; }

for($i=0;$i<=$#FILES_TO_GLOB;$i++)
	{
#print $FILES_TO_GLOB[$i] . "\n";

$file_to_parse = $FILES_TO_GLOB[$i];
$file_to_parse =~ m/\/(.*)\.$FILE_IMAGE_TYPE-(\d+)-(\d+)/;
#print "X y are $2 $3 \n";

$command = sprintf "%s;%d;%d;%s",$FILES_TO_GLOB[$i],$2,$3,$1;

$TILE_ROOT = $1;
#print $command . "\n";


if(int($2) > $MAX_X_VALUE)  { $MAX_X_VALUE = int($2) };
if(int($3) > $MAX_Y_VALUE)  { $MAX_Y_VALUE = int($3) };
	}

print "Tile root is $1 ... \n";


print "MAX X AND Y are $MAX_X_VALUE and $MAX_Y_VALUE \n";

if(! -d $STRIP_OUTPUT_ROOT) { `mkdir $STRIP_OUTPUT_ROOT`; }

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
		$statement .= sprintf "/%s.svs-%010d-%010d.tiff ", $TILE_ROOT,$x,$y;

		}

	$statement .= " +append $STRIP_OUTPUT_ROOT/" . "strip$y.tiff ";
	print $statement . "\n";
exit;
#`$statement`;
printf FP_APR "strip$y.tiff 0 $y \n";

	}

	}

### need toa dd logic to look for missing tiles
