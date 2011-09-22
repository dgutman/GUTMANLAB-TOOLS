#!/usr/bin/perl

## because of the way mcverter works... I can only specific the output directory... not the name of the output files
## which makes sense as its designed to work on the output directories... so because of this I am going to iterate through
# the created output directories and clean things up

## basically just move the files contained in a directory
use File::Basename;
require 'braintumor_project_cleanup_functions.pl';

$DICOM_IMAGE_ROOT_DIR = "/IMAGING_SCRATCH/TCGA_DICOM_CACHE/TCGA_DATA/NIFTI_FILES/RAW_NIFTI_FILES/AXIAL-T1-PRE-GD/";


$DICOM_IMAGE_QA_DIR = $DICOM_IMAGE_ROOT_DIR . "MANUAL_QA/";


my @DIRS_TO_PROCESS = glob("${DICOM_IMAGE_ROOT_DIR}/*.nii.gz/*");
my %DIRECTORIES_SEEN; ## for some goofy reasons... sometimes a directory contains more than one nifti file... I need to mark these
my %DIRECTORIES_TO_MOVE_AND_ANALYZE  ; ## These directories contain one or more files in it and need to be investigated
my %UNIQUE_SUBJECTS ;





check_directory_for_duplicate_patients( $DICOM_IMAGE_ROOT_DIR);





for($i=0;$i<=$#DIRS_TO_PROCESS;$i++)
	{

#print $DIRS_TO_PROCESS[$i] ."\n";

my($filename,$directory) = fileparse($DIRS_TO_PROCESS[$i]);




if($DIRECTORIES_SEEN{$directory} ) {
		 print "this dir has two files... $directory \n"; 
		$DIRECTORIES_TO_MOVE_AND_ANALYZE{$directory}++; 
		}
else {   $DIRECTORIES_SEEN{$directory}++; }

	}



foreach $dir_keys ( keys %DIRECTORIES_TO_MOVE_AND_ANALYZE ) 
	{
print $DIRECTORIES_TO_MOVE_AND_ANALYZE{$dir_keys} . ";$dir_keys;\n";

$statement = "mv $dir_keys $DICOM_IMAGE_QA_DIR";
print $statement . "\n";
`$statement`;	
	}



### so if there are no duplicatels




my @FILES_TO_MOVE = glob("${DICOM_IMAGE_ROOT_DIR}*.nii.gz/*");

for($i=0;$i<=$#FILES_TO_MOVE;$i++)
	{
	print "I am going to move the file $FILES_TO_MOVE[$i] ... \n";

my($filename,$directory) = fileparse($FILES_TO_MOVE[$i]);

## the new filename is the actual directory name with .nii.gz on it.

@DIR_SPLIT = split(/\//,$directory);

$NEW_FILE_NAME = $DIR_SPLIT[($#DIR_SPLIT)];

$NEW_FILE_NAME =~ s/\.gz//;

print "New file name is $NEW_FILE_NAME \n";

$statement = "mv $FILES_TO_MOVE[$i] $DICOM_IMAGE_ROOT_DIR/$NEW_FILE_NAME";
print $statement."\n";
`$statement`;
$statement_two = "rmdir $directory";
print $statement_two . "\n";
`$statement_two`;
}



 

