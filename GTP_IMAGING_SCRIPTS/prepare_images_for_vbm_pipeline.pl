
#!/usr/bin/perl

@DIRS_TO_PROCESS = `ls -d /SGE_RAID/RESSLER_TRAUMA_IMAGING/RESIL*`;


my %SUBJECT_ASSIGNMENTS;

$SUBJECT_ASSIGNMENTS{"6610"} = "TRAUMA_ONLY";
$SUBJECT_ASSIGNMENTS{"6753"} = "TRAUMA_ONLY";
$SUBJECT_ASSIGNMENTS{"6824"} = "PTSD";
###$SUBJECT_ASSIGNMENTS{"7293"} = "TRAUMA_ONLY"; Patient not used-- panic attack in scan room

$SUBJECT_ASSIGNMENTS{"7373"} = "TRAUMA_ONLY";
$SUBJECT_ASSIGNMENTS{"7422"} = "TRAUMA_ONLY";
$SUBJECT_ASSIGNMENTS{"7464"} = "TRAUMA_ONLY";
$SUBJECT_ASSIGNMENTS{"7470"} = "TRAUMA_ONLY";
$SUBJECT_ASSIGNMENTS{"7555"} = "TRAUMA_ONLY";
###$SUBJECT_ASSIGNMENTS{"7591"} = "PTSD";   ## JUNK-- is justine's brain!
#$SUBJECT_ASSIGNMENTS{"7614"} = "PTSD";  ### EXCLUDED FOR SUBDURAL HEMATOMA!!
$SUBJECT_ASSIGNMENTS{"7618"} = "TRAUMA_ONLY";
$SUBJECT_ASSIGNMENTS{"7806"} = "TRAUMA_ONLY";

$SUBJECT_ASSIGNMENTS{"7807"} = "PTSD";
$SUBJECT_ASSIGNMENTS{"7810"} = "TRAUMA_ONLY";
$SUBJECT_ASSIGNMENTS{"8025"} = "PTSD"; ### callcification in midline

$SUBJECT_ASSIGNMENTS{"8155"} = "PTSD";

$SUBJECT_ASSIGNMENTS{"8178"} = "PTSD";

$SUBJECT_ASSIGNMENTS{"8382"} = "PTSD";
$SUBJECT_ASSIGNMENTS{"8383"} = "PTSD";



$SUBJECT_ASSIGNMENTS{"8453"} = "PTSD";

$SUBJECT_ASSIGNMENTS{"8489"} = "PTSD";



$SUBJECT_ASSIGNMENTS{"8496"} = "TRAUMA_ONLY";


$SUBJECT_ASSIGNMENTS{"8518"} = "TRAUMA_ONLY";


$SUBJECT_ASSIGNMENTS{"8543"} = "PTSD";
$SUBJECT_ASSIGNMENTS{"8593"} = "PTSD"; ## brain a "little weird"?
$SUBJECT_ASSIGNMENTS{"8595"} = "PTSD";

$SUBJECT_ASSIGNMENTS{"8798"} = "PTSD";


$SUBJECT_ASSIGNMENTS{"8855"} = "TRAUMA_ONLY";  


#$SUBJECT_ASSIGNMENTS{"8857"} = "TRAUMA_ONLY";  ## LOTS OF MOVEMENT?? so bad T1?

$SUBJECT_ASSIGNMENTS{"8871"} = "TRAUMA_ONLY";

$SUBJECT_ASSIGNMENTS{"8883"} = "TRAUMA_ONLY";

$SUBJECT_ASSIGNMENTS{"8897"} = "TRAUMA_ONLY";
$SUBJECT_ASSIGNMENTS{"8982"} = "TRAUMA_ONLY";
$SUBJECT_ASSIGNMENTS{"8985"} = "TRAUMA_ONLY";
$SUBJECT_ASSIGNMENTS{"8993"} = "TRAUMA_ONLY";
$SUBJECT_ASSIGNMENTS{"9005"} = "PTSD";


$SUBJECT_ASSIGNMENTS{"9035"} = "PTSD";


$SUBJECT_ASSIGNMENTS{"9080"} = "PTSD";

$SUBJECT_ASSIGNMENTS{"9083"} = "PTSD";


$SUBJECT_ASSIGNMENTS{"9176"} = "PTSD";


$SUBJECT_ASSIGNMENTS{"9185"} = "PTSD";


$SUBJECT_ASSIGNMENTS{"9233"} = "PTSD";


$SUBJECT_ASSIGNMENTS{"9268"} = "TRAUMA_ONLY";


$SUBJECT_ASSIGNMENTS{"9295"} = "PTSD";


$PTSD_GROUP=0;
$CTRL_GROUP=0;
$TOTAL_PATIENTS = 0;
foreach $subj_key ( keys %SUBJECT_ASSIGNMENTS )
	{
	$TOTAL_PATIENTS++;
	if($SUBJECT_ASSIGNMENTS{$subj_key} eq "TRAUMA_ONLY") { $CTRL_GROUP++;}
	elsif($SUBJECT_ASSIGNMENTS{$subj_key} eq "PTSD") { $PTSD_GROUP++;}
	}
print "There are $PTSD_GROUP ptsd patients and $CTRL_GROUP control patients and $TOTAL_PATIENTS total patients... \n";


$VBM_OUTPUT_DIRECTORY = "/SGE_RAID/RESSLER_TRAUMA_IMAGING/DATA_ANALYSIS/my_fsl_vbm_ucla_collab/";


### CREATE OUTPUT DIRECTORIES
if( ! -d $VBM_OUTPUT_DIRECTORY ) { `mkdir $VBM_OUTPUT_DIRECTORY`; `mkdir $VBM_OUTPUT_DIRECTORY\\struc`;}


### I AM GOING TO REAPPLY THE MASK FROM THE MANUAL_BET directory and then copy over this newly generated image to the struc directory



for($i=0;$i<=$#DIRS_TO_PROCESS;$i++)
	{
## ITERATING THROUGH ALL DIRECTORIES AND WILL COPY FILES AS NEEDED
	$CURRENT_DIRECTORY = $DIRS_TO_PROCESS[$i];
	chomp($CURRENT_DIRECTORY);
$CURRENT_DIRECTORY =~ m/(.*)_Subject_(\d+)/;
#print "Processing $CURRENT_DIRECTORY ...subject $2 \n";


$CURRENT_SUBJECT_ID = $2;

$GROUP_ID_TAG = $SUBJECT_ASSIGNMENTS{$CURRENT_SUBJECT_ID};  


if($GROUP_ID_TAG ne "") 
	{


print "Current subject tag is :$CURRENT_SUBJECT_ID:$GROUP_ID_TAG\n";

$statement = " cp $CURRENT_DIRECTORY" . "/structural_data/T1_flipped.nii.gz " . $VBM_OUTPUT_DIRECTORY  . $GROUP_ID_TAG . "-$2" . ".nii.gz";
#print $statement . "\n";
`$statement`;


$statement = " cp $CURRENT_DIRECTORY" . "/structural_data/T1_flipped.nii.gz " . $VBM_OUTPUT_DIRECTORY ."struc/" . $GROUP_ID_TAG . "-$2" . "_struc.nii.gz";
#print $statement . "\n";
`$statement`;

### ALSO COPY THE BRAIN EXTRACTED IMAGES.... THESE WILL BE RECREAETED IF A structural_data/manual_bet/T1_flipped_bet_mask.nii.gz image exists......

## THIS WILL APPLY FSLMATHS TO THE BET IMAGE AND THEN THE OUTPUT GOES INTO THE FSLVBM DIRECTORY
$statement = "fslmaths $CURRENT_DIRECTORY". "/structural_data/T1_flipped.nii.gz " . " -mas $CURRENT_DIRECTORY". "/structural_data/manual_bet/T1_flipped_bet_mask.nii.gz " .  $VBM_OUTPUT_DIRECTORY  . "struc/" . $GROUP_ID_TAG . "-$2" . "_struc_brain.nii.gz";
#print $statement . "\n";
`$statement`;

	}
else
	{

print  "This is either an unknown subject ID or you have decided to exclude it..... for $CURRENT_SUBJECT_ID ... \n";
	}


	}

exit;
`cp /SGE_RAID/RESSLER_TRAUMA_IMAGING/DATA_ANALYSIS/my_fsl_vbmwithtim/*.nii.gz /var/www/RESSLER_IMAGING/VBM_PIPELINE/`;

$output_dir = "/var/www/RESSLER_IMAGING/VBM_PIPELINE/";
chdir $output_dir;
`slicesdir *.nii.gz`;



## run fslvbm_2_template when your done above step.. this will begin generating the data
#Running initial registration: ID=766651
#Creating first-pass template: ID=766652
#Running registration to first-pass template: ID=766653
#Creating second-pass template: ID=766654
#Study-specific template will be created, when complete, check results with:
#fslview struc/template_4D_GM
#and turn on the movie loop to check all subjects, then run:
#fslview  /usr/local/fsl/data/standard/tissuepriors/avg152T1_gray  struc/template_GM
#to check general alignment of mean GM template vs. original standard space template.
#[dgutman@trauma-computernode1 my_fsl_vbm_41subjs]$ 

