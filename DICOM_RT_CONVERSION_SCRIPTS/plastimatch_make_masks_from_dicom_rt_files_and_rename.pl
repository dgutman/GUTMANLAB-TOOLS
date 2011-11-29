#!/usr/bin/perl

use File::Basename;

$FILE_TYPE[0] = "AXIAL_T2_FLAIR";
$FILE_TYPE[1] = "AXIAL_T1_POST_GD";




#http://xnat.cci.emory.edu:8080/xnat/data/experiments?xsiType=xnat:mrSessionData&columns=ID,xnat:mrScanData/type,xnat:mrScanData/series_description,xnat:mrScanData/parameters/tr,xnat:mrScanData/parameters/te,xnat:mrScanData/parameters/frames,xnat:mrScanData/parameters/voxelRes/x,xnat:mrScanData/parameters/voxelRes/y,xnat:mrScanData/parameters/voxelRes/z,date,xnat:mrScanData/parameters/quality,xnat:mrScanData/parameters/UID&

$DICOM_RT_MASK_EXPORT_DIRECTORY = "/IMAGING_SCRATCH/TCGA_DICOM_CACHE/TCGA_DATA/MASK_EXPORT/";


$CONVERSION_OUTPUT_DIRECTORY = "/IMAGING_SCRATCH/PLASTIMATCH_OUTPUT/";



@RT_DCM_FILE_LIST = glob("${DICOM_RT_MASK_EXPORT_DIRECTORY}*/*/*.dcm");


### I am going to keep track of all the subjects and scans I have data on... may as well asince it's easy


foreach $potential_rt_file ( @RT_DCM_FILE_LIST )
	{
#	print $potential_rt_file . "\n";


	($file, $dir) = fileparse($potential_rt_file);

	$dir_copy = $dir;
	### Since I want to isolate only the last two files I will get rid of the base directory... w
	$dir_copy =~ s/\Q$DICOM_RT_MASK_EXPORT_DIRECTORY\E//;

	($SUBJECT_ID, $SCAN_ID)  = split(/\//,$dir_copy);
	
	if( $SCAN_ID =~ m/AXIAL_T1_POST_GD/ )
		{	
#		print "found an Axial T1 post GD image for $SUBJECT_ID ... \n";
	 process_dicom_rt_header_file ( $potential_rt_file )



		}
	elsif( $SCAN_ID =~ m/AXIAL_T2_FLAIR/ )
		{	
#		print "found an Axial T2 Flair image for $SUBJECT_ID ... \n";
		}
	else {
	
	print "NO MATCH FOR $DIRECTORY_PARTS[0] $DIRECTORY_PARTS[1] \n";
	print $potential_rt_file . "\n";
		}


	}


sub process_dicom_rt_header_file ( $input_dicom_rt_file )
	{
$dicom_rt_file = $_[0];


#(0010,0010) PN [226427^]                                #   8, 1 PatientsName
#(0010,0020) LO [TCGA-06-0162]                           #  12, 1 PatientID
#(0010,0030) DA (no value available)                     #   0, 0 PatientsBirthDate
##(0010,0040) CS (no value available)                     #   0, 0 PatientsSex
#(0018,1000) LO [0]                                      #   2, 1 DeviceSerialNumber
##(0018,1020) LO [2.7.0]                                  #   6, 1 SoftwareVersions
##0020,000d) UI [1.3.6.1.4.1.9328.50.45.68017139859310765805049054903251069055] #  62, 1 StudyInstanceUID
#(0020,000e) UI [1.2.276.0.7230010.3.1.4.1014192915.6324.1312394934.28] #  54, 1 SeriesInstanceUID



@DCM_DUMP_OUTPUT = `dcmdump $dicom_rt_file`;

$found_structure_set = 0;

	foreach $line ( @DCM_DUMP_OUTPUT )
		{

		if( $line =~ m/\(0008,0060\) CS \[RTSTRUCT\]/) { 
#						print $line;
						 $found_structure_set=1;
						 }
		elsif( $line =~ m/\(0010,0020\) LO \[(.*)\]/ )   {
						#		 print "Subject id should be $1 \n"; 
						$SUBJECT_ID = $1;
								}
		elsif( $line =~ m/\(0020,000d\) UI \[(.*)\]/ )   {
						#	 print "StudyInstance UID  should be $1 \n"; 
						$STUDY_UID=$1;
								}
		elsif( $line =~ m/\(0020,000e\) UI \[(.*)\]/ )   {
						#		 print "Series Instance UID  should be $1 \n";
							 $SERIES_UID=$1; 
								}



		}




if($found_structure_set ) {
			 print "found a dicom RT file for $dicom_rt_file... \n"; 
			print "Series id is $SERIES_UID and Study id is $STUDY_UID \n";
		### check and see if series ID has been exported for this directory..

			($file,$base_dir ) = fileparse($dicom_rt_file );
				print "Base dir should be $base_dir ... \n";
				print "File with series id is.... \n";
				$series_id_output_dir = $base_dir . $SERIES_UID  ;
				if( -d $series_id_output_dir ) { 
				print "Series id output dir exists... at $series_id_output_dir \n";
					 }
				else { 
					print "have not exported directory or can't find it... \n"; 
					print "Subject is $SUBJECT_ID for $dicom_rt_file \n";
				}


$statement = "plastimatch convert --input $dicom_rt_file  --output-ss-img ${CONVERSION_OUTPUT_DIRECTORY}/$file.nii.gz --output-ss-list argo_test.txt --fixed $series_id_output_dir ";

print $statement . "\n";
exit;
			}
else { print "Not a valid Dicom RT file... ruh roh! \n " ;}


	}
