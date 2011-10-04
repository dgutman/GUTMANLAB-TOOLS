#!/usr/bin/perl
use DBI;
use DBD::mysql;
use Time::Local;
use Time::HiRes qw( gettimeofday tv_interval );

&connect_to_mysql_v2();
system('export FSLDIR=/usr/share/fsl');

$before_time = [gettimeofday];
$timer = [gettimeofday];
DBI->trace(0);

@DIRS_TO_PROCESS = glob("*-tile");



$statement = "truncate SERIES_DESCRIPTION ";

print "$statement\n";
$insert_db = $realdbh->prepare($statement);
$insert_db->execute();




for($k=0;$k<=$#DIRS_TO_PROCESS;$k++)
	{

print $DIRS_TO_PROCESS[$k] . "\n";

$FILE_PATTERN_ROOT_NAME = $DIRS_TO_PROCESS[$k];

$SOURCE_FILE_NAME = `ls $FILE_PATTERN_ROOT_NAME/\*.svs`;
print "Source file name is $SOURCE_FILE_NAME ";

chomp($SOURCE_FILE_NAME);

print $FILE_PATTERN_ROOT_NAME  . " is file pattern root name \n"; 
determine_image_directory_information($FILE_PATTERN_ROOT_NAME);
	}

exit;






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

sub get_image_series_reference_id  ($SERIES_TAG, $NUM_OF_TILES )
{
print "Was passed $_[0] $_[1] $_[2]  $_[3]\n";


$statement = "select series_id_key from SERIES_DESCRIPTION where SERIES_TAG='$_[0]'";

# and map_description='$_[1]' ";
print "$statement\n";
$select_db = $realdbh->prepare($statement);
$select_db->execute();

($series_id_key) = $select_db->fetchrow_array();


if($series_id_key eq "" )
{
$statement = "insert into SERIES_DESCRIPTION (series_tag,_root,map_description,nifti_image_path,index_text_file_image_path) values  " ;
$statement .= " ('$_[0]','$_[1]','$_[2]','$_[3]') ";
print "$statement \n";
$insert_db = $realdbh->prepare($statement);
$insert_db->execute();
}
else {

$statement = "update atlas_image_info set nifti_image_path='$_[2]',index_text_file_image_path='$_[3]' where analysis_key_root='$_[0]' and map_description='$_[1]' ";

print "$statement\n";
$insert_db = $realdbh->prepare($statement);
$insert_db->execute();

	}
$statement = "select atlas_map_id from atlas_image_info where analysis_key_root='$_[0]' and map_description='$_[1]' ";
print "$statement\n";
$select_db = $realdbh->prepare($statement);
$select_db->execute();

($atlas_map_id) = $select_db->fetchrow_array();




return($atlas_map_id);
}






### FIRST THING I NEED TO DO IS GENERATE A SERIES_ID_KEY FOR THIS SET OF IMAGES.. AS WELL AS PERFORM 
## SOME STATISTICS ON IMAGE SERIES THAT I AM TRYING TO LOAD....



$IMG_SPACE_ID = $ARGV[0];
$PROBTRACK_FILE_NAME = $ARGV[1];
$MASK_VALUE_LIST = $ARGV[2];
$ROI_DESCRIPT = $ARGV[3];

print "$IMG_SPACE_ID $PROBTRACK_FILE_NAME $ROI_DESCRIPT $MASK_VALUE_LIST\n";

if($#ARGV != 3) { print "Did not pass enough paramaeters \n";}

$seed_id = get_seed_reference_id($IMG_SPACE_ID,$ROI_DESCRIPT,$PROBTRACK_FILE_NAME,$MASK_VALUE_LIST); 

print "$seed_id is the seed id number for above \n";

process_index_file($IMG_SPACE_ID,$MASK_VALUE_LIST,$ROI_DESCRIPT,$seed_id);

##insert_raw_image_data($IMG_SPACE_ID,$PROBTRACK_FILE_NAME,$ROI_DESCRIPT,$seed_id);

exit;




sub process_index_file
{



print "Was passed $_[0]; $_[1]; $_[2] $_[3]; \n";


$INPUT_FILE= "$_[1]";

if(!open(FP_IN,"<$INPUT_FILE") )
        {
        print "Could not open $INPUT_FILE so quitting"; exit;
        }

print "Input ASCII file is $INPUT_FILE \n";
exit;

## NEED TO SKIP THE FIRST TWO LINES
<FP_IN>;
<FP_IN>;


$statement = "delete from atlas_index_and_descr_ids where analysis_key_root='$_[0]' and atlas_map_id='$_[3]'";
print "$statement\n";
$select_db = $realdbh->prepare($statement);
$select_db->execute();

while(<FP_IN>)
{
chomp;
#@COLS=split(/s+/,$_);  
@COLS=split;

print "$COLS[0];$COLS[1];\n";


$COLS[1] =~ s/\.nii\.gz//;
$statement = "insert into atlas_index_and_descr_ids  (analysis_key_root,region_description,atlas_map_id,region_id) values  " ;
$statement .= " ('$_[0]','$COLS[1]','$_[3]','$COLS[0]') ";
#print "$statement \n";
$insert_db = $realdbh->prepare($statement);
$insert_db->execute();




}






}





sub get_seed_reference_id  {

print "Was passed $_[0] $_[1] $_[2]  $_[3]\n";


$statement = "select atlas_map_id from atlas_image_info where analysis_key_root='$_[0]' and map_description='$_[1]' ";
print "$statement\n";
$select_db = $realdbh->prepare($statement);
$select_db->execute();

($roi_id) = $select_db->fetchrow_array();

if($roi_id eq "" )
{
$statement = "insert into atlas_image_info (analysis_key_root,map_description,nifti_image_path,index_text_file_image_path) values  " ;
$statement .= " ('$_[0]','$_[1]','$_[2]','$_[3]') ";
print "$statement \n";
$insert_db = $realdbh->prepare($statement);
$insert_db->execute();
}
else {

$statement = "update atlas_image_info set nifti_image_path='$_[2]',index_text_file_image_path='$_[3]' where analysis_key_root='$_[0]' and map_description='$_[1]' ";

print "$statement\n";
$insert_db = $realdbh->prepare($statement);
$insert_db->execute();

	}


$statement = "select atlas_map_id from atlas_image_info where analysis_key_root='$_[0]' and map_description='$_[1]' ";
print "$statement\n";
$select_db = $realdbh->prepare($statement);
$select_db->execute();

($atlas_map_id) = $select_db->fetchrow_array();




return($atlas_map_id);
}





sub connect_to_mysql_v2
{
#$ENV{'PATH'} = "/usr/local/mysql/bin";

my $dbhost = 'bumblebee.psychiatry.emory.edu';
my $sqldbuser = 'root';
my $sqldbpass = 'dti4ever';
my $dbname='IMAGE_BROWSER';


    $realdbh =
DBI->connect("dbi:mysql:database=$dbname;host=$dbhost",
"$sqldbuser", "$sqldbpass");
    if ($DBI::errstr) {
        if ($DBI::err == 1034) {
            print "The Mysql database is currently down.\n";
        }
        else {
            print "Unable to connect: $DBI::errstr\n";
        }
        exit;
    }
}



sub create_directory_structure
{
$DIR_STRUC_TO_CREATE = $_[0];

@PATH_LIST = split(/\//,$DIR_STRUC_TO_CREATE);

$START_PATH = "/";

for($beta=0;$beta<=$#PATH_LIST;$beta++)
        {
$START_PATH .=  $PATH_LIST[$beta] . "/";

if( !( -d $START_PATH) )
                {
        print "Creating output path for $START_PATH\n";

                `mkdir $START_PATH`;
                }
        }
}

