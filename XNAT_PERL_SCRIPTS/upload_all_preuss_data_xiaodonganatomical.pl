#!/usr/bin/perl
use File::Basename;

@DIRS_TO_UPLOAD = glob("*Preuss*.zip");

$PROJECT="PREUSS_DATA";

foreach $zip_file ( @DIRS_TO_UPLOAD )
	{
print STDERR "You should be uploading $zip_file .. \n";


$zip_file =~ m/(.*)_Preuss/;



$patient_root_name = $1;


if($patient_root_name =~ m/^R/ && !($1 eq "Rowena") ) { $SUBJECT_ID = "Macaque_$patient_root_name"; }
else { $SUBJECT_ID = "Chimp_" . $patient_root_name; }




#$SCAN_ID = $2;
#print "$1 and $2 \n";

#print "I found $SCAN_ID for scan \n";

($file,$directory,$suffix) = fileparse($zip_file,".zip");

$EXPERIMENT_ID = $file;
$ZIP_FILE_NAME = $zip_file;



$statement = "/IMAGING_SCRATCH/TCGA_DICOM_CACHE/SCRIPTS/dg_python_tools/upload-dicom-zipfile.sh  $PROJECT $SUBJECT_ID $EXPERIMENT_ID $ZIP_FILE_NAME  'http://xnat.cci.emory.edu:8080/xnat' nbia nbia ";
print $statement ."\n";
#`$statement`;
	}




