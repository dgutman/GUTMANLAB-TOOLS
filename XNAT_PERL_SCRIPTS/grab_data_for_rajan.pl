#!/usr/bin/perl
use Text::CSV;

require('xnat_update_field_module.pl');
$connect_params = " -host http://xnat.cci.emory.edu:8080/xnat -u nbia -p nbia ";
$BASE_COMMAND = " /home/dgutman/xnat_tools/XNATRestClient $connect_params ";

my $csv = Text::CSV->new();


if(!open(FP_RAJAN,"<experiment_ids_to_get_for_rajan.txt") )
	{
	print "I couldn open rajan's file.. \n"; exit;
	}


%EXPERIMENT_IDS_TO_GET ;

while(<FP_RAJAN>)
	{
chomp;
$expt_id = $_;
#print $expt_id . "\n";

$expt_uri = "/xnat/REST/experiments/$expt_id/scans/ALL/files?format=zip";

#pull_all_dicom_sessions($expt_uri,"TEST");
$EXPERIMENT_IDS_TO_GET{$expt_id}++;
	}

$current_project = "NBIA_TCGA";

## TAG TO SCAN FOR...

$IMAGE_ARCHIVE_PATH = "/IMAGING_SCRATCH/TCGA_DICOM_CACHE/RAJAN_DATA/";

#$FULL_SYNTAX = $BASE_COMMAND . " -m GET -remote " . $GET_ALL_SCAN_INFO;
$statement = " curl -u nbia:nbia 'http://xnat.cci.emory.edu:8080/xnat/REST/experiments?columns=xnat:mrSessionData/ID,xnat:imageScanData/type,xnat:imageScanData/ID,ID,label,subject_ID,subject_label,xnat:imageScanData/quality&format=csv'";

@FULL_SUBJECT_EXPERIMENT_LIST_INFO = `$statement`;

my %EXPERIMENT_LABELS;

if(!open(FP_IN,"<newfilelist.csv") )
	{
	print "unable to open file... crap!!! \n";

	}

#for($x=0; $x<=$#FULL_SUBJECT_EXPERIMENT_LIST_INFO; $x++)
#$x=0;
#while(<FP_IN>)


for($x=0; $x<=$#FULL_SUBJECT_EXPERIMENT_LIST_INFO; $x++)
        {
chomp;

#print $FULL_SUBJECT_EXPERIMENT_LIST_INFO[$x];
$csv->parse($FULL_SUBJECT_EXPERIMENT_LIST_INFO[$x]);
my @columns = $csv->fields();


if( $EXPERIMENT_IDS_TO_GET{$columns[0]} )
	{

$file_label = $columns[2] . "-". $columns[5];
#print "grabbing $file_label \n";

$EXPERIMENT_LABELS{$columns[0]} = $file_label;



	}

}



#$EXPERIMENT_IDS_TO_GET{$expt_id}++;

foreach $expt_key ( keys %EXPERIMENT_IDS_TO_GET )
	{
#print "should be pulling $expt_key with file sesion label " . $EXPERIMENT_LABELS{$expt_key}  . "\n";

$file_label = $EXPERIMENT_LABELS{$expt_key};

pull_all_dicom_sessions($expt_key,$file_label);

	}

exit;

### first make and see if this it he right project
#if( $columns[6] eq $SCAN_TAG && $columns[8] eq "usable")
#	{
#print "Found $columns[6] for $columns[2] which is scan $columns[7]\n";
##### NOW I AM GOING TO CONVERT IT TO NIFTI IF IT IS NOT ALREADY DONE....
#check_for_or_make_nifti_images($columns[9],$columns[2],$columns[7],$SCAN_TAG);
#	}








sub pull_all_dicom_sessions()
{

###### NEXT THING I AM GOING TO DO IS FOR A GIVEN EXPERIMENT... LIST ALL THE SCAN 

$EXPERIMENT_URI = $_[0];
$NIFTI_OUTPUT_FILE = $_[1];

$PULL_DICOM_COMMAND = "\"/experiments/" .$EXPERIMENT_URI . "/scans/ALL/files?format=zip&\"" ;

#print "rest command is $PULL_DICOM_COMMAND \n";

## BELOW WILL GRAB A ZIP ARCHIVE... I NEED TO STICK THIS SOMEWHERE...
### http://xnat.cci.psy.emory.edu:8080/xnat/REST/experiments/CCIXNAT_E00002/scans/5/files?format=zip


$FULL_SYNTAX = $BASE_COMMAND . " -m GET -remote " . $PULL_DICOM_COMMAND;

#	print $FULL_SYNTAX. "\n MEH";

$OUTPUT_DICOM_FILE_DIR = $IMAGE_ARCHIVE_PATH .  $NIFTI_OUTPUT_FILE ;


#print "\nputting dat IN $OUTPUT_DICOM_FILE_DIR";

### this prevents me from having "old" copies in the dicom directories-- this was causing problems because I would t=pull 2 sets of dicom images
## and then since i was only checking the nifti directory... I kept recreating the same images over and over again, evne though XNAt was updated


`rm -r $OUTPUT_DICOM_FILE_DIR//*`;


if( ! -d $OUTPUT_DICOM_FILE_DIR ) { `mkdir -p $OUTPUT_DICOM_FILE_DIR`}
else { printf STDERR "dir exists\n";}
#print "I should be putting the dicom files in $OUTPUT_DICOM_FILE_DIR" . " and file is ${PATIENT_ID}_${SCAN_NAME}_SCANNUM_${SCAN_ID}.zip \n";

#$FULL_OUTPUT_FILE = $OUTPUT_DICOM_FILE_DIR ."/" . "${PATIENT_ID}_${SCAN_NAME}_SCANNUM_${SCAN_ID}.zip";
$FULL_OUTPUT_FILE = $OUTPUT_DICOM_FILE_DIR ."/" . $NIFTI_OUTPUT_FILE  . ".zip";
#print $FULL_OUTPUT_FILE . "\n";

$FULL_SYNTAX .= " > $FULL_OUTPUT_FILE ";

print $FULL_SYNTAX . "\n";
#`$FULL_SYNTAX`;


        }
