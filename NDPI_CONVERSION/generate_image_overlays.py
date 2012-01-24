#!/usr/bin/python
import glob, os, re, sys
import subprocess as sp

# This script will check an output directory and make overlays so I can do quick QA/QC checks

PLASTIMATCH_MASK_EXPORT_DIR = '/IMAGING_SCRATCH/TCGA_DICOM_CACHE/TCGA_DATA/PLASTIMATCH_MASK_EXPORT/'


rt_mask_file_list = glob.glob(PLASTIMATCH_MASK_EXPORT_DIR + '*.nii.gz')

for maskfile in rt_mask_file_list:
	print maskfile
#        background_image = maskfile
#	background_image = background_image.replace('/PLASTIMATCH_MASK_EXPORT/','/PLASTIMATCH_/MASK_EXPORT/BACKGROUND/')
#	print background_imagea
	(dir, file) = os.path.split(maskfile)
	print "file is",file,"and dir is",dir
	file_name_elements = file[:-7].split('_')
	if len(file_name_elements)==4:
		subject_id=file_name_elements[0]
		scan_type=file_name_elements[1]
		rt_file_name=file_name_elements[2]
		mask_file_name=file_name_elements[3]
		print subject_id,scan_type,rt_file_name,mask_file_name	
	else:
	    print "FILE NAME ERROR FOR ",file	
	background_image = dir+'/BACKGROUNDS/'+subject_id+"_"+scan_type+"_"+rt_file_name+'_BACKGROUND.nii.gz'
	if os.path.exists(background_image):
	    print "Found background iamge!! woo hoo"
	else:
	    print "Can't find",background_image
	


sys.exit()

'''
#!/usr/bin/perl
use File::Basename;

#$UNDERLAY_IMAGE_DEMO = "/IMAGING_SCRATCH/TCGA_DICOM_CACHE/TCGA_DATA/NIFTI_FILES/NIFTI_MASKS/POST_GD_MASKS/TCGA-06-0166_POST-GD-MASK_DJ.nii";

##$POST_GD_IMAGE = "/IMAGING_SCRATCH/TCGA_DICOM_CACHE/TCGA_DATA/NIFTI_FILES/RAW_NIFTI_FILES/AXIAL-T1-POST-GD/TCGA-06-0166_AXIAL-T1-POST-GD_SCANNUM_7.nii.gz ";



$AXIAL_T1_POST_GD_DIR = "/IMAGING_SCRATCH/TCGA_DICOM_CACHE/TCGA_DATA/NIFTI_FILES/RAW_NIFTI_FILES/AXIAL-T1-POST-GD/";

$OUTPUT_DIRECTORY = "/IMAGING_SCRATCH/TCGA_DICOM_CACHE/PNG_WEB_DEPOT/";


 

##@TCGA_MASKS_ON_POST_GD_LIST = glob("/IMAGING_SCRATCH/TCGA_DICOM_CACHE/TCGA_DATA/NIFTI_FILES/NIFTI_MASKS/POST_GD_MASKS/TCGA*POST-GD-MASK*.nii.gz");

### I need to figure out the correspond mask for this patient... eventually this will all be done in a database... but for now I can just use regex


#$statement = "medcon -f  $INPUT_NIFTI_IMAGE -w -fv -noprefix -o
#$OUTPUT_JPG_ROOT_DIR" . $UNDERLAY_ID ."_axial -c png "  .
#$ADDL_COMMANDS;
#`$statement`;
#
#print "Generating coronal images for $ANALYSIS_KEY_ROOT $UNDERLAY_ID \n";
#$statement = "medcon -f  $INPUT_NIFTI_IMAGE -w -rs  -noprefix -o
#$OUTPUT_JPG_ROOT_DIR" . $UNDERLAY_ID ."_coronal -cor -c png "  .
#$ADDL_COMMANDS;;
#`$statement`;



foreach $TCGA_MASK ( @TCGA_MASKS_ON_POST_GD_LIST )
	{

print $TCGA_MASK;

($file,$dir) = fileparse($TCGA_MASK);

$copy = $file;

@SPLIT_ME = split(/_/,$copy);
$patient_id = $SPLIT_ME[0];


print "Generating overlay for $patient_id for mask file $file ... \n";


### NOW LOOK FOR MATCHING OVERLAY FILE...
$TARGET_POST_GD_FILE = $AXIAL_T1_POST_GD_DIR . $patient_id . "_AXIAL-T1-POST-GD_*";
 @matching_files = glob($TARGET_POST_GD_FILE);
if( $#matching_files == 0 ) { print "Target file is $matching_files[0] \n";   

$overlay_command = "overlay 1 1 $matching_files[0] -a $TCGA_MASK 0 1 /tmp/tmp_image.nii.gz";
print $overlay_command . "\n";
`$overlay_command`;
$command = "slicer -L  /tmp/tmp_image.nii.gz -A 1600 ${OUTPUT_DIRECTORY}${patient_id}-axial-postgdimages-with-mask.png ";
print $command;
`$command`;


		}
elsif( $#matching_files > 0 ) { print "More than one post gd image detected \n" ;  }


	}

#!/usr/bin/perl
use File::Basename;
### this will generate statistics and overlays showing the ROI itselfp ainted on top of the underlying
## image... it will use a number of system calls to do this
##mostly slicer and imagemagick



#$UNDERLAY_IMAGE_DEMO = "/IMAGING_SCRATCH/TCGA_DICOM_CACHE/TCGA_DATA/NIFTI_FILES/NIFTI_MASKS/POST_GD_MASKS/TCGA-06-0166_POST-GD-MASK_DJ.nii";

##$POST_GD_IMAGE = "/IMAGING_SCRATCH/TCGA_DICOM_CACHE/TCGA_DATA/NIFTI_FILES/RAW_NIFTI_FILES/AXIAL-T1-POST-GD/TCGA-06-0166_AXIAL-T1-POST-GD_SCANNUM_7.nii.gz ";
$AXIAL_T1_POST_GD_DIR = "/IMAGING_SCRATCH/TCGA_DICOM_CACHE/TCGA_DATA/NIFTI_FILES/RAW_NIFTI_FILES/AXIAL-T1-POST-GD/";


$OUTPUT_DIRECTORY = "/IMAGING_SCRATCH/TCGA_DICOM_CACHE/DASHBOARD_IMAGES/";



@TCGA_MASKS_ON_POST_GD_LIST = glob("/IMAGING_SCRATCH/TCGA_DICOM_CACHE/TCGA_DATA/NIFTI_FILES/NIFTI_MASKS/POST_GD_MASKS/TCGA*POST-GD-MASK*.nii.gz");

### I need to figure out the correspond mask for this patient... eventually this will all be done in a database... but for now I can just use regex


foreach $TCGA_MASK ( @TCGA_MASKS_ON_POST_GD_LIST )
	{

print $TCGA_MASK;

($file,$dir) = fileparse($TCGA_MASK);

$copy = $file;

@SPLIT_ME = split(/_/,$copy);
$patient_id = $SPLIT_ME[0];


print "Generating overlay for $patient_id for mask file $file ... \n";


### NOW LOOK FOR MATCHING OVERLAY FILE...
$TARGET_POST_GD_FILE = $AXIAL_T1_POST_GD_DIR . $patient_id . "_AXIAL-T1-POST-GD_*";
 @matching_files = glob($TARGET_POST_GD_FILE);
if( $#matching_files == 0 ) { print "Target file is $matching_files[0] \n";   

$overlay_command = "overlay 1 1 $matching_files[0] -a $TCGA_MASK 0 1 /tmp/tmp_image.nii.gz";
print $overlay_command . "\n";
`$overlay_command`;
$command = "slicer -L  /tmp/tmp_image.nii.gz -A 1600 ${OUTPUT_DIRECTORY}${patient_id}-axial-postgdimages-with-mask.png ";
print $command;
`$command`;


		}
elsif( $#matching_files > 0 ) { print "More than one post gd image detected \n" ;  }


	}


exit;
'''
