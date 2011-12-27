#!/usr/bin/perl
use File::Basename;
$tile_dir_location = "/home/dgutman/NDPI_DEMO/";

$big_tif_output = "/IMAGING_SCRATCH/BIG_TIFF_IMAGES/";
$vips_pyramid_output = "/IMAGING_SCRATCH/PYRAMIDS/";



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

	printf FP_OUT "rename -v 's/ndpi-(\\d+)-(\\d+)/ndpi.\$1.\$2/'  ${dir_to_check}/*.tif \n "; 
	printf FP_OUT "/home/dgutman/Dropbox/GIT_ROOT/NDPI_CONVERSION/BuildSlide_dg ${dir_to_check}/ $big_tif_output$TILE_ROOT.tif -lzw \n";
	}




	}



	}

