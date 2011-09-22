#!/usr/bin/perl
use Text::CSV;

require('xnat_update_field_module.pl');
$connect_params = " -host http://xnat.cci.psy.emory.edu:8080/xnat -u nbia -p nbia ";
$BASE_COMMAND = " /home/dgutman/xnat_tools/XNATRestClient $connect_params ";
my $csv = Text::CSV->new();


$current_project = "NBIA_TCGA";

## TAG TO SCAN FOR...
$SCAN_TAG_LIST[0] = "AXIAL T1 POST GD";
$SCAN_TAG_LIST[1] = "AXIAL T2 FLAIR";
$SCAN_TAG_LIST[2] = "AXIAL FSE";
$SCAN_TAG_LIST[3] = "FA MAP";
$SCAN_TAG_LIST[4] = "ADC MAP";
$SCAN_TAG_LIST[5] = "DWI MAP";
$SCAN_TAG_LIST[6] = "AXIAL T1 PRE GD";


my $DICOM_CACHE = "/IMAGING_SCRATCH/TCGA_DICOM_CACHE/TCGA_DATA/RAW_DICOMS/";
$IMAGE_ARCHIVE_PATH = "/IMAGING_SCRATCH/TCGA_DICOM_CACHE/TCGA_DATA/NIFTI_FILES/RAW_NIFTI_FILES";

### for some stupid reason... I am unable to use the xnat rest client to get this file... so I am just going to pass it as a parameter
### csv_input_file.txt 
#$FULL_SYNTAX = $BASE_COMMAND . " -m GET -remote " . $GET_ALL_SCAN_INFO;

#print $FULL_SYNTAX. "\n";

$statement = " curl -u nbia:nbia 'http://xnat.cci.psy.emory.edu:8080/xnat/REST/experiments?columns=xnat:mrSessionData/ID,xnat:imageScanData/type,xnat:imageScanData/ID,ID,label,subject_ID,subject_label,xnat:imageScanData/quality&format=csv'";



@FULL_SUBJECT_EXPERIMENT_LIST_INFO = `$statement`;




for($m=0;$m<=$#SCAN_TAG_LIST;$m++)
	{
$SCAN_TAG = $SCAN_TAG_LIST[$m];


for($x=0; $x<=$#FULL_SUBJECT_EXPERIMENT_LIST_INFO; $x++)
        {
#print $FULL_SUBJECT_EXPERIMENT_LIST_INFO[$x];

$csv->parse($FULL_SUBJECT_EXPERIMENT_LIST_INFO[$x]);
my @columns = $csv->fields();
#print "@columns\n";


### first make and see if this it he right project
if( $columns[6] eq $SCAN_TAG && $columns[8] eq "usable")
	{
print "Found $columns[6] for $columns[2] which is scan $columns[7]\n";
#### NOW I AM GOING TO CONVERT IT TO NIFTI IF IT IS NOT ALREADY DONE....
check_for_or_make_nifti_images($columns[9],$columns[2],$columns[7],$SCAN_TAG);
	}


        }



	}


sub check_for_or_make_nifti_images( $URI_FOR_IMAGE, $PATIENT_ID, $SCAN_ID, $SCAN_TAG_TO_OUTPUT)
{

## in order to "grab" the data i.e. the dicom images... we need to know the URI (its the easiest way to do it)
## plus the specific scan ID I am trying to grab for that subject.. and the patient ID is used for output naming
# the scan_tag_to_output is basically the 'AXIAL T1 PRE GD' or similar tag
## of note I am replacing spaces with _'s prior to output


## FIRST I AM GOING TO DECIDE WHAT THE FILE OUTPUT SHOULD_BE called.. and see if it exists...

$URI_FOR_IMAGE = $_[0];
$PATIENT_ID = $_[1];
$SCAN_ID = $_[2];
$SCAN_TAG_TO_OUTPUT=$_[3];

## REMOVE SPACES AND MAKE THEM _
$SCAN_TAG_TO_OUTPUT =~ s/\s+/-/g;

$IMAGE_OUTPUT_DIR =  $IMAGE_ARCHIVE_PATH . "/$SCAN_TAG_TO_OUTPUT";
if( ! -d $IMAGE_OUTPUT_DIR ) { mkdir $IMAGE_OUTPUT_DIR; }


$OUTPUT_FILE_NAME = ${PATIENT_ID} . "_${SCAN_TAG_TO_OUTPUT}_SCANNUM_${SCAN_ID}";
print "Output file should be $OUTPUT_FILE_NAME \n";

### OK NEXT THING TO DO IS ACTUALLY GRAB THE DATA...
##dg_update_scan_id_and_make_nifti.pl:###$ /home/dgutman/usr/bin/mcverter -o TCGA-06-0130/NIFTI_TEST -d -v -n -f nifti CRAP0/*.dcm

## if I can't find the nifti.. better pull the dicom images

$OUTPUT_FILE_FULL_PATH = "$IMAGE_OUTPUT_DIR/$OUTPUT_FILE_NAME";
$OUTPUT_FILE_FULL_PATH_WITH_EXT = "$IMAGE_OUTPUT_DIR/$OUTPUT_FILE_NAME.nii.gz";


if( ! -e $OUTPUT_FILE_FULL_PATH && ! (-e $OUTPUT_FILE_FULL_PATH_WITH_EXT) ) 
	{
 

print "Double check the output file isn't there... $OUTPUT_FILE_FULL_PATH or $OUTPUT_FILE_FULL_PATH_WITH_EXT\n";
pull_dicom_session( $URI_FOR_IMAGE, $SCAN_ID, $PATIENT_ID, $SCAN_TAG_TO_OUTPUT, "$IMAGE_OUTPUT_DIR/$OUTPUT_FILE_NAME" )
	}


}


sub pull_dicom_session()
{

###### NEXT THING I AM GOING TO DO IS FOR A GIVEN EXPERIMENT... LIST ALL THE SCAN 

$EXPERIMENT_URI = $_[0];
$SCAN_ID = $_[1];
$PATIENT_ID = $_[2];
$SCAN_NAME = $_[3];
$NIFTI_OUTPUT_FILE = $_[4];


$PULL_DICOM_COMMAND = $EXPERIMENT_URI . "/scans/$SCAN_ID/files?format=zip" ;

print "rest command is $PULL_DICOM_COMMAND \n";

## BELOW WILL GRAB A ZIP ARCHIVE... I NEED TO STICK THIS SOMEWHERE...
### http://xnat.cci.psy.emory.edu:8080/xnat/REST/experiments/CCIXNAT_E00002/scans/5/files?format=zip


$FULL_SYNTAX = $BASE_COMMAND . " -m GET -remote " . $PULL_DICOM_COMMAND;

print $FULL_SYNTAX. "\n";

$OUTPUT_DICOM_FILE_DIR = $DICOM_CACHE . $SCAN_NAME . "/" . $PATIENT_ID ;

### this prevents me from having "old" copies in the dicom directories-- this was causing problems because I would t=pull 2 sets of dicom images
## and then since i was only checking the nifti directory... I kept recreating the same images over and over again, evne though XNAt was updated


`rm -r $OUTPUT_DICOM_FILE_DIR//*`;


if( ! -d $OUTPUT_DICOM_FILE_DIR ) { `mkdir -p $OUTPUT_DICOM_FILE_DIR`};

print "I should be putting the dicom files in $OUTPUT_DICOM_FILE_DIR" . " and file is ${PATIENT_ID}_${SCAN_NAME}_SCANNUM_${SCAN_ID}.zip \n";

$FULL_OUTPUT_FILE = $OUTPUT_DICOM_FILE_DIR ."/" . "${PATIENT_ID}_${SCAN_NAME}_SCANNUM_${SCAN_ID}.zip";
print $FULL_OUTPUT_FILE . "\n";

$FULL_SYNTAX .= " > $FULL_OUTPUT_FILE ";

print $FULL_SYNTAX . "\n";
`$FULL_SYNTAX`;

$UNZIP_COMMAND = "unzip -o -j $FULL_OUTPUT_FILE -d $OUTPUT_DICOM_FILE_DIR";
`$UNZIP_COMMAND`;


$BUILD_NIFTI_COMMAND = "/home/dgutman/usr/bin/mcverter -o $NIFTI_OUTPUT_FILE -d -n -f nifti $OUTPUT_DICOM_FILE_DIR";
###dg_update_scan_id_and_make_nifti.pl:###$ /home/dgutman/usr/bin/mcverter -o TCGA-06-0130/NIFTI_TEST -d -v -n -f nifti CRAP0/*.dcm

print $BUILD_NIFTI_COMMAND . "\n";
`$BUILD_NIFTI_COMMAND`;

        }
