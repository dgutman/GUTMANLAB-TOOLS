#!/usr/bin/perl
use File::Basename;

@DIRS_TO_PROCESS = `ls  /SGE_RAID/RESSLER_TRAUMA_IMAGING/ROBEX_BRAIN_MASKS/*.nii.gz`;




for($i=0;$i<=$#DIRS_TO_PROCESS;$i++)
	{
## ITERATING THROUGH ALL DIRECTORIES AND WILL COPY FILES AS NEEDED
	$CURRENT_DIRECTORY = $DIRS_TO_PROCESS[$i];
	chomp($CURRENT_DIRECTORY);
$CURRENT_DIRECTORY =~ m/(\d{2,5})/;
#print "Processing $CURRENT_DIRECTORY ...subject $1 \n";


	
$directory_to_copy_into = "/SGE_RAID/RESSLER_TRAUMA_IMAGING/RESILIENCE_and_VULNERABILITY_Subject_" . $1 . "/structural_data/manual_bet/";

if( -d $directory_to_copy_into ) {
## THIS WILL APPLY FSLMATHS TO THE BET IMAGE AND THEN THE OUTPUT GOES INTO THE FSLVBM DIRECTORY
$statement = "cp $CURRENT_DIRECTORY  $directory_to_copy_into" ."T1_flipped_bet_mask.nii.gz ";
print $statement . "\n";
#`$statement`;
	}
else	{
	print "Could not find $directory_to_copy_into \n";
	}



	}



