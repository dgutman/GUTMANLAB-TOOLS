#!/usr/bin/perl
use File::Basename;

$IMAGE_DIR = "/IMAGING_SCRATCH/TCGA_DICOM_CACHE/TCGA_DATA/ALEX_GETS_CONFUSED_EASILY/big_CRAP_DUMP/*_AXIAL-T1-POST-GD_*";



@BASE_IMAGES = glob("${IMAGE_DIR}*.nii.gz");


#$slices_statement = "slicesdir -o -S ";
$slices_statement = "slicesdir -o -S ";

for($i=0;$i<=$#BASE_IMAGES;$i++)
	{

$MASK_IMAGE = $BASE_IMAGES[$i];

($file,$dir) = fileparse($MASK_IMAGE);

if( $file =~ m/TCGA-(\d\d)-(\d\d\d\d)/ ) { $patient_root = "TCGA-$1-$2"; }
elsif ($file =~ m/HF(\d\d\d\d)/ ) { $patient_root = "HF$1"; }
else { print "No file root found.. exiting\n"; exit; }


$MASK_IMAGE =  $patient_root . "_DJ_POST_MASK_flipped.nii.gz ";

$BASE_IMAGE_BEFORE_BET = $file;
#$BASE_IMAGE_BEFORE_BET =~ s/_MANUAL_BET\.nii\.gz/\.nii\.gz/;


	$slices_statement .=  $BASE_IMAGE_BEFORE_BET . " $MASK_IMAGE " ;


	}


print $slices_statement;
`$slices_statement`;
