
use DBI;
use DBD::mysql;
use File::Basename;


sub check_for_main_thumbnail_image_for_svs($Directory,$Filename)
	{

$slide_input_directory = $_[0];
$slide_input_file = $_[1];

#### TO MAKE THINGS SIMPLER I AM GOING TO HAVE ALIASSES FOR CERTAIN SLIDE INPUT DIRECTORIES..
### SOME OF THESE INPUT DIRECTORIES ARE JUST TOO LONG SO I AM GOING TO CREATE A SHORTERED VERSION    du  f7

#print "Received $slide_input_directory and $slide_input_file \n";


$current_thumbnail_dir = $THUMBNAIL_DEPOT .  $slide_input_directory; 

#print "thumbnails should be in $current_thumbnail_dir \n";

if( ! -d $current_thumbnail_dir ) { `mkdir -p $current_thumbnail_dir;`; print "generating $current_thumbnail_dir \n"; }

### each svs or ndpi file should have a -thumbnail.jpg associated with it... this is cached
## locally inn my /imagingscratch/thumbnaildepot directory...

$THUMBNAIL_FILE_NAME = $current_thumbnail_dir . "$slide_input_file";
$THUMBNAIL_FILE_NAME =~ s/\.ndpi|\.svs/-thumbnail.tif/;


if( ! -e $THUMBNAIL_FILE_NAME)
		{
##for svs files i don't need to do all the weird winddows stuff...
		$CURRENT_WHOLESLIDE_FILENAME = $SVS_FILES_TO_CHECK[$i];

print "should be making the thumbnial...\n";
print "thumbnail name should be $THUMBNAIL_FILE_NAME \n";


if( ! ( $CURRENT_WHOLESLIDE_FILENAME =~ /\s/) ) ## thumbnail does NOT exist yet so I shold create it
			{
print "Generating thumbnail now...?";

$layer_to_grab = parse_tiff_header_info_and_get_layer($CURRENT_WHOLESLIDE_FILENAME);

print "You should be pulling $layer_to_grab \n";

$layer_to_grab = 1;
$statement ="/APERIO_SHARE/DAG_SCRIPTS/extractLayer $CURRENT_WHOLESLIDE_FILENAME  $THUMBNAIL_FILE_NAME $layer_to_grab \n";


`$statement`;

`convert $THUMBNAIL_FILE_NAME.ppm $THUMBNAIL_FILE_NAME`;
`rm $THUMBNAIL_FILE_NAME.ppm`;

#`convert  /APERIO_SHARE/TCGA_SLIDES/THUMBNAIL_DEPOT/$THUMBNAIL_NAME.jpg -thumbnail 200 /APERIO_SHARE/TCGA_SLIDES/THUMBNAIL_DEPOT/$THUMBNAIL_NAME-tiny.jpg`;

	return($THUMBNAIL_FILE_NAME); 
			}
else 
	{
	print "Need to fix $CURRENT_WHOLESLIDE_FILENAME\n";
	return(0); ## thumbnail does NOT exist in this case either and file has a problem in its name
	}
}

return($THUMBNAIL_FILE_NAME);
	}



sub parse_tiff_header_info( $SVS_FILE_NAME )
{

$SVS_FILE_NAME = $_[0];
#print "$SVS_FILE_NAME was passed... \n";
@TIFF_DATA = `tiffinfo $SVS_FILE_NAME`;

$current_layer =0;
for($k=0;$k<=$#TIFF_DATA;$k++)
       {
chomp($TIFF_DATA[$k]);
#print $TIFF_DATA[$k] . "\n";

$line_copy = $TIFF_DATA[$k];

if( $line_copy =~ m/TIFF Directory at offset/)
                {
 #               print "Found a layer.... processing layer $current_layer;";
                $current_layer++;
                }

if( $line_copy =~ m/Image Width:\s(\d+) Image Length:\s(\d+)(.*)/  )
        {
#        print "Image resolution is $1 x $2;$1;$2;$current_layer;\n";
        }
 
}
}





sub parse_tiff_header_info_and_get_layer( $SVS_FILE_NAME )
{

$SVS_FILE_NAME = $_[0];
#print "$SVS_FILE_NAME was passed... \n";
@TIFF_DATA = `tiffinfo $SVS_FILE_NAME`;

$current_layer =0;
for($k=0;$k<=$#TIFF_DATA;$k++)
       {
chomp($TIFF_DATA[$k]);
#print $TIFF_DATA[$k] . "\n";

$line_copy = $TIFF_DATA[$k];

if( $line_copy =~ m/TIFF Directory at offset/)
                {
 #               print "Found a layer.... processing layer $current_layer;";
                
                }

if( $line_copy =~ m/Image Width:\s(\d+) Image Length:\s(\d+)(.*)/  )
        {
        print "Image resolution is $1 x $2;$1;$2;$current_layer;\n";


if($current_layer >= 2 && $1 < 4096) { 
	#		print "You should be here now... hmm for $1 $2 $current_layer \n";
			return($current_layer); 
			}
$current_layer++;      
		  }
 
}

return( (2) );
}




sub parse_tiff_header_info_and_get_large_layer_size( $SVS_FILE_NAME )
{

$SVS_FILE_NAME = $_[0];
#print "$SVS_FILE_NAME was passed... \n";
@TIFF_DATA = `tiffinfo $SVS_FILE_NAME -0`;

for($x=0;$x<=$#TIFF_DATA;$x++)
		{
$line_copy =$TIFF_DATA[$x];
chomp($line_copy);
if( $line_copy =~ m/Image Width:\s(\d+) Image Length:\s(\d+)(.*)/  )
        {
 #       print "Image resolution is $1 x $2;$1;$2;$current_layer;\n";
			return("$1x$2"); 
			}
	}
}


return(1);
