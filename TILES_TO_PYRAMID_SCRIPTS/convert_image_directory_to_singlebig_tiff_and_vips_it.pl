#!/usr/bin/perl
use File::Basename;

$FILE_IMAGE_TYPE = "ndpi" ;  ## ITS EITHER SVS OR NDPI
$img_extension_type = "tif";


$BASE_DIRECTORY_TO_TRANSCODE = "/IMAGING_SCRATCH/ADRC/PYRAMIDS/ADRC/TO_CONVERT/";


@DIRS_TO_RECODE = `find $BASE_DIRECTORY_TO_TRANSCODE -maxdepth 1 -type d`;

$DATA_GROUP = "OPK";

#SINGLE_TIFF
# VIPS_PYRAMID_FORMAT

#SINGLE_TIFF
# VIPS_PYRAMID_FORMAT

$TRANSCODING_STAGING_AREA = "/IMAGING_SCRATCH/STAGING_AREA/";


foreach $directory (@DIRS_TO_RECODE)
	{
	chomp($directory);
	print $directory ."\n";

### in this case I am going to  parse the APR file I generated... since I still don't have a converterd anyway
##@FILES_TO_GLOB = glob("${directory}/*.${img_extension_type}");
@FILES_TO_GLOB = glob("${directory}/*.apr");

my %X_HASH;
my %Y_HASH;
$MAX_X_VALUE= 0;
$MAX_Y_VALUE = 0;
$file_to_parse = $FILES_TO_GLOB[0];
print "Base file is $file_to_parse \n";

if(! -e $file_to_parse) { print "No apr file found... skipping to next \n"; next;}

#if ( $file_to_parse =~ m/(.*)\.$FILE_IMAGE_TYPE-(\d+)-(\d+)/ ) { print "Going to process $1 ..\n";      }
#else { print "unable to file an appropriate tiff base file... skiping next directory.. .\n";  next;}

if(!open(FP_APR,"<$file_to_parse"))
	{
	print "Can not open $file_to_parse \n";
	exit;
	}




($file,$dir) = fileparse($file_to_parse);
print "Base path should  be $dir \n"; 

$slide_name = $file;
$slide_name =~ s/\.apr//;




$DATA_GROUP = "OPK";

$output_vips_file = $TRANSCODING_STAGING_AREA . $DATA_GROUP . "/VIPS_PYRAMID_FORMAT/";
$output_single_tiff_file = $TRANSCODING_STAGING_AREA . $DATA_GROUP .  "/SINGLE_TIFF/";

if( ! -d $output_vips_file) { `mkdir -p $output_vips_file`;}
if( ! -d $output_single_tiff_file) { `mkdir -p $output_single_tiff_file`;}


$output_vips_file = $output_vips_file . "$slide_name.dzi.tif";
$output_single_tiff_file = $output_single_tiff_file . "$slide_name.singletif.tif";

$cascase_output =0;

$starting_file = <FP_APR>;




$starting_file = $dir . $starting_file;
$starting_file =~ s/ 0 0//;
chomp($starting_file);
print $starting_file . " is starting file";


$CURRENT_INPUT_FILE = $starting_file ;
$CURRENT_OUTPUT_FILE = "/tmp/tif_join_1.tif";


$files_processed=1;
while(<FP_APR>)
	{
$files_processed++;
	chomp;

	@COLS = split(/\s/);
	print $COLS[0] ."\n";

$CURRENT_OUTPUT_FILE = "/tmp/tif_join_$files_processed.tif";

$statement = "vips im_tbjoin $CURRENT_INPUT_FILE $dir$COLS[0] $CURRENT_OUTPUT_FILE";
print $statement . "\n";
#`$statement`;
$CURRENT_INPUT_FILE = $CURRENT_OUTPUT_FILE ;
	}
print "Check to see if $output_vips_file or $output_single_tiff_file exist ";

exit;


	}	



exit;

$TILE_SIZE = 4096;  ## this varies

$IMAGE_OUTPUT_DIRECTORY = "/data2/dgutman/madhu_tmas/40X_Tiles/PYRAMIDS/";

$blank_tile = "/data2/dgutman/" . "blank${TILE_SIZE}x${TILE_SIZE}.tif";



### I should probably also check each image is the same name.. .hmm may want to double check the hash table and see if more than one root id exists......

$command = sprintf "%s;%d;%d;%s",$FILES_TO_GLOB[$i],$2,$3,$1;

$TILE_ROOT = $1;

$STRIP_OUTPUT_ROOT = $IMAGE_OUTPUT_DIRECTORY .$TILE_ROOT ;
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
	exit;
	}

### NOW BUILDING STRIPS.....




@STRIP_STACK ;


	for($y=0;$y<=$MAX_Y_VALUE;$y+=$TILE_SIZE)
		{
$statement  = "convert  ";

for($x=0;$x<=$MAX_X_VALUE;$x+=$TILE_SIZE)
	{

		$current_jpg_file = sprintf "%s.ndpi-%010d-%010d.tif", $TILE_ROOT,$x,$y,$img_extension_type;
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

	$statement .= " +append $STRIP_OUTPUT_ROOT/${TILE_ROOT}_" . "strip$y.tif ";

	push(@STRIP_STACK,"${STRIP_OUTPUT_ROOT}/${TILE_ROOT}_strip$y.tif");
	print $statement . "\n";
`$statement`;
printf FP_APR "${TILE_ROOT}_strip$y.tif 0 $y \n";

	}


$statement = "convert ";
for($i=0;$i<$#STRIP_STACK;$i++)
	{
$statement .=  " $STRIP_STACK[$i] ";
	}
$statement .=  " -append ${STRIP_OUTPUT_ROOT}/${TILE_ROOT}_singlefile.tif";

print $statement;
`$statement`;
#if ( $file_to_parse =~ m/(.*)_strip(\d+)\.tif/ ) { print "Going to process $1 ..\n";		}
#else { print "unable to file an appropriate svs file... exiting.. .\n"; exit;}


### need toa dd logic to look for missing tiles
