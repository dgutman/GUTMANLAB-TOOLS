use File::Basename;

$FILE_TYPE = "AXIAL_T1_POST_GD";
$FILE_TYPE = "AXIAL_T2_FLAIR";

@MASK_FILES_TO_PARSE = glob("V:\\TCGA_DICOM_CACHE\\TCGA_DATA\\MASK_EXPORT\\*\\$FILE_TYPE\\*.dcm");


$make_mask_executable = "V:\\TCGA_DICOM_CACHE\\TCGA_DATA\\MASK_EXPORT\\MakeMask.exe";


$mask_export_directory = "V:\\TCGA_DICOM_CACHE\\TCGA_DATA\\MASK_EXPORT\\\TEMP_OUTPUT_BEFORE_RENAMING\\$FILE_TYPE\\";

foreach $dicom_rt_mask ( @MASK_FILES_TO_PARSE)
	{
#	print $dicom_rt_mask . "\n";
	
	
	($file,$dir) = fileparse($dicom_rt_mask);
#	print "Data is in $dir \n";
	## also could do =~  m/DJ|ARGO|TYLER/
		
	## Going to check for Valid masks which contain either TYLER or DJ
	if( $file =~ m/DJ/ || $file =~ m/TYLER/ || $file =~ m/ARGO/ || $file =~ m/TARUN/) 
		{
		print "Found valid mask for argo post mask for $file in $dir\n";
		
		if($dir =~ m/TCGA-(\d\d)-(\d\d\d\d)/ ) { $patient_id = "TCGA-$1-$2";}
		elsif( $dir =~ m/HF(\d\d\d\d)/ ) { $patient_id = "HF$1";}
		else { print "Patient id was not found\n"; exit;}
		
		print "Found patient id is $patient_id \n";
		

			## TO AVOID REGENERATING THESE... I FIRST WANT TO CHECK IF THE OUTPUT DIRECTORY EXISTS
		
	$LOOK_FOR_MASK = "V:\\TCGA_DICOM_CACHE\\TCGA_DATA\\MASK_EXPORT\\TEMP_OUTPUT_BEFORE_RENAMING\\$FILE_TYPE\\$patient_id\\";
		## the mask will likely be generated in the patient_id directory... and should also have the Filename apended to it
		
		
		$target_dir = $file ;
		$target_dir =~ s/\.dcm//;
		print "Likely file target is $file which should be $target_dir\n"; 
		##in the case of the TYLER images... it may be Tumor_TA*
		$full_target_dir = $LOOK_FOR_MASK . $target_dir;
		print "full target dir should be $full_target_dir \n"; 
		if( ! target_data_already_made( $full_target_dir ) ) 
		{
		if ( $dir_with_mri_images = look_for_dicom_image_dir($dir) ) 
			{
			$PATIENT_EXPORT_DIR = $mask_export_directory . $patient_id;
		
			if( ! -d $PATIENT_EXPORT_DIR ) {
			print "Trying to generate $PATIENT_EXPORT_DIR \n";
			`mkdir $PATIENT_EXPORT_DIR`;
											}
		chdir($PATIENT_EXPORT_DIR);
		$statement = "$make_mask_executable $dir_with_mri_images $dicom_rt_mask ";
		print $statement . "\n";
		`$statement`;
			}
		
		}
	
		}
	
	}
	
	sub target_data_already_made( $input_directory ) 
		{
		
		$input_dir = $_[0];
		
			print "I am looknig for $input_dir \n";
		
		#@DIRS_TO_CHECK = glob("${input_dir}1.*");
		
		#foreach $dirs_to_scan (@DIRS_TO_CHECK)
		#	{
		#	if ( -d $dirs_to_scan ) { print "Found $dirs_to_scan \n"; }
		#	return($dirs_to_scan);
		#	}
		
			if($input_dir =~ m/TYLER/) { $input_dir =~ s/TYLER_MASKS/Tumor_TA_C/;}
		
		if( -d $input_dir)
			{
			print "Found $input_dir !!! \n"; return(1);
			}
		else { print "Did not find dir for $input_dir \n"; return(0); }
		
		
		return(0);
		
			
		
		
		}
		
	
	sub look_for_dicom_image_dir( $input_directory)
		{
		### in order to generate the masks.. I need to point to the exported native image as well (like the axial pre gd image..)
		## this usually is a bunch of numbers like 1.2940832 or 2.5894385943
		
		$input_dir = $_[0];
		
		@DIRS_TO_CHECK = glob("${input_dir}1.*");
		push(@DIRS_TO_CHECK,glob("${input_dir}2.*") );

		
		foreach $dirs_to_scan (@DIRS_TO_CHECK)
			{
			if ( -d $dirs_to_scan ) { print "Found $dirs_to_scan \n"; }
			return($dirs_to_scan);
			}
		
		return(0);
		
		}
