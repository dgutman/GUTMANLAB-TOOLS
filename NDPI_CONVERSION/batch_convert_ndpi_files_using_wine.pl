#!/usr/bin/perl
use File::Basename;

$directory_to_transcode = "/var/www/ADRC/TRAINING_SLIDES/";   ## Contains the raw NDPI IMAGES

#$TILE_BASE_DIRECTORY = "/var/www/ADRC/TILE_CACHE/";
$TILE_BASE_DIRECTORY = "/SSD/TILE_CACHE/";  ### These contain the 4kx4k tiles that are split using NDPIUt9ilities

#$big_tif_output = "/SATA_1_5_GB_D2/BIG_TIFF_IMAGES/TRAINING_SLIDES/";
$big_tif_output = "/home/dgutman/BIG_TIFF_IMAGES/TRAINING_SLIDES/";

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

#if (! -e "$$PYRAMID_FILE_LOCATION_BASE${TILE_ROOT}.dzi.tif") { print "Need to make tiff pyramid!!!!!\n";  }

### I am calling the "VIPS" image TILE_ROOT.dzi.tif  .... the "big" tiff is just .tif
$TILE_ROOT = $file;
$VIPS_IMAGE_NAME = $TILE_ROOT . ".dzi.tif";
$VIPS_IMAGE_NAME =  $PYRAMID_FILE_LOCATION_BASE . $VIPS_IMAGE_NAME;

if( ! -e $VIPS_IMAGE_NAME)
	{
	print "File $file has not been pyramidized... no image found in $VIPS_IMAGE_NAME\n";
	print "Will now see if BIG_TIFF image file  exists..\n"; 
	## order is  Tiles -->  Big Tiff -->  Pyramidal TIFF

	if( -e "$big_tif_output$TILE_ROOT.tif" ) { print "$TILE_ROOT was already converted toa big tiff!! it's in $big_tif_output$TILE_ROOT\n";  }


	$do_cleanup = 1;
	if($do_cleanup)  {  `rm -rf $tile_output_directory` ; print "Cleaned up output directory for tile..which is $tile_output_directory \n"; }
	exit;

	scan_dir_for_complete_tile_list( $tile_output_directory );

	$tile_output_directory = $TILE_BASE_DIRECTORY  .  $file;
	$image_already_tiled =  check_for_tile_directory( $tile_output_directory) ;

	exit;

	if( $image_already_tiled)
		{
		print "Will try and assemble image now.. .should also clean up the tiled directory!!!\n";
		scan_dir_for_complete_tile_list( $tile_output_directory );
		}
    }
else
	{
## case where VIPS image is already created..

	}



if($image_already_tiled )	{ 	$already_tiled++;	}


	}

print "A total of $ndpi_images_found were located \n";
print "A total of them were already tiled.. $already_tiled \n";

#### I am now going to check and see if the image is already created

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
	@wine_command_output = `time wine NDPIUtilities.exe current_tile_list.txt`;
	print @wine_command_output . "\n";
	print "Image conversion completed for $statement \n";
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



@DIRECTORY_LIST = `find $tile_dir_location -type d`;

if(!open(FP_OUT,">make_me_some_images.bash") )
	{
	print "Unable to open output bash file \n";
	}

foreach $tile_directory ( @DIRECTORY_LIST)
	{
#	print $tile_directory;
	chomp($tile_directory);
	scan_dir_for_complete_tile_list($tile_directory);
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

	$VIPS_COMMAND  = "vips --vips-concurrency=2 --vips-progress im_vips2tiff $big_tif_output${TILE_ROOT}.tif $vips_pyramid_output${TILE_ROOT}.dzi.tif" . ":deflate,tile:256x256,pyramid";
	if (! -e "$vips_pyramid_output${TILE_ROOT}.dzi.tif") { print "Need to make tiff pyramid!!!!!\n";
			printf FP_OUT $VIPS_COMMAND . "\n";
				 } 

		}
else
	{
	### because of the assumptions build slide takes about file names I need to change the dashes to dots... easy command in linux
	$rename_command =   "rename -v 's/ndpi-(\\d+)-(\\d+)/ndpi.\$1.\$2/'  ${dir_to_check}/*.tif ";
	`$rename_command`; 
	if(! -d $big_tif_output) { `mkdir -p $big_tif_output`;}
	print "Converting big tiff now... \n";
	$convert_to_big_tiff_command =  "time /home/dgutman/Dropbox/GIT_ROOT/NDPI_CONVERSION/BuildSlide_dg ${dir_to_check}/ $big_tif_output$TILE_ROOT.tif -lzw ";
	print "$convert_to_big_tiff_command\n";
	@conversion_time  = `$convert_to_big_tiff_command`;		
	$delete_command = "rm -rf ${dir_to_check}/";
	`$delete_command`;	

	}

	}




	}

