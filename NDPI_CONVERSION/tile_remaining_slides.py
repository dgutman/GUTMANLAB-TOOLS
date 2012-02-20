''' 
Created on 1/12/2012
This is a simple python script to convert a source directory of images to tiled images... but only if the
BIG tiff or PYRAMIDAL tiff doesn't exist yet

'''
import os,glob,re , sys
import subprocess as sp


NDPI_ROOT_DIR = '/data2/dgutman/TARUN_SLIDES/Training_Slides/'
BIG_TIFF_OUTPUT_DIR = '/data3/BIG_TIFF_IMAGES/'
rootdir = BIG_TIFF_OUTPUT_DIR
PYRAMIDAL_TIFF_DIR = '/data3/PYRAMIDS/ADRC/TRAINING_SLIDES/BATCH1/'
COMPRESSION_STRING = ":jpeg:75,tile:256x256,pyramid,,,,8"
TILE_CACHE = '/data3/TILE_CACHE/ADRC/TRAINING_SLIDES/'

# the ,,,,8 tells it to write the output as a BIGTIFF
#":lzw,tile:256x256,pyramid,,,,8"	
### The compression_string could also be deflate or lzw

### I may run these commands using SWIFT asynchronously... debating

f_command_list = open('tile_command_list.txt','w')

def build_whole_slide_tiff_image(input_directory,big_tiff_output_image):
	print "received ",input_directory,big_tiff_output_image
	buildslide_stmt = "/home/dgutman/Build_Slide/BuildSlide "+input_directory+big_tiff_output_image+"/ "+BIG_TIFF_OUTPUT_DIR+big_tiff_output_image+".tif -lzw\n"
	print buildslide_stmt
	f_command_list.write(buildslide_stmt)


def create_tiling_command(file_to_tile,output_directory,slide_id):
	print "Goign to tile ",file_to_tile,"into ",output_directory
	tile_command = "time wine NDPIUtilities.exe "+slide_id+".txt\n"
	print tile_command
	tile_input_file = open(slide_id+'.txt','w')
	tiling_stmt = "tile "+NDPI_ROOT_DIR+file_to_tile+".ndpi "+output_directory+file_to_tile+" 4096 40"
	tile_input_file.write(tiling_stmt)
	f_command_list.write(tile_command)



WHOLE_SLIDE_FILES  = [ f[:-5] for f in glob.glob1(NDPI_ROOT_DIR, '*.ndpi') if os.path.isfile(os.path.join(NDPI_ROOT_DIR, f)) ]
print len(WHOLE_SLIDE_FILES)," whole slide NDPI files are available to be tiled  ..."

BIGTIFF_FILES  = [ f[:-4] for f in glob.glob1(rootdir, '*.tif') if os.path.isfile(os.path.join(rootdir, f)) ]
print len(BIGTIFF_FILES)," big tiff files have been created ..."
#print BIGTIFF_FILES


TILED_DIRECTORIES   = [ f for f in glob.glob1(TILE_CACHE, '*') if os.path.isdir(os.path.join(TILE_CACHE, f)) ]
print len(TILED_DIRECTORIES)," directgories have been tiled."
print TILED_DIRECTORIES


ALREADY_PYRAMIDIZED_SLIDES = []

PYRAMID_TIFF_FILES  =glob.glob(PYRAMIDAL_TIFF_DIR+ '*.dzi.tif')
print len(PYRAMID_TIFF_FILES),"files have been converted to a pyramidal tiff"

for pyramid in PYRAMID_TIFF_FILES:
     print pyramid
     m = re.search('([^\/]+)\.dzi\.tif',pyramid)
     base_file_name = m.group(1)     
#     print m.group(1)
     if base_file_name.rpartition('.')[0]:
	print base_file_name.rpartition('.')[0],"FOUND A MATCH below removes the .tif extension"
#	ALREADY_PYRAMIDIZED_SLIDES.append(base_file_name.rpartition('.')[0][:-4])
	ALREADY_PYRAMIDIZED_SLIDES.append(base_file_name.rpartition('.')[0])
     else:
#	print m.group(1)	
#	ALREADY_PYRAMIDIZED_SLIDES.append(m.group(1)+'.tif')
	ALREADY_PYRAMIDIZED_SLIDES.append(m.group(1))


print len(ALREADY_PYRAMIDIZED_SLIDES),"files have been converted to TIFF PYRAMID although some are dupes..."
print len(set(ALREADY_PYRAMIDIZED_SLIDES)),"ARE ACTUALLY UNIQUE patients.. MUHAHAHHA"
print ALREADY_PYRAMIDIZED_SLIDES


### generating the list of tiled files

## the tiled files are intermediate.s.. I should see how many of them exist....

CONVERTED_TO_BIGTIFF_FILES = []

for tiffimage in BIGTIFF_FILES:
#   print tiledir,"is the tile output file..."
    CONVERTED_TIFF=BIG_TIFF_OUTPUT_DIR+tiffimage+".tif"
#    print CONVERTED_TIFF,"is the converted tiff... "
    if os.path.isfile(CONVERTED_TIFF):
#	print "Big tiff file at least exists... now checking for valid big tiff file "
	proc = sp.Popen(('tiffinfo', CONVERTED_TIFF), stdout=sp.PIPE, stderr=sp.PIPE)
	stdout, stderr = proc.communicate()
#	print stdout
	for line in stdout.splitlines():
	    if 'Image Width' in line:
	       theline = line
#	       print theline
	       break
	CONVERTED_TO_BIGTIFF_FILES.append(tiffimage)
    else:
#	  print "File was not convetred to tiff... do not delete the TILE directory "
	pass
print len(CONVERTED_TO_BIGTIFF_FILES),"are already converted to big tiff images"
print "List of already pyramidized files... "

### so if the PYRAMID DOESN'T EXIST... FIRST CHECK IF THE BIG TIFF IMAGE EXISTS...

slides_to_tile = 0
tiled_slides = 0
big_tiffed_files = 0

for WSI in WHOLE_SLIDE_FILES:
    if WSI not in ALREADY_PYRAMIDIZED_SLIDES:
## means the file needs to be either pyramidized ... means I might need the BIGTIFF image
	if WSI in CONVERTED_TO_BIGTIFF_FILES:
		print "Need to convert big tiff image to a pyramid..."
	        VIPS_COMMAND  = "vips  --vips-progress im_vips2tiff "+BIG_TIFF_OUTPUT_DIR+WSI+".tif  "+PYRAMIDAL_TIFF_DIR+WSI+".jpeg75.dzi.tif"+COMPRESSION_STRING
		f_command_list.write(VIPS_COMMAND+'\n')	
	        print VIPS_COMMAND

	elif WSI not in CONVERTED_TO_BIGTIFF_FILES and WSI in TILED_DIRECTORIES:
	        print "Need to convert tile directory to tiled image"
		print WSI,"image needs to be made into a BIG TIFF image first.."
		build_whole_slide_tiff_image(TILE_CACHE,WSI)
	elif WSI not in TILED_DIRECTORIES:
		create_tiling_command(WSI,TILE_CACHE,WSI)

        else:
		print "Need to pyramidize",WSI	
		slides_to_tile+=1


    else:
        tiled_slides+=1

print "there are ",slides_to_tile,"slides to tile"
print "and ",tiled_slides,"tiled slides"


sys.exit()




### now I want to see if a .dzi.tif file exists for this little guy...
for file in BIGTIFF_FILES:
    PYRAMID_FILE = PYRAMIDAL_TIFF_DIR+file+".deflate.dzi.tif"
#    print PYRAMID_FILE
    if os.path.isfile(PYRAMID_FILE):
#	print "Found it!!! WITH NORMAL NAME"
        pass
    elif file in ALREADY_PYRAMIDIZED_SLIDES:
	print "Found it!!! WITH special NAME",file
    else:
	VIPS_COMMAND  = "vips --vips-concurrency=2 --vips-progress im_vips2tiff "+rootdir+file+" "+PYRAMID_FILE+COMPRESSION_STRING

	print VIPS_COMMAND

sys.exit()


'''
### CONDOR VESION


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
