#!/usr/bin/perl
use File::Basename;

$CLEANUP_TILES = 0;  ### If the pyramidal tiff alraedy exists, I may want to go ahead and delete the TILED and/or BIG TIFF Version of the image... probably for now not the
### big tiff versionas I am still playing around with different ways to transcode the images.....


### CONDOR VESION
$directory_to_transcode = "/var/www/CONDR/NDPI_IMAGES/";   ## Contains the raw NDPI IMAGES
$TILE_BASE_DIRECTORY = "/home/dgutman/TILE_CACHE/";  ### These contain the 4kx4k tiles that are split using NDPIUt9ilities
$big_tif_output = "/home/dgutman/BIG_TIFF_IMAGES/CONDR/";
$PYRAMID_FILE_LOCATION_BASE = "/var/www/CONDR/CONDR_PYRAMIDS/";


#### ADRC VERSION...
$directory_to_transcode = "/var/www/ADRC/TRAINING_SLIDES/";   ## Contains the raw NDPI IMAGES
$TILE_BASE_DIRECTORY = "/home/dgutman/TILE_CACHE/";  ### These contain the 4kx4k tiles that are split using NDPIUt9ilities
$big_tif_output = "/var/www/ADRC/BIG_TIFF_IMAGES/";
$PYRAMID_FILE_LOCATION_BASE = "/var/www/ADRC/ZOOMIFY_FULL_PYRAMIDS/TRAINING_SLIDES/";

@NDPI_FILES = `find $directory_to_transcode -name '*.ndpi'`;

$tile_resolution=40;
$tile_size=4096;

### I want to store timing info for how long each part take sfor optimizatino purposes and curiosity
if(!open(FP_STATS,">>tile_conversion_stats.txt"))
	{
	print "unable to open ndpiutilis input tile cache\n";
	exit;
	}


if(!open(FP_OUT,">tile_conversion_commands.bash"))
	{
	print "unable to open ndpiutilis input tile cache\n";
	exit;
	}



$ndpi_images_found = 0;
$already_tiled = 0;

foreach $ndpi_image ( @NDPI_FILES)
	{	
chomp($ndpi_image);
$input_file = $ndpi_image;
$output_file = $input_file;
($file,$dir) = fileparse($ndpi_image);

$ndpi_images_found++;

$file =~ s/\s+/_/;
$file =~ s/\&/-/;
$file =~ s/\.ndpi//;

### This should eventually be a database call.. for now I am going to look in the PYRAMID output directory and see 
### if the converted file exists...


### I am calling the "VIPS" image TILE_ROOT.dzi.tif  .... the "big" tiff is just .tif
$TILE_ROOT = $file;
$VIPS_IMAGE_NAME = $TILE_ROOT . ".dzi.tif";
$VIPS_IMAGE_NAME =  $PYRAMID_FILE_LOCATION_BASE . $VIPS_IMAGE_NAME;
$tile_output_directory = $TILE_BASE_DIRECTORY  .  $file;


if( ! -e $VIPS_IMAGE_NAME)
	{

	print "File $file has not been pyramidized... no image found in $VIPS_IMAGE_NAME\n";
	print "Will now see if BIG_TIFF image file  exists..\n"; 


	## order is  Tiles -->  Big Tiff -->  Pyramidal TIFF

	if( -e "$big_tif_output$TILE_ROOT.tif" ) {
	 print "$TILE_ROOT was already converted toa big tiff!! it's in $big_tif_output$TILE_ROOT\n";   
	printf FP_OUT "echo \"$TILE_ROOT already converted\" \n";
	$do_cleanup = 0;
	if($do_cleanup)  { 
		printf FP_OUT "rm -rf $tile_output_directory" ; 
			 }
	exit;
	}

	else
	{



	#in this case the image isn't tiled and I need to create it....		
	scan_dir_for_complete_tile_list( $tile_output_directory );
	$image_already_tiled =  check_for_tile_directory( $tile_output_directory) ;
		print "Will try and assemble image now.. .should also clean up the tiled directory!!!\n";


	
	}
    }
else
	{
## case where VIPS image is already created..
	print "VIPS IMAGE $VIPS_IMAGE already created.... \n";

	$do_cleanup = 0;
	if($do_cleanup)  {  printf FP_OUT "rm -rf $tile_output_directory"; print "Cleaned up output directory for tile..which is $tile_output_directory \n"; }


	}



if($image_already_tiled )	{ 	$already_tiled++;	}


	}

print "A total of $ndpi_images_found were located \n";
print "A total of them were already tiled.. $already_tiled \n";

#### I am now going to check and see if the image is already created

exit;

sub check_for_tile_directory( $tile_output_directory) 
	{
$tile_output_directory = $_[0];

@CHECK_FILE_COUNT = `find $tile_output_directory -name '*.tif' | wc `;
print STDERR  "File count was $CHECK_FILE_COUNT[0] for $tile_output_directory"; 
$line = $CHECK_FILE_COUNT[0];

$statement ="tile ${input_file} $tile_output_directory $tile_size $tile_resolution";

if( $line =~ m/0(\s+)0(\s+)0(\s+)/ )
	{
	if( ! -d $tile_output_directory) { ` mkdir -p $tile_output_directory `;}

	if(!open(FP_OUT,">current_tile_list.txt")) 	{	print "unable to open ndpiutilis input tile cache\n";	exit;	}

	print $statement . "\n";
	print STDERR "Blank file!! \n";
	printf FP_OUT $statement ."\n";
	close(FP_OUT);
printf FP_OUT "time wine NDPIUtilities.exe current_tile_list.txt ";

	return(1);
	}
else 
	{
	print STDERR "Already converted to tile directory\n"; 
	return(1);	
	}
	


	}




exit;






########




sub scan_dir_for_complete_tile_list( $input_dir )
	{
%X_HASH;
%Y_HASH;
$MAX_X_VALUE= 0;
$MAX_Y_VALUE = 0;

$FILE_IMAGE_TYPE = "ndpi" ; 

	$dir_to_check = $_[0];
	@TIFF_IMAGES = glob("${dir_to_check}/*.tif");

if( $#TIFF_IMAGES != -1 )
	{
	print "looking in $dir_to_check \n";
	printf "%d files were found\n", $#TIFF_IMAGES +1 ;

for($i=0;$i<=$#TIFF_IMAGES;$i++)
        {
$file_to_parse = $TIFF_IMAGES[$i];

($base_file, $base_dir) = fileparse($TIFF_IMAGES[$i]);

#print "base file and dir is $base_file $base_dir \n";


if ( $base_file =~ m/(.*)\.$FILE_IMAGE_TYPE-(\d+)-(\d+)/) { $TILE_ROOT = $1; }
elsif ( $base_file =~ m/(.*)\.$FILE_IMAGE_TYPE\.(\d+)\.(\d+)/) { $TILE_ROOT = $1; }


if(int($2) > $MAX_X_VALUE)  { $MAX_X_VALUE = int($2) };
if(int($3) > $MAX_Y_VALUE)  { $MAX_Y_VALUE = int($3) };
        }

print "MAX X AND Y are $MAX_X_VALUE and $MAX_Y_VALUE \n";

print "Total number of images should be..." . (($MAX_X_VALUE/4096) +1 ) * ( ($MAX_Y_VALUE/4096)+1) . "\n" ;


$image_stack_size = (($MAX_X_VALUE/4096) +1 ) * ( ($MAX_Y_VALUE/4096)+1)  ;

if($image_stack_size != ($#TIFF_IMAGES +1) )  { print "You aremissing some tiff images in $dir_to_check \n"; }
elsif( -e "$big_tif_output$TILE_ROOT.tif" ) { print "$dir_to_check was already converted toa big tiff!! \n"; 

	$VIPS_COMMAND  = "vips --vips-concurrency=2 --vips-progress im_vips2tiff $big_tif_output${TILE_ROOT}.tif $vips_pyramid_output${TILE_ROOT}.dzi.tif" . ":deflate,tile:256x256,pyramid";
	if (! -e "$vips_pyramid_output${TILE_ROOT}.dzi.tif") { print "Need to make tiff pyramid!!!!!\n";
			printf FP_OUT $VIPS_COMMAND . "\n";
#			printf FP_OOUT "`$VIPS_COMMAND`;
				 } 

		}
else
	{
	### because of the assumptions build slide takes about file names I need to change the dashes to dots... easy command in linux
	$rename_command =   "rename -v 's/ndpi-(\\d+)-(\\d+)/ndpi.\$1.\$2/'  ${dir_to_check}/*.tif ";
#	`$rename_command`; 
	printf FP_OUT $rename_command . "\n";
	if(! -d $big_tif_output) { `mkdir -p $big_tif_output`;}
	print "Converting big tiff now... \n";
	$convert_to_big_tiff_command =  "time /home/dgutman/Dropbox/GIT_ROOT/NDPI_CONVERSION/BuildSlide_dg ${dir_to_check}/ $big_tif_output$TILE_ROOT.tif -lzw ";
	print "$convert_to_big_tiff_command\n";
#	@conversion_time  = `$convert_to_big_tiff_command`;		
	printf FP_OUT $convert_to_big_tiff_command . "\n";		
#	$delete_command = "rm -rf ${dir_to_check}/";
#	`$delete_command`;	

	}

	}




	}


$DEFAULT_TILE_SIZE = 4096; ## need to make this a parmater below.. or even figure it out automatically?

### there are multiple steps-- first step is creating a SINGLE huge tiff file... second part is making a TIFF PYRAMID from that.. these parts can be decoupled



$DELETE_TILE_DIRECTORY = 0 ;  ## I may or may not want to keep the tiled images available for later work... since I am running out of disk space I will probably nule them


$NDPI_FILE_LOCATION = "/var/www/ADRC/TRAINING_SLIDES/";
$tile_dir_location = "/home/dgutman/TILE_CACHE/";
$big_tif_output = "/var/www/ADRC/CONDR_BIG_TIFF_IMAGES/";
$vips_pyramid_output = "/var/www/CONDR/CONDR_PYRAMIDS/";



### this is the appropriate set up for the ADRC images...

$NDPI_FILE_LOCATION = "/var/www/ADRC/TRAINING_SLIDES/";
$tile_dir_location = "/home/dgutman/TILE_CACHE/";
$big_tif_output = "/var/www/ADRC/BIG_TIFF_IMAGES/";
$vips_pyramid_output = "/var/www/CDSA/TCGA_ZOOMIFY_FULL_PYRAMIDS/TRAINING_SLIDES/TRAINING_BATCH1/";


## I am debating this... I may want to make this just go to STDOUT and run a bash script...
if(!open(FP_OUT,">make_me_some_images.bash") )
	{
	print "Unable to open output bash file \n";
	}

@DIRECTORY_LIST = `find $tile_dir_location -type d`;


foreach $tile_directory ( @DIRECTORY_LIST)
	{

## first find directories and make sure they were tiled properly..
	print $tile_directory;
	chomp($tile_directory);
#	scan_dir_for_complete_tile_list($tile_directory);
	}


sub scan_dir_for_complete_tile_list( $input_dir )
	{
%X_HASH;
%Y_HASH;
$MAX_X_VALUE= 0;
$MAX_Y_VALUE = 0;

$FILE_IMAGE_TYPE = "ndpi" ; 

	$dir_to_check = $_[0];

	@TIFF_IMAGES = glob("${dir_to_check}/*.tif");

if( $#TIFF_IMAGES != -1 )
	{
	print "looking in $dir_to_check \n";
	printf "%d files were found\n", $#TIFF_IMAGES +1 ;


for($i=0;$i<=$#TIFF_IMAGES;$i++)
        {
$file_to_parse = $TIFF_IMAGES[$i];

($base_file, $base_dir) = fileparse($TIFF_IMAGES[$i]);
#print "base file and dir is $base_file $base_dir \n";

if ( $base_file =~ m/(.*)\.$FILE_IMAGE_TYPE-(\d+)-(\d+)/) { $TILE_ROOT = $1; }
elsif ( $base_file =~ m/(.*)\.$FILE_IMAGE_TYPE\.(\d+)\.(\d+)/) { $TILE_ROOT = $1; }


if(int($2) > $MAX_X_VALUE)  { $MAX_X_VALUE = int($2) };
if(int($3) > $MAX_Y_VALUE)  { $MAX_Y_VALUE = int($3) };
        }

print "MAX X AND Y are $MAX_X_VALUE and $MAX_Y_VALUE \n";
print "Total number of images should be..." . (($MAX_X_VALUE/4096) +1 ) * ( ($MAX_Y_VALUE/4096)+1) . "\n" ;


$image_stack_size = (($MAX_X_VALUE/4096) +1 ) * ( ($MAX_Y_VALUE/4096)+1)  ;

if($image_stack_size != ($#TIFF_IMAGES +1) )  { print "You aremissing some tiff images in $dir_to_check \n"; }
elsif( -e "$big_tif_output$TILE_ROOT.tif" ) { print "$dir_to_check was already converted toa big tiff!! \n"; 

	$VIPS_COMMAND  = "vips --vips-concurrency=2 --vips-progress im_vips2tiff $big_tif_output${TILE_ROOT}.tif $vips_pyramid_output${TILE_ROOT}.dzi.tif" . ":lzw,tile:256x256,pyramid,,,,8";
	if (! -e "$vips_pyramid_output${TILE_ROOT}.dzi.tif") { print "Need to make tiff pyramid!!!!!\n";
			printf FP_OUT $VIPS_COMMAND . "\n";
				 } 


		}
else
	{

	printf FP_OUT "rename -v 's/ndpi-(\\d+)-(\\d+)/ndpi.\$1.\$2/'  ${dir_to_check}/*.tif \n "; 
	printf FP_OUT "/home/dgutman/Dropbox/GIT_ROOT/NDPI_CONVERSION/BuildSlide_dg ${dir_to_check}/ $big_tif_output$TILE_ROOT.tif -lzw \n";
	}




	}



	}

