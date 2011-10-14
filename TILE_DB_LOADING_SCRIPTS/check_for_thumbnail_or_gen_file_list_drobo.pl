#!/usr/bin/perl
use DBI;
use DBD::mysql;
use File::Basename;

require 'dg_helper_functions_for_thumbnails_drobo.pl';

&connect_to_mysql_v2();





$ROOT_DIR = "/IMAGING_SCRATCH/THUMBNAIL_DEPOT/RAW_SLIDE_LINKS/";
@SVS_FILES_TO_CHECK = ( glob("/IMAGING_SCRATCH/THUMBNAIL_DEPOT/RAW_SLIDE_LINKS/LU*/*/*.svs"),
glob("/IMAGING_SCRATCH/THUMBNAIL_DEPOT/RAW_SLIDE_LINKS/bcrTCGA-HE/*/*.svs"),
glob("/IMAGING_SCRATCH/THUMBNAIL_DEPOT/RAW_SLIDE_LINKS/bcrTCGA-FS/*/*.svs") ,
glob("/IMAGING_SCRATCH/THUMBNAIL_DEPOT/RAW_SLIDE_LINKS/BREAST_TUMORS/*/*.svs"), 
glob("/IMAGING_SCRATCH/THUMBNAIL_DEPOT/RAW_SLIDE_LINKS/LUNG_LUSC_DIAG/*/*.svs") 
);


### this is a weird hack... there's something goofy related to the symbolic links..

for($i=0;$i<$#SVS_FILES_TO_CHECK;$i++)
	{
$current_file_name = $SVS_FILES_TO_CHECK[$i];
$current_file_name =~ s/$ROOT_DIR//;
($Filename,$Directory) = fileparse($current_file_name);
### FOR EACH FILE I AM GOIMG TO SEE IF THE THUMBNAIL AND MINITHnail exist


print $Directory . ";$Filename\n";

if( $Directory =~ /\s/ || $Filename =~ /\s/ || $Filename =~ /\(/) { 
		print "$Directory or $Filename has space in it... skipping \n"; 
					}
else {

#print $Directory . ";$Filename\n";
### First I check if the main thumbnail exists-- the 1X version currently needs to be done in windows...
### so I can't directly create it here.. I have to use NDPI Utilities

$large_thumbnail_name = check_for_main_thumbnail_image_for_svs($Directory,$Filename);
if($large_thumbnail_name eq "0")  {  next; }
$current_patient_id = 		determine_patient_id($Filename,$Directory);

if($current_patient_id eq "NONEFOUND")  {  next; }
### should be passing it THUMBNAIL_FILE_NAME

$thumbnail_info_string =  check_for_derivative_thumbnails($large_thumbnail_name);

#$statement  = "insert into SLIDE_TILE_AND_THUMBNAIL_INFO PATIENT_ID,FILESYSTEM_THUMBNAIL_IMAGE_LARGE, 
#FILESYSTEM_THUMBNAIL_IMAGE_SMALL,";
#$statement .= "WEBROOT_THUMBNAIL_IMAGE_LARGE,WEBROOT_THUMBNAIL_IMAGE_SMALL ";
#$statement .= "  Values( '$current_patient_id', '$large_thumbnail_name', '$Filename',";
#$statement .= " $Directory, $thumbnail_info_string \n";

$tiny_webroot_thumb = $large_thumbnail_name;
$tiny_webroot_thumb =~ s/\.tif$/-tiny\.png/;
$tiny_webroot_thumb =~ s/$THUMBNAIL_DEPOT//;

$webroot_large_thumb = $large_thumbnail_name;
$webroot_large_thumb =~ s/\.tif$/\.png/;
$webroot_large_thumb =~ s/$THUMBNAIL_DEPOT//;

### the tiff itself is downsampled by 20X from the original

$image_size = parse_tiff_header_info_and_get_large_layer_size($SVS_FILES_TO_CHECK[$i]);
     chomp($image_size);
#print $image_size ."\n";

	@IMG_PARAMS = split(/x/,$image_size);
	
	$SCANNED_RESOLUTION = 20; ## it's probably 20 for the bcr folder..
	$orig_image_width = $IMG_PARAMS[0];
	$orig_image_height = $IMG_PARAMS[1];

$Slide_group = $Directory; ## normally
$Slide_group_copy = $Slide_group;

@GET_THE_TAGS = split(/\//,$Slide_group_copy);
$Slide_group = $GET_THE_TAGS[0];
#print "Slide group should be $Slide_group \n";

$statement = "insert into SLIDE_TILE_AND_THUMBNAIL_INFO (SLIDE_ID_TAG,ROOT_DIRECTORY,PATIENT_ID, FILESYSTEM_THUMBNAIL_IMAGE_SMALL,SLIDE_GROUP,";
$statement .="  WEBROOT_THUMBNAIL_IMAGE_SMALL,WEBROOT_THUMBNAIL_IMAGE_LARGE,LARGE_THUMB_WIDTH,LARGE_THUMB_HEIGHT,ORIG_IMAGE_WIDTH,ORIG_IMAGE_HEIGHT)";
$statement .= " Values ( '$Filename','$Directory','$current_patient_id', '$large_thumbnail_name', '$Slide_group' , '$tiny_webroot_thumb','$webroot_large_thumb','$IMG_PARAMS[0]','$IMG_PARAMS[1]','$orig_image_width','$orig_image_height' ) ";
#print $statement. "\n";

$insert_db = $realdbh->prepare($statement);
$insert_db->execute();
		}
	}



if(!open(FP_OUT,">thumbnail_make_file.txt") ) 
	{
	print "unable to open output file for thumbnail generation....\n";exit;
	}


$ROOT_DIR = "/STORAGE01-VG2/Images/";


for($i=0;$i<$#NDPI_FILES_TO_CHECK;$i++)
	{

$current_file_name = $NDPI_FILES_TO_CHECK[$i];
$current_file_name =~ s/$ROOT_DIR//;
($Filename,$Directory) = fileparse($current_file_name);
$Directory =~ s/\///;
print $Directory . ";$Filename\n";
### FOR EACH FILE I AM GOIMG TO SEE IF THE THUMBNAIL AND MINITHnail exist

if( $Directory =~ /\s/ || $Filename =~ /\s/ || $Filename =~ /\(/) { 
				print "$Directory or $Filename has space in it... skipping \n"; 
					}
else {


### First I check if the main thumbnail exists-- the 1X version currently needs to be done in windows...
### so I can't directly create it here.. I have to use NDPI Utilities


$large_thumbnail_name = check_for_main_thumbnail_image($Directory,$Filename);
if($large_thumbnail_name eq "0")  {  next; }


$current_patient_id = 		determine_patient_id($Filename,$Directory);
if($current_patient_id eq "NONEFOUND")  {  next; }

### I Am also going to make sure all the derivate thumbnails exist...
##check_for_deriviate_thumbnail_image($large_thumbnail_name);
### should be passing it THUMBNAIL_FILE_NAME
#sub check_for_derivative_thumbnails($THUMBNAIL_FILE_NAME)
$thumbnail_info_string =  check_for_derivative_thumbnails($large_thumbnail_name);

$statement  = "insert into SLIDE_TILE_AND_THUMBNAIL_INFO PATIENT_ID,FILESYSTEM_THUMBNAIL_IMAGE_LARGE, FILESYSTEM_THUMBNAIL_IMAGE_SMALL,";
$statement .= "WEBROOT_THUMBNAIL_IMAGE_LARGE,WEBROOT_THUMBNAIL_IMAGE_SMALL ";
$statement .= "  Values( '$current_patient_id', '$large_thumbnail_name', '$Filename',";
$statement .= " $Directory, $thumbnail_info_string \n";

$tiny_webroot_thumb = $large_thumbnail_name;
$tiny_webroot_thumb =~ s/\.tif$/-tiny\.png/;
$tiny_webroot_thumb =~ s/$THUMBNAIL_DEPOT//;

$webroot_large_thumb = $large_thumbnail_name;
$webroot_large_thumb =~ s/\.tif$/\.png/;
$webroot_large_thumb =~ s/$THUMBNAIL_DEPOT//;



### the tiff itself is downsampled by 20X from the original
#@TIFF_INFO_ON_SVS = `tiffinfo $SOURCE_FILE_NAME -0`;
#@TIFF_INFO_ON_SVS = `tiffinfo $NDPI_FILES_TO_CHECK[$i] -0`;
#print "Just ran tiffinfo... maybe it failed?? \n";
## ndpi files aren't tiffs..
        $image_size = `identify -format "%wx%h" $large_thumbnail_name`;
        chomp($image_size);
	@IMG_PARAMS = split(/x/,$image_size);
	
## in this case I am directly excatying it anyway
$SCANNED_RESOLUTION = 40; ## it's probably 20 for the bcr folder..
	$orig_image_width = $IMG_PARAMS[0]*$SCANNED_RESOLUTION;
	$orig_image_height = $IMG_PARAMS[1]*$SCANNED_RESOLUTION;

$statement = "insert into SLIDE_TILE_AND_THUMBNAIL_INFO (SLIDE_ID_TAG,ROOT_DIRECTORY,PATIENT_ID, FILESYSTEM_THUMBNAIL_IMAGE_SMALL,SLIDE_GROUP,";
$statement .="  WEBROOT_THUMBNAIL_IMAGE_SMALL,WEBROOT_THUMBNAIL_IMAGE_LARGE,LARGE_THUMB_WIDTH,LARGE_THUMB_HEIGHT,ORIG_IMAGE_WIDTH,ORIG_IMAGE_HEIGHT)";
$statement .= " Values ( '$Filename','$Directory','$current_patient_id', '$large_thumbnail_name', '$Directory' , '$tiny_webroot_thumb','$webroot_large_thumb','$IMG_PARAMS[0]','$IMG_PARAMS[1]','$orig_image_width','$orig_image_height' ) ";
#print $statement. "\n";

$insert_db = $realdbh->prepare($statement);
$insert_db->execute();
		}

	}


exit;


sub check_for_main_thumbnail_image($Directory,$Filename)
	{
$slide_input_directory = $_[0];
$slide_input_file = $_[1];

$current_thumbnail_dir = $THUMBNAIL_DEPOT . $slide_input_directory; 
print "thumbnails should be in $current_thumbnail_dir \n";



 if( ! -d $current_thumbnail_dir ) { `mkdir $current_thumbnail_dir;`; print "generating $current_thumbnail_dir \n"; }

### each svs or ndpi file should have a -thumbnail.jpg associated with it... this is cached
## locally inn my /imagingscratch/thumbnaildepot directory...

$THUMBNAIL_FILE_NAME = $current_thumbnail_dir . "/$slide_input_file";
$THUMBNAIL_FILE_NAME =~ s/\.ndpi|\.svs/-thumbnail.tif/;

print "thumbnail name should be $THUMBNAIL_FILE_NAME \n";

if( ! -e $THUMBNAIL_FILE_NAME)
		{
		$WINDOWS_OUTPUT_FILE_NAME = $THUMBNAIL_FILE_NAME;
		$WINDOWS_OUTPUT_FILE_NAME =~ s/$THUMBNAIL_DEPOT/$WINDOWS_ROOT_PATH/;
		$CURRENT_WHOLESLIDE_FILENAME = $NDPI_FILES_TO_CHECK[$i];
### NEED TO MAKE THIS A WINDOWS PATH SO I MAKE MY SCRIPT FOR WINDOWS	
### ITS WHEREEVER I HAVE STORAGE01 MOUNTED..
		$CURRENT_WHOLESLIDE_FILENAME =~ s/$ROOT_DIR/W:\\Images\\/;
		$statement = "thumb $CURRENT_WHOLESLIDE_FILENAME $WINDOWS_OUTPUT_FILE_NAME 1 \n";
		$statement =~ s/\//\\/g;	
print "statement should be $statement \n";

### for windows all back slashed should relaly be forward slashes... I hate this...

if( ! ( $CURRENT_WHOLESLIDE_FILENAME =~ /\s/) && ! ($WINDOWS_OUTPUT_FILE_NAME =~ /\s/) )
			{
		printf FP_OUT $statement;
	return(0); ## thumbnail does NOT exist in this case
			}
else 
	{
	print "Need to fix $CURRENT_WHOLESLIDE_FILENAME\n";
	return(0); ## thumbnail does NOT exist in this case either and file has a problem in its name
	}
}
return($THUMBNAIL_FILE_NAME);
	}



sub check_for_derivative_thumbnails($THUMBNAIL_FILE_NAME)
    {
### this module makes sure that the original thumbnail (which is a huge 1X tif) has correspond png images
### as weill as a "tiny" version that is a fixed width

$THUMBNAIL_FILE_NAME = $_[0];
#print "Received $THUMBNAIL_FILE_NAME ... \n";

$input_tiff = $THUMBNAIL_FILE_NAME;
$input_to_png = $THUMBNAIL_FILE_NAME;
$input_to_png =~ s/\.tif/\.png/;

$input_to_tiny_png = $THUMBNAIL_FILE_NAME;
$input_to_tiny_png =~ s/\.tif/-tiny\.png/;

###convert input -thumbnail 200 output$THUMBNAIL_FILE_NAME

if( ! -e $input_to_png )
    {
    $convert_statement = "convert $input_tiff $input_to_png";
    print $convert_statement ."\n";
    `$convert_statement`;
    }

if( ! -e $input_to_tiny_png)
    {
    $convert_statement = "convert $input_tiff -thumbnail 200 $input_to_tiny_png";
    print $convert_statement ."\n";
    `$convert_statement`;
    }


$formatted_string = " '$input_to_tiny_png', '$input_tiff', '$input_to_png' ";
#print $formatted_string . "\n";
### this will actually be returned as an entire string contain the root path and the full filename..
### i want to track these separately anyway..

return($input_to_tiny_png);
    }




sub determine_patient_id ( $slide_id )
	{
$input_fileid = $_[0];
$input_directory = $_[1];
$parsed_patient_id="";

##################3 determine file type.. its svs or ndpi
if($input_fileid =~ /\.ndpi/) 
	{
#	print "file type is ndpi \n";
	$image_file_type = "ndpi";
	}
elsif($input_fileid =~ /\.svs/) 
	{
#	print "file type is svs \n";
	$image_file_type = "svs";
	}


#print "received $input_fileid \n";

if( $input_fileid =~ m/^HF/ ) 
	{
	# print "henry ford file\n"; 
	if( $input_fileid =~ /HF(\d\d\d\d)/ ) 
		{ 
		# print "four digit hf found\n"; 
		$parsed_patient_id="HF$1";	
		}

	}
elsif( $input_fileid =~ m/^TCGA/ ) { 
		 
	if( $input_fileid =~ /TCGA-(\d\d)-(\d\d\d\d)/ ) 
		{ 
		$parsed_patient_id="TCGA-$1-$2";	
		}
	elsif	($input_fileid =~ /TCGA-(..)-(....)/ )
		{
		$parsed_patient_id="TCGA-$1-$2";
		}
	else
		{
		print "tcga  file $input_fileid not parsed properly\n";
		}	

				}
elsif( $input_fileid =~ m/^900_/ ) {

if( $input_fileid =~ /900_(\d\d)_(\d\d\d\d)/ ) 
		{ 
		$parsed_patient_id="900_$1_$2";	
		}
	else
		{
		print "tju  file $input_fileid not parsed properly\n";
		}	
				}
elsif( $input_directory =~ m/Thomas/ )
		{
		print STDERR "This means I am looking at other types of thomas jefferson data\n";
		print STDERR "File id was $input_fileid \n";
		if( $input_fileid =~ /(\d+)-/ ) 
			{
			$parsed_patient_id = $1; 
			print STDERR $parsed_patient_id;}
		} 

###  i will also do the database inserts for ecah file here.... will add these fileds lateer


if($parsed_patient_id eq "") { print STDERR $input_fileid . "\n"; return("NONEFOUND"); }
else { return($parsed_patient_id); }
	}





sub connect_to_mysql_v2
{
#$ENV{'PATH'} = "/usr/local/mysql/bin";

my $dbhost = 'trauma-computernode1.psychiatry.emory.edu';
my $sqldbuser = 'tcgauser';
my $sqldbpass = 'cancersuckz!';
my $dbname='HISTO_VIEWER_DATA';


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
