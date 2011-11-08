#!/usr/bin/perl
use DBI;
use DBD::mysql;
use File::Basename;

# This script will look in a <collection> of directories containing SVS files and generate appropriate image formats
# so that I can create zoomify pyramids

require 'dg_helper_functions_for_thumbnails_node32.pl';

$ROOT_DIR = "/data/dgutman/RAW_SLIDE_LINKS/";

## the pyramid root dir mirrors the directory structure of the RAW slide links... so i can keep the organization consistent
$THUMB_ROOT_DIR = "/data/dgutman/THUMBS/";
$PYRAMID_ROOT_DIR = "/data/dgutman/PYRAMIDS/";

@SVS_FILES_TO_PROCESS = `find -L ${ROOT_DIR}bcrTCGA*/* -name *.svs`;
#@SVS_FILES_TO_PROCESS = `find -L ${ROOT_DIR}bcrTCGA*/* -name *.svs`;

$slides_processed=0;
foreach $SVS_FILE ( @SVS_FILES_TO_PROCESS)
	{
	chomp($SVS_FILE);
	print "Found $SVS_FILE \n";
### For each of these files I will run it through my processing pipeline to generate tiff's/pyramids/etc...

## all pyramided/tiled files should live somewhere in the PYRAMID_ROOT_DIR..
$current_file_name = $SVS_FILE;
$current_file_name =~ s/$ROOT_DIR//;
($Filename,$Directory) = fileparse($current_file_name);
### FOR EACH FILE I AM GOIMG TO SEE IF THE THUMBNAIL AND MINITHnail exist


check_for_main_thumbnail_image_for_svs($Directory,$Filename);
	
if($slides_processed %5 == 0 ) { print "Processed $slides_processed\n"; }

$slides_processed++;
	}
