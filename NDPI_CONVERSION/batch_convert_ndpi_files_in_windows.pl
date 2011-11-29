#!/usr/bin/perl
use File::Basename;

$directory_to_transcode = "/IMAGING_SCRATCH/CONDR/";



$windows_path = $directory_to_transcode;
$windows_path =~ s/\/data2//;
$windows_path =~ s/\//\\/g;
$windows_path = "W:" . $windows_path;
print $windows_path . "\n";


#$windows_path = "W:\\Images\\HenryFordRembrandt\\";


@NDPI_FILES = `find $directory_to_transcode -name '*.ndpi'`;


$tile_resolution=40;
$tile_size=4096;



foreach $ndpi_image ( @NDPI_FILES)
	{
chomp($ndpi_image);

$input_file = $ndpi_image;

$input_file =~ s/\//\\/g;
$input_file =~ s/IMAGING_SCRATCH\\//;

$output_file = $input_file;


($file,$dir) = fileparse($ndpi_image);

$file =~ s/\s+/_/;
$file =~ s/\&/-/;
$file =~ s/\.ndpi//;

$linux_output_directory = "/drobo/40X_Tiles/" . $dir ."/" . $file;
if( ! -d $linux_output_directory) { ` mkdir -p $linux_output_directory `;}


$windows_output_directory = "R:\\40X_Tiles" . $dir .  $file;
$windows_output_directory =~ s/\//\\/g;



@CHECK_FILE_COUNT = `find $linux_output_directory -name '*.tif' | wc `;



#print STDERR  "File count was $CHECK_FILE_COUNT[0]"; 


$line = $CHECK_FILE_COUNT[0];



#$statement ="tile W:${input_file} R:\\40X_Tiles${output_file} $tile_resolution $tile_size ";
$statement ="tile V:${input_file} $windows_output_directory $tile_size $tile_resolution";


if( $line =~ m/0(\s+)0(\s+)0(\s+)/ )
	{
	print $statement . "\n";
	print STDERR "Blank file!! \n";

	}
else 
	{
	print STDERR "Already converted \n"; 
	}


	}
