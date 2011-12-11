#!/usr/bin/perl
use DBI;
use DBD::mysql;
use File::Basename;

require('/includes/connect_to_cerebro_sql.pl'); 

&connect_to_mysql_v2();
DBI->trace(0);



### USE BELOW WITH CAUTION-- TRUNCATES INPUT TABLE!!
#wipe_slide_database();

### there's also an exclusion list of directories where I just don't want to include it
my %SLIDE_NAME_HASH ; 


### this will store all the file names I have found and keep track of duplicates...
### Going to scan for all NDPI or SVS files located on my system...
### Will debate most efficient way to do this.. may likely do this in stages
### first assume the filename of an image is ALWAYS unique.. and build a hash
### of current SLIDE_NAMES I have stored...
### I want to track when things move however... so I think I'll build a hash of
### all files and their directories as a hash... then if it's not there.. add it to the database

#locate_wholeslide_files( "/data2/Images/*/", "svs" );
#locate_wholeslide_files( "/data2/Images/*/", "ndpi" );
#locate_wholeslide_files("/data2/TCGA_MIRROR/tcga-data.nci.nih.gov/tcgafiles/ftp_auth/distro_ftpusers/anonymous/tumor/","svs");






#locate_pyramid_files( "/data/dgutman/PYRAMIDS/" , "dzi.tif" );

#locate_pyramid_files( "/IMAGING_SCRATCH/ADRC/PYRAMIDS/" , "dzi.tif" );




#check_for_or_generate_thumbnail(  "/IMAGING_SCRATCH/THUMBNAIL_DEPOT/" );


#update_slide_parameters();


 update_datagroup_info();

exit;

sub check_for_or_generate_thumbnail( $base_directory_path_to_scan_for_thumbs)
	{
## this will receive the WEBROOT_LOCATION and then look within that hierachy for a thumbnail image....
### for now since I haven't organized everything I will use the find command with the -tiny.jpg extension in several
### root locations

$base_search_path = $_[0];

@thumbnail_depot_list = `find $base_search_path -name '*-thumbnail.png'`;

my %THUMBNAIL_LOCATION_HASH;


foreach $potential_thumb_name ( @thumbnail_depot_list )
	{
	chomp($potential_thumb_name);
	($file,$dir) = fileparse($potential_thumb_name);
	$THUMBNAIL_LOCATION_HASH{$file} = $potential_thumb_name;
	print "$file , $dir \n";
	}


$select_all_data = 0;
if($select_all_data) { $select_statement = "select SOURCE_FILE_NAME,ROOT_DIRECTORY,source_file_name_base from  svs_slide_location_info "; }
else { $select_statement = "select SOURCE_FILE_NAME, ROOT_DIRECTORY,source_file_name_base from svs_slide_location_info where webroot_image_small IS NULL ";   }

print $select_statement ."\n";
$select_db = $realdbh->prepare($select_statement);
$select_db->execute(); 

while( @SLIDE_INFORMATION = $select_db->fetchrow_array() )
	{
	print $SLIDE_INFORMATION[0] . ";" . $SLIDE_INFORMATION[1] .  ";". $SLIDE_INFORMATION[2] . "\n";
	$slide_path = $SLIDE_INFORMATION[1] . $SLIDE_INFORMATION[0];	
#	read_slide_metadata_info( $slide_path,$SLIDE_INFORMATION[0]);
	$predicted_thumbnail_name = $SLIDE_INFORMATION[2] . "-thumbnail.png";
## I should be generating thumbnails in a consistent pattern based on taking the "fixed" base slide name
# where I remove any spaces or special characters and then use either a windows based tiler that lee wrote
# or the aperio tiffsplit program to find the appropriately sized layer and extract that from the tiff

#	print "looking for $predicted_thumbnail_name\n";
	if( $THUMBNAIL_LOCATION_HASH{$predicted_thumbnail_name} ) { 
		

#	print "Found $predicted_thumbnail_name in" . $THUMBNAIL_LOCATION_HASH{$predicted_thumbnail_name}; 
	
				$slide_location_with_base_path_removed = $THUMBNAIL_LOCATION_HASH{$predicted_thumbnail_name};
				$slide_location_with_base_path_removed =~ s/$base_search_path//;
	$webroot_image_large = $slide_location_with_base_path_removed;
	$webroot_image_small = $webroot_image_large;
	$webroot_image_small =~ s/-thumbnail.png$/-thumbnail-tiny.png/;
				$statement = "update svs_slide_location_info set webroot_image_large='$webroot_image_large',webroot_image_small='$webroot_image_small', webroot_filesystem_base='$base_search_path' ";
				$statement .= "where source_file_name='${SLIDE_INFORMATION[0]}'";
	#			print $statement . "\n";

				$insert_db = $realdbh->prepare($statement);
				$insert_db->execute(); 
			if($DBI::errstr or $realdbh::errstr ) {    print "found an error $DBI::errstr or $realdbh::errstr \n"; }


					
					}
	else	
		{

		print "Did not find thumbnail image for ${SLIDE_INFORMATION[0]} \n";

		}

	}


	}


sub update_datagroup_info()
{
$select_all_data = 1;

if($select_all_data) { $select_statement = "select root_directory, source_file_name ,svs_slide_id from  svs_slide_location_info  where primary_datagroup IS NULL "; }
#else { $select_statement = "select SOURCE_FILE_NAME, ROOT_DIRECTORY from svs_slide_location_info where scanned_resolution IS NULL and slide_format='ndpi' limit 500";   }


#### this only works for this type of file/data2/TCGA_MIRROR/tcga-data.nci.nih.gov/tcgafiles/ftp_auth/distro_ftpusers/anonymous/tumor/

print $select_statement ."\n";

$select_db = $realdbh->prepare($select_statement);
$select_db->execute(); 

while( @SLIDE_INFORMATION = $select_db->fetchrow_array() )
	{
#	print $SLIDE_INFORMATION[0] . ";" . $SLIDE_INFORMATION[1] . "\n";
	$slide_path = $SLIDE_INFORMATION[1] . $SLIDE_INFORMATION[0];	
	
	$data_group = "";
	$image_type = "";

	if($SLIDE_INFORMATION[0] =~ m/ftp_auth\/distro_ftpusers\/anonymous\/tumor\/(.*)\/bcr/)
		{
		$data_group = "$1";		
#		print "data group was $1 \n";
		}


	if($SLIDE_INFORMATION[0] =~ m/ftp_auth\/distro_ftpusers\/anonymous\/tumor\/(.*)\/diagnostic_images/)
		{
		$image_type = "diagnostic_images";		
#		print "image type was $image_type";
		}		
	elsif($SLIDE_INFORMATION[0] =~ m/ftp_auth\/distro_ftpusers\/anonymous\/tumor\/(.*)\/tissue_images/)
		{
		$image_type = "frozen_section";		
#		print "image type was $image_type";
		}	
	

if( $SLIDE_INFORMATION[1] =~ m/ndpi/ || $SLIDE_INFORMATION[0] =~ m/$data\/Images\//) {  next;} 


if( $SLIDE_INFORMATION[1] =~ m/TCGA-(..)-(....)/ ) 
	{
$patient_id = "TCGA-$1-$2";
	}

if( ( $image_type eq "" || $data_group eq "" )) 
		{
		print "Need info for $slide_path \n";
		}
else
	{
	
$update_statement = "update svs_slide_location_info set primary_datagroup='$data_group', patient_id='$patient_id', stain_type='HE-${image_type}' where svs_slide_id=$SLIDE_INFORMATION[2]"; 
#else { $select_statement = "select SOURCE_FILE_NAME, ROOT_DIRECTORY from svs_slide_location_info where scanned_resolution IS NULL and slide_format='ndpi' limit 500";   }


#### this only works for this type of file/data2/TCGA_MIRROR/tcga-data.nci.nih.gov/tcgafiles/ftp_auth/distro_ftpusers/anonymous/tumor/

print $update_statement ."\n";
#exit;
$update_db = $realdbh->prepare($update_statement);
$update_db->execute(); 



	}

	


	}



}




sub update_slide_parameters()
{
### this will query the database and determine what slides do not have resolution/voxel size/whaetver data

$select_all_data = 0;

if($select_all_data) { $select_statement = "select SOURCE_FILE_NAME,ROOT_DIRECTORY from  svs_slide_location_info  where slide_format='ndpi' "; }
else { $select_statement = "select SOURCE_FILE_NAME, ROOT_DIRECTORY from svs_slide_location_info where scanned_resolution IS NULL and slide_format='ndpi' limit 500";   }

print $select_statement ."\n";

$select_db = $realdbh->prepare($select_statement);
$select_db->execute(); 

while( @SLIDE_INFORMATION = $select_db->fetchrow_array() )
	{
	print $SLIDE_INFORMATION[0] . ";" . $SLIDE_INFORMATION[1] . "\n";
	$slide_path = $SLIDE_INFORMATION[1] . $SLIDE_INFORMATION[0];	
	read_slide_metadata_info( $slide_path,$SLIDE_INFORMATION[0]);
	}







}


sub locate_wholeslide_files( $BASE_PATH_TO_SCAN, $FILE_EXTENSION_TO_LOOK_FOR )
	{
	
	$BASE_PATH_TO_SCAN = $_[0];
	$FILE_EXTENSION_TO_LOOK_FOR = $_[1];
	$find_statement = "find $BASE_PATH_TO_SCAN  -name '*.$FILE_EXTENSION_TO_LOOK_FOR' ";
#	$find_statement = "find $BASE_PATH_TO_SCAN -maxdepth 3 -name '*.$FILE_EXTENSION_TO_LOOK_FOR' ";
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















sub locate_pyramid_files( $BASE_PATH_TO_SCAN, $FILE_EXTENSION_TO_LOOK_FOR )
	{
	
	$BASE_PATH_TO_SCAN = $_[0];
	$FILE_EXTENSION_TO_LOOK_FOR = $_[1];
	$find_statement = "find $BASE_PATH_TO_SCAN  -name '*.$FILE_EXTENSION_TO_LOOK_FOR' ";
	print $find_statement ."\n";
	@CURRENT_FILE_LIST = `$find_statement`;
	
	print "There were a total of $#CURRENT_FILE_LIST files found ... \n";
	foreach $DZI_PYRAMID_FILE ( @CURRENT_FILE_LIST )
		{
		chomp($DZI_PYRAMID_FILE);
		($file,$dir) = fileparse($DZI_PYRAMID_FILE);
		### Just reading in the list of files and slides...
		print $DZI_PYRAMID_FILE . "\n";
		$input_dir_escaped = $realdbh->quote($DZI_PYRAMID_FILE);
	 $filesize = -s "$dir$file";

		$slide_name = $file;
		$slide_name =~ s/\.dzi\.tif//;
		$slide_name = $realdbh->quote($slide_name);
		$file = $realdbh->quote($file);


	$statement = "replace into tiff_pyramid_information (slide_name,base_file_path,extended_file_path,tiff_pyramid_file_name,conversion_scheme) values  " ;
	$statement .= "($slide_name,$input_dir_escaped,$file,$filesize,'vips_jpeg75_256x256') ";
#	print $statement;#
#	exit;
	$insert_db = $realdbh->prepare($statement);
	$insert_db->execute


	
		}
	
	}














sub read_slide_metadata_info( $slide_location, $slide_name)
	{
	
	$input_slide_with_path = $_[0];
	$slide_name = $realdbh->quote($_[1]);
	
#$base_command = "/drobo/LOCI_TOOLS/loci/showinf -nopix -omexml '$input_slide_with_path' ";
$base_command = "/drobo/LOCI_TOOLS/loci/showinf -nopix '$input_slide_with_path' ";


print $base_command . "\n";
@OME_TIFF_OUTPUT = `$base_command`;


for($i=0;$i<=$#OME_TIFF_OUTPUT;$i++)
		{
		
			if( $OME_TIFF_OUTPUT[$i] =~ m/<Image ID=\"Image:0\" Name=\"Series 1\">/ )
					{
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
		## the above code only really works if I populate the omexml model.. for NDPI will try a different method
		if($OME_TIFF_OUTPUT[$i] =~ m/^ImageLength: (\d+)/) { $base_image_height = $1; }
		if($OME_TIFF_OUTPUT[$i] =~ m/^ImageWidth: (\d+)/)  { $base_image_width = $1; }
		if($OME_TIFF_OUTPUT[$i] =~ m/^XResolution: (\d+)/) { $x_resolution = $1; }
		if($OME_TIFF_OUTPUT[$i] =~ m/^YResolution: (\d+)/) { $y_resolution = $1; }
		
## for ndpi files..		
#Reading global metadata
#BitsPerSample: 8
#Compression: JPEG
#DateTime: 2011:08:19 17:17:16
#ImageLength: 76544
#ImageWidth: 83328
#Instrument Make: Hamamatsu
#Instrument Model: C9600-12
#MetaDataPhotometricInterpretation: RGB
#NumberOfChannels: 3
#PhotometricInterpretation: YCbCr
#ReferenceBlackWhite: 0
#ResolutionUnit: Centimeter
#SamplesPerPixel: 3
#Software: NDP.scan 2.3.11
#XResolution: 44137
#YCbCrSubSampling: chroma image dimensions = luma image dimensions
#YResolution: 43950			
		}
	


		print "Image is $base_image_width by $base_image_height and was sacnned at $base_magnification\n";
	  print "and the x and y resolution were $x_resolution and $y_resolution ";
	if(  ($base_image_width / $x_resolution)  > 1.9 ) { $base_magnification=40;} else { $base_magnification=20;}
	  ### this is a shim... but basically if there's twice as many pixels as there is resolution it must have been a 40x scan..?
	  
$statement = "update svs_slide_location_info set scanned_resolution='$base_magnification',orig_image_width='$base_image_width', ";
$statement .= "orig_image_height=$base_image_height where source_file_name=$slide_name";
print $statement . "\n";

$insert_db = $realdbh->prepare($statement);
$insert_db->execute(); 
	}

sub		update_or_insert_slide_info($file,$dir,$slide_format)
	{
	#This function will do the database inserts/replace for the raw file location.... I am going to try and only have
	# one entry for a given file.... need to debate how to deal with this

	
$file = $_[0];
$dir = $_[1];	
$slide_format = $_[2];  ### SVS or NDPI basically
$input_file_escaped = $realdbh->quote($file);
$input_dir_escaped = $realdbh->quote($dir);



####			update_or_insert_slide_info($file,$dir,$FILE_EXTENSION_TO_LOOK_FOR);
###	parse_tiff_header_info_and_get_layer( $slide_path);

### so for SVS files... I can directly get the image size and resolution using the TIFFINFO command..
 $filesize = -s "$dir$file";
	$filename_no_ext = $file;
	$filename_no_ext =~ s/\.ndpi|\.svs//;
	$filename_no_ext = $realdbh->quote($filename_no_ext);
print "Filename which was $file with no extension is now $filename_no_ext ... \n";	



if($slide_format eq "svs")
	{
$svs_header_info=  parse_tiff_header_info_and_get_svs_info( "$dir$file");

### will also get the file size of the current file...

($image_width,$image_height,$skip,$appmag) = split(/;/,$svs_header_info);
	
	
$statement = "replace into svs_slide_location_info (source_file_name,root_directory,slide_format,ORIG_IMAGE_WIDTH,ORIG_IMAGE_HEIGHT,scanned_resolution,filesize,source_file_name_base) values  " ;
$statement .= "($input_file_escaped,$input_dir_escaped,'$slide_format',$image_width,$image_height,$appmag,$filesize,$filename_no_ext) ";
$insert_db = $realdbh->prepare($statement);
$insert_db->execute(); 
#print $statement . "\n";
	}
	else
	{

$statement = "replace into svs_slide_location_info (source_file_name,root_directory,slide_format,filesize,source_file_name_base) values  " ;
$statement .= "($input_file_escaped,$input_dir_escaped,'$_[2]',$filesize,$filename_no_ext) ";
$insert_db = $realdbh->prepare($statement);
$insert_db->execute(); 
	}

if($DBI::errstr or $realdbh::errstr ) {    print "found an error $DBI::errstr or $realdbh::errstr \n"; print $statement;  }


}


sub wipe_slide_database()
	{
$statement = "truncate svs_slide_location_info ";
print "$statement\n";
$insert_db = $realdbh->prepare($statement);
$insert_db->execute();
	}

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

	}


	
	
	

sub parse_tiff_header_info_and_get_svs_info( $SVS_FILE_NAME )
{

$SVS_FILE_NAME = $_[0];
#print "$SVS_FILE_NAME was passed... \n";
@TIFF_DATA = `tiffinfo $SVS_FILE_NAME`;

$image_width="";
$image_height="";

$current_layer =0;
for($k=0;$k<=$#TIFF_DATA;$k++)
       {
chomp($TIFF_DATA[$k]);
#print $TIFF_DATA[$k] . "\n";
$line_copy = $TIFF_DATA[$k];

## probably other ways to do this.. this means  image width ahsn't been foudn yet
if( $line_copy =~ m/Image Width:\s(\d+) Image Length:\s(\d+)(.*)/ && $image_width eq "" )
        {
#        print "Image resolution is $1 x $2;$1;$2;$current_layer;\n";
			$image_width = $1;
			$image_height = $2;
			$current_layer++;      
			}
	if( $line_copy =~ m/AppMag = (\d+)\|/  ) 	{ 	$app_mag = $1; 	}
		
}

return("$image_width;$image_height;appmag;$app_mag");
}
