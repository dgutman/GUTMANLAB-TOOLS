''' 
Created on 1/12/2012
This is a simple python script to basically scan a "bigtiffed" directory and convert
them to pyramid tiff images..
'''
import os,glob,re , sys
import subprocess as sp

BIG_TIFF_OUTPUT_DIR = '/var/www/ADRC/BIG_TIFF_IMAGES/'
rootdir = BIG_TIFF_OUTPUT_DIR
PYRAMIDAL_TIFF_DIR = '/var/www/ADRC/ZOOMIFY_FULL_PYRAMIDS/TRAINING_SLIDES/'
PYRAMIDAL_TIFF_DIR = '/var/www/CDSA/TRAINING_SLIDES/'

BIGTIFF_FILES  = [ f for f in glob.glob1(rootdir, '*.tif') if os.path.isfile(os.path.join(rootdir, f)) ]
print len(BIGTIFF_FILES)," have been created ..."


ALREADY_PYRAMIDIZED_SLIDES = []

PYRAMID_TIFF_FILES  =glob.glob(PYRAMIDAL_TIFF_DIR+ '*/*.dzi.tif')
print len(PYRAMID_TIFF_FILES)
for pyramid in PYRAMID_TIFF_FILES:
#    print pyramid
     m = re.search('([^\/]+)\.dzi\.tif',pyramid)
     base_file_name = m.group(1)     
#     print m.group(1)
     if base_file_name.rpartition('.')[0]:
	print base_file_name.rpartition('.')[0],"FOUND A RPARATION MATCH"
	ALREADY_PYRAMIDIZED_SLIDES.append(base_file_name.rpartition('.')[0])
     else:
	print m.group(1)	
	ALREADY_PYRAMIDIZED_SLIDES.append(m.group(1)+'.tif')


print len(ALREADY_PYRAMIDIZED_SLIDES),"files have been converted although some are dupes..."
print len(set(ALREADY_PYRAMIDIZED_SLIDES)),"ARE ACTUALLY UNIQUE.. MUHAHAHHA"

print ALREADY_PYRAMIDIZED_SLIDES


### now I want to see if a .dzi.tif file exists for this little guy...
for file in BIGTIFF_FILES:
    PYRAMID_FILE = PYRAMIDAL_TIFF_DIR+file+".deflate.dzi.tif"
#    print PYRAMID_FILE
    if os.path.isfile(PYRAMID_FILE):
	print "Found it!!! WITH NORMAL NAME"
    elif file in ALREADY_PYRAMIDIZED_SLIDES:
	print "Found it!!! WITH special NAME",file
    else:
	VIPS_COMMAND  = "vips --vips-concurrency=2 --vips-progress im_vips2tiff "+rootdir+file+" "+PYRAMID_FILE+":lzw,tile:256x256,pyramid,,,,8"	
	print VIPS_COMMAND

sys.exit()

for tiledir in TILED_FILES:
    print tiledir,
    CONVERTED_TIFF=BIG_TIFF_OUTPUT_DIR+tiledir+'.tif'
    print CONVERTED_TIFF
    if os.path.isfile(CONVERTED_TIFF):
	print "Big tiff file at least exists... now checking for valid big tiff file "
	proc = sp.Popen(('tiffinfo', CONVERTED_TIFF), stdout=sp.PIPE, stderr=sp.PIPE)
	stdout, stderr = proc.communicate()
#	print stdout
	for line in stdout.splitlines():
	    if 'Image Width' in line:
	       theline = line
	       print theline
	       break
    else:
	  print "File was not convetred to tiff... don't nuke it!!"



'''
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


$ndpi_images_found = 0;
$already_tiled = 0;

foreach $ndpi_image ( @NDPI_FILES)
	{	
chomp($ndpi_image);
$input_file = $ndpi_image;
$output_file = $input_file;
($file,$dir) = fileparse($ndpi_image);

$ndpi_images_found++;



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

#	$VIPS_COMMAND  = "vips --vips-concurrency=2 --vips-progress im_vips2tiff $big_tif_output${TILE_ROOT}.tif $vips_pyramid_output${TILE_ROOT}.dzi.tif" . ":deflate,tile:256x256,pyramid";
	$VIPS_COMMAND  = "vips --vips-concurrency=2 --vips-progress im_vips2tiff $big_tif_output${TILE_ROOT}.tif $vips_pyramid_output${TILE_ROOT}.dzi.tif" . ":jpeg:100,tile:256x256,pyramid";
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
'''
