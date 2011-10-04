#!/usr/bin/perl

sub parse_tiff_header_info( $SVS_FILE_NAME )
{

$SVS_FILE_NAME = $_[0];

print "$SVS_FILE_NAME was passed... \n";

@TIFF_DATA = `tiffinfo $SVS_FILE_NAME`;


$current_layer =0;
for($k=0;$k<=$#TIFF_DATA;$k++)
	{
chomp($TIFF_DATA[$k]);
#print $TIFF_DATA[$k] . "\n";

$line_copy = $TIFF_DATA[$k];


if( $line_copy =~ m/TIFF Directory at offset/)
		{
		print "Found a layer.... processing layer $current_layer;\n";
		$current_layer++;
		}

if( $line_copy =~ m/Image Width:\s(\d+) Image Length:\s(\d+)(.*)/  )
	{
	print "Image resolution is $1 x $2 \n";
	}

  
}
}


return 1;
