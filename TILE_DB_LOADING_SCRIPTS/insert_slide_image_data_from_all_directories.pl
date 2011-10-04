#!/usr/bin/perl
use DBI;
use DBD::mysql;
use File::Basename;

require('/includes/connect_to_sideshowbob_sql.pl'); 


&connect_to_mysql_v2();
DBI->trace(0);


### there's also an exclusion list of directories where I just don't want to include it

my %SLIDE_NAME_HASH ;  ### this will store all the file names I have found and keep track of duplicates...
### Going to scan for all NDPI or SVS files located on my system...
### Will debate most efficient way to do this.. may likely do this in stages
### first assume the filename of an image is ALWAYS unique.. and build a hash
### of current SLIDE_NAMES I have stored...
### I want to track when things move however... so I think I'll build a hash of
### all files and their directories as a hash... then if it's not there.. add it to the database

read_slide_metadata_info( "/data2/Images/bcrTCGA/diagnostic_block_HE_section_image/intgen.org_GBM.tissue_images.8.0.0/TCGA-06-0145-01Z-00-DX3.svs");



exit;

locate_svs_files( "/data2/Images/bcrTCGA*/", "svs" );
locate_svs_files( "/data2/Images/*/", "ndpi" );
	

	
update_slide_parameters();


sub update_slide_parameters()
{

### this will query the database and determine what slides do not have resolution/voxel size/whaetver data

$select_all_data = 0;

if($select_all_data) { $select_statement = "select * from  svs_slide_location_info"; }
else { $select_statement = "select * from svs_slide_location_info where scanned_resolution != NULL";   }

}
	
	

sub locate_svs_files( $BASE_PATH_TO_SCAN, $FILE_EXTENSION_TO_LOOK_FOR )
	{
	
	$BASE_PATH_TO_SCAN = $_[0];
	$FILE_EXTENSION_TO_LOOK_FOR = $_[1];
	$find_statement = "find $BASE_PATH_TO_SCAN -maxdepth 3 -name '*.$FILE_EXTENSION_TO_LOOK_FOR' ";
	print $find_statement ."\n";
	@CURRENT_FILE_LIST = `$find_statement`;
	
	print "There were a total of $#CURRENT_FILE_LIST files found ... \n";
	foreach $WHOLE_SLIDE_FILE ( @CURRENT_FILE_LIST )
		{
		chomp($WHOLE_SLIDE_FILE);
		($file,$dir) = fileparse($WHOLE_SLIDE_FILE);
		### Just reading in the list of files and slides...
		#print "$file was in $dir \n";
		if($SLIDE_NAME_HASH{$file}) {
								#print "Found a duplicate for $file in $dir\n";
								} 
		else{
			update_or_insert_slide_info($file,$dir,$FILE_EXTENSION_TO_LOOK_FOR);
			}
		$SLIDE_NAME_HASH{$file}++;
		}
	
	}

exit;

sub read_slide_metadata_info( $slide_location)
	{
	
	$input_slide = $_[0];
	
$base_command = "/drobo/LOCI_TOOLS/loci/showinf -nopix -omexml $input_slide ";


print $base_command . "\n";

#@OME_TIFF_OUTPUT = `$base_command`;
@OME_TIFF_OUTPUT = `cat /home/dgutman/Dropbox/GIT_ROOT/TILE_DB_LOADING_SCRIPTS/doc_to_parse.txt`;

for($i=0;$i<=$#OME_TIFF_OUTPUT;$i++)
		{
		
			if( $OME_TIFF_OUTPUT[$i] =~ m/<Image ID=\"Image:0\" Name=\"Series 1\">/ )
					{
#		print $OME_TIFF_OUTPUT[$i]  ;
		if( $OME_TIFF_OUTPUT[$i+3]  =~ m/<Pixels DimensionOrder=\"(.*)\" ID=\"(.*)\" PhysicalSizeX=\"(.*)\" PhysicalSizeY=\"(.*)\" PhysicalSizeZ=\"(.*)\" SizeC=\"(.*)\" SizeT=\"(.*)\" SizeX=\"(.*)\" SizeY=\"(.*)\" SizeZ=\"(.*)\" Type/)
			{
#			print "Found pixel dimensions match... \n";
			}
		else
			{
#			print "regex failed... \n";
			}
		$base_image_width = $8;
		$base_image_height = $9;
				
					}
		
			if( $OME_TIFF_OUTPUT[$i] =~ m/<Key>Series 1 AppMag<\/Key>/ )
				{
			print "Foudn base magnification \n";
				$OME_TIFF_OUTPUT[$i+1] =~ m/<Value>(.*)<\/Value>/;
					$base_magnification = $1;
						print "Base magnification is $base_magnification";
				}
		
		
		}



		print "Image is $base_image_width by $base_image_height and was sacnned at $base_magnification\n";


		
	}

sub		update_or_insert_slide_info($file,$dir)
	{
	#This function will do the database inserts/replace for the raw file location.... I am going to try and only have
	# one entry for a given file.... need to debate how to deal with this

	
$file = $_[0];
$dir = $_[1];	

$input_file_escaped = $realdbh->quote($file);
$input_dir_escaped = $realdbh->quote($dir);


$statement = "replace into svs_slide_location_info (source_file_name,root_directory,slide_format) values  " ;
$statement .= "($input_file_escaped,$input_dir_escaped,'$_[2]') ";
#,'$_[2]','$_[3]') ";
#print "$statement  was the statement\n";
$insert_db = $realdbh->prepare($statement);
$insert_db->execute(); 

#@GET_SLIDE_INFO `
#showinf -nopix -omexml-only sourceImageFile > omexml-metadata.xml

if($DBI::errstr or $realdbh::errstr ) {    print "foudn an error $DBI::errstr or $realdbh::errstr \n"; }

		}


$statement = "truncate svs_slide_location_info ";

print "$statement\n";
$insert_db = $realdbh->prepare($statement);
$insert_db->execute();


### THIS WILL READ ALL THE TILES IN A GIVEN DIRECTORY THAT MATCH MY PATTERN INTO AN ARRAY
sub determine_image_directory_information($FILE_PATTERN_ROOT)
	{

$FILE_PATTERN_ROOT = $_[0];

print "file pattern root is $FILE_PATTERN_ROOT \n";

$SEARCH_PATTERN = $FILE_PATTERN_ROOT . "/" . "*.png";
print " The search pattern was $SEARCH_PATTERN\n";

@IMAGE_TILES = glob($SEARCH_PATTERN);


print $#IMAGE_TILES  . " tiles are in this directory... for file pattern $FILE_PATTERN_ROOT\n";


## MAKE SURE ALL THE TILES ARE THE SAME SIZE.. if not there's probably something wrong....
## USING THE FIRST IMAGE AND COMAPRING FROM THERE...

$IMAGE_TILE_SIZE =`identify -format "%wx%h" $IMAGE_TILES[0]`;
chomp($IMAGE_TILE_SIZE);


$DEBUG = 0;


	for($i=0;$i<=$#IMAGE_TILES;$i++)
	{
	#print $IMAGE_TILES[$i] . "\n";



if($DEBUG) {
	$image_size = `identify -format "%wx%h" $IMAGE_TILES[$i]`;
	chomp($image_size);


if($image_size != $IMAGE_TILE_SIZE )  
	{  print "I am exiting.. the tile sizes are not consistent across images... uh oh! \n";
	print "$image_size and $IMAGE_TILE_SIZE for $FILE_PATTERN_ROOT \n";

		}

	} ## END DEBUG BRACKET
	
	}

### WHEN I DO THE INSERT I NEED TO DETERMINE IF THERE's A MAT file associated with this..

print "Image tile size is $IMAGE_TILE_SIZE ... \n";
@TILE_PARAMS = split(/x/,$IMAGE_TILE_SIZE);

$SLICE_WIDTH  =  $TILE_PARAMS[0];
$SLICE_HEIGHT = $TILE_PARAMS[1];
$NUM_SLICES = $#IMAGE_TILES;


### NOW GENERATING THE THUMBNAIL IMAGE
$outputdir = $FILE_PATTERN_ROOT . "/THUMB_NAIL/";
if(! -d $outputdir) { `mkdir $outputdir`; }


$copy = $SOURCE_FILE_NAME;
@COLS = split(/\//,$copy);
$SVS_FILE_NAME = $COLS[1];

@TIFF_INFO_ON_SVS = `tiffinfo $SOURCE_FILE_NAME -0`;

print "Current SVS file name is $SOURCE_FILE_NAME \n";

$found_length = 0;

for($x=0;$x<=$#TIFF_INFO_ON_SVS && ! $found_length;$x++)
	{
print "Current x value is $x ... \n";
if( $TIFF_INFO_ON_SVS[$x] =~ m/Image Width:\s+(\d+) Image Length: (\d+)/ )
		{
		print "Image width and length is $1 and $2\n";
		$found_length=1;
		$SVS_TILE_WIDTH = $1;
		$SVS_TILE_LENGTH = $2;	
		}

	}
print "Down here now ... \n";

$PPM_LARGE_THUMBNAIL_NAME = "$FILE_PATTERN_ROOT" . "/THUMB_NAIL/thumbnail-$SVS_FILE_NAME";
$LARGE_THUMBNAIL_NAME = "$FILE_PATTERN_ROOT" . "/THUMB_NAIL/thumbnail-$SVS_FILE_NAME.ppm.jpg";
$TINY_THUMBNAIL_NAME = "$FILE_PATTERN_ROOT" . "/THUMB_NAIL/thumbnail-$SVS_FILE_NAME-tiny.jpg";


### PROBABLY ONLY NEED TO RUN THIS IF THUMBNAILS ARE NOT THERE

$RECREATE_THUMBNAILS = 0;

if( ( ! -e $LARGE_THUMBNAIL_NAME )    )
	{

$statement ="/APERIO_SHARE/DAG_SCRIPTS/extractLayer $SOURCE_FILE_NAME  $PPM_LARGE_THUMBNAIL_NAME   1 \n";
print $statement . "\n";
`$statement`;

$statement = "convert $PPM_LARGE_THUMBNAIL_NAME.ppm $LARGE_THUMBNAIL_NAME";
print "$statement \n";
`$statement `;

`rm $PPM_LARGE_THUMBNAIL_NAME.ppm  `;
$statement  = "convert  $LARGE_THUMBNAIL_NAME  -thumbnail 200 $TINY_THUMBNAIL_NAME";
print $statement . " \n";
`$statement`;

	}


print "This image series contains $NUM_SLICES tiles and is $SLICE_WIDTH by $SLICE_HEIGHT per tile .. the source file name is $SOURCE_FILE_NAME \n";
print "Thumbnail image large is $LARGE_THUMBNAIL_NAME \n";

$statement = "select series_id_key from SERIES_DESCRIPTION where SERIES_TAG='$SERIES_TAG'";
print "$statement\n";
$select_db = $realdbh->prepare($statement);
$select_db->execute();

($series_id_key) = $select_db->fetchrow_array();
if($series_id_key eq "" )
{
$statement = "insert into SERIES_DESCRIPTION (series_tag,ROOT_DIRECTORY,slice_width,slice_height,num_slices,source_file_name,thumbnail_image_name,large_thumbnail_image_name,orig_image_width,orig_image_height ) values  " ;
$statement .= " ('$FILE_PATTERN_ROOT_NAME','IMAGE_STORE/$FILE_PATTERN_ROOT_NAME','$SLICE_WIDTH','$SLICE_HEIGHT','$NUM_SLICES','$SOURCE_FILE_NAME','$TINY_THUMBNAIL_NAME','$LARGE_THUMBNAIL_NAME','$SVS_TILE_WIDTH','$SVS_TILE_LENGTH') ";
print "$statement \n";
$insert_db = $realdbh->prepare($statement);
$insert_db->execute();
}


$statement = "select series_id_key from SERIES_DESCRIPTION where series_tag='$FILE_PATTERN_ROOT_NAME' ";
print "$statement\n";
$select_db = $realdbh->prepare($statement);
$select_db->execute();

($current_series_id_key ) = $select_db->fetchrow_array();
print "The current series id is $current_series_id_key \n";



##
##
## NOW ITERATING THROUGH THE INDIVIDUAL FILES TO INSERT THEM INTO THE DB

$statement = "delete from INDIV_SERIES_FILE_NAMES where series_id_key='$current_series_id_key' ";

print "$statement\n";
$insert_db = $realdbh->prepare($statement);
$insert_db->execute();

$WORKING_PATH = `pwd`;
print "Working path is $WORKING_PATH \n";

for($i=0;$i<$#IMAGE_TILES;$i++)
	{

$copy = $IMAGE_TILES[$i];
$copy =~ m/(.*)svs-(\d+)-(\d+)(.*)/;
#print $1 . ";" . $2 . " $3  was what was parsed\n";
$TILE_X_START = $2;
$TILE_Y_START = $3;

$MAT_FILE = $IMAGE_TILES[$i];

## NEED TO LOOK FOR A FILE WITH EXTENSION .ppm.grid6.mat
## BNASED ON THE WAY I'VE DONE THIS I NEE TO REPLACE THE PNG extension with grid6.mat
$MAT_FILE =~ s/png/grid6\.mat/;

#print "Looking for $MAT_FILE in this dierctory ... \n";


if(-e $MAT_FILE) { $HAS_A_MAT_FILE = 1; 
#	print "Found a mat file for $IMAGE_TILES[$i]\n";
 } else { $HAS_A_MAT_FILE = 0; }




$statement = "insert delayed into INDIV_SERIES_FILE_NAMES  (SERIES_ID_KEY,FULL_FILE_NAME,FILE_ORDER,HAS_MAT_DATA,TILE_X_START,TILE_Y_START) values  " ;
$statement .= " ('$current_series_id_key','$IMAGE_TILES[$i]',$i,'$HAS_A_MAT_FILE','$TILE_X_START','$TILE_Y_START') ";
#print $statement . "\n";
$insert_db = $realdbh->prepare($statement);
$insert_db->execute();
	}
print "Inserted $i images ... \n";


	}




#print "Genertaing thumbnail image for $SVS_FILES_TO_PARSE  \n";
#$statement ="/APERIO_SHARE/DAG_SCRIPTS/extractLayer $SVS_FILE_TO_PARSE   /APERIO_SHARE/TCGA_SLIDES/THUMBNAIL_DEPOT/$THUMBNAIL_NAME-thumbnail 1 \n";

#`$statement`;
#`convert /APERIO_SHARE/TCGA_SLIDES/THUMBNAIL_DEPOT/$THUMBNAIL_NAME-thumbnail.ppm /APERIO_SHARE/TCGA_SLIDES/THUMBNAIL_DEPOT/$THUMBNAIL_NAME.jpg`;
#`rm /APERIO_SHARE/TCGA_SLIDES/THUMBNAIL_DEPOT/$THUMBNAIL_NAME-thumbnail.ppm`;

#`convert  /APERIO_SHARE/TCGA_SLIDES/THUMBNAIL_DEPOT/$THUMBNAIL_NAME.jpg -thumbnail 200 /APERIO_SHARE/TCGA_SLIDES/THUMBNAIL_DEPOT/$THUMBNAIL_NAME-tiny.jpg`;


exit;

