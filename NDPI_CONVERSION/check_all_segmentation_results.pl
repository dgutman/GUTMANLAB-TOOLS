#!/usr/bin/perl

@DIRS_TO_PROCESS = `ls -d /IMAGING_SCRATCH/RESSLER_TRAUMA_IMAGING/RESIL*`;


$IMAGE_SET_OUTPUT_DIR = "/var/www/RESSLER_IMAGING/BET_DATA/";
$IMAGE_SET_MASK_OUTPUT_DIR = "/var/www/RESSLER_IMAGING/BET_DATA/MASK/";
$IMAGE_SET_BET_OUTPUT_DIR = "/var/www/RESSLER_IMAGING/BET_DATA/BET/";

### CREATE OUTPUT DIRECTORIES
if( ! -d $IMAGE_SET_OUTPUT_DIR) { `mkdir -p $IMAGE_SET_OUTPUT_DIR`;}

$slices_statement = "slicesdir -o ";


$DEBUG = 0;

for($i=0;$i<=$#DIRS_TO_PROCESS;$i++)
	{
## ITERATING THROUGH ALL DIRECTORIES AND WILL COPY FILES AS NEEDED
	$CURRENT_DIRECTORY = $DIRS_TO_PROCESS[$i];
	chomp($CURRENT_DIRECTORY);
$CURRENT_DIRECTORY =~ m/(.*)_Subject_+(\d+)/;
print "Processing $CURRENT_DIRECTORY ...subject $2 \n";

## instead of copying the subject I am going to reapply the BET mask and "fix" it...
#$statement = "cp $CURRENT_DIRECTORY" . "/structural_data/T1_flipped_bet.nii.gz" . " /var/www/RESSLER_IMAGING/BET_DATA/$2" . "-T1_flipped_bet.nii.gz";
#print $statement;
#`$statement`;



## THIS WILL APPLY FSLMATHS TO THE BET IMAGE AND THEN THE OUTPUT GOES INTO THE FSLVBM DIRECTORY

$statement = "fslmaths $CURRENT_DIRECTORY". "/structural_data/T1_flipped.nii.gz " . " -mas $CURRENT_DIRECTORY". "/structural_data/manual_bet/T1_flipped_bet_mask.nii.gz " .  $IMAGE_SET_BET_OUTPUT_DIR  . $2 . "-T1_flipped_bet.nii.gz";
print $statement . "\n";
if( ! $DEBUG) {`$statement`;}

$statement = "cp $CURRENT_DIRECTORY" . "/structural_data/manual_bet/T1_flipped_bet_mask.nii.gz " . $IMAGE_SET_MASK_OUTPUT_DIR  . $2 . "-T1_flipped_bet_mask.nii.gz";
print $statement;
if( ! $DEBUG) {`$statement`;}



$statement = "cp $CURRENT_DIRECTORY" . "/structural_data/manual_bet/T1_flipped.nii.gz " . $IMAGE_SET_OUTPUT_DIR  . $2 . "-T1_flipped.nii.gz";
print $statement;
if( ! $DEBUG) {`$statement`;}

$check_for_me = $IMAGE_SET_OUTPUT_DIR . $2 . "-T1_flipped.nii.gz";


if( -e $check_for_me) { $slices_statement .=  $2 . "-T1_flipped.nii.gz MASK/" . $2  . "-T1_flipped_bet_mask.nii.gz " ; }
	}




print $slices_statement;

chdir $IMAGE_SET_OUTPUT_DIR;
exec("cd $IMAGE_SET_OUTPUT_DIR; $slices_statement");






