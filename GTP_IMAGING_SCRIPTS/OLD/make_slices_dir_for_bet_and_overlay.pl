#!/usr/bin/perl


$IMAGE_DIR = "/SGE_RAID/RESSLER_TRAUMA_IMAGING/LONI_MIRROR/PTSD/T1_MPRAGE_IMAGES/";



@BASE_IMAGES = glob("${IMAGE_DIR}*-ROBEX-MASK_F.nii.gz");


#$slices_statement = "slicesdir -o -S ";
$slices_statement = "slicesdir -o ";

for($i=0;$i<=$#BASE_IMAGES;$i++)
	{

$MASK_IMAGE = $BASE_IMAGES[$i];
#$MASK_IMAGE =~ s/\.nii\.gz/_mask\.nii\.gz/;

$BASE_IMAGE_BEFORE_BET = $BASE_IMAGES[$i];
$BASE_IMAGE_BEFORE_BET =~ s/-ROBEX-MASK_F\.nii\.gz/\.nii\.gz/;


	$slices_statement .=  $BASE_IMAGE_BEFORE_BET . " $MASK_IMAGE " ;


	}


print $slices_statement;
`$slices_statement`;
