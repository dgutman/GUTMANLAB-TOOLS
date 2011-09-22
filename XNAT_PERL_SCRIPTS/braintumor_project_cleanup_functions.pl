
sub check_directory_for_duplicate_patients( $DIRECTORY_TO_CHECK )
{

$dir_to_scan = $_[0];

print "scanning $dir_to_scan \n";

@FILES_TO_CHECK = glob("${dir_to_scan}/*.nii.gz");


%DUP_PATIENT_HASH;

for($m=0;$m<=$#FILES_TO_CHECK;$m++)
	{
	
($file_part,$dir_part) = fileparse($FILES_TO_CHECK[$m]);

#print "current subject is $file_part \n"; 

$SUBJECT_ID="NONE";

if($file_part =~ m/TCGA-(\d\d)-(\d\d\d\d)/ ) { 
#		print "found patinet TCGA-$1-$2\n";
		$SUBJECT_ID="TCGA-$1-$2"; 
		}
elsif($file_part =~ m/HF(\d\d\d\d)/) { 
#			print "Found patient HF$1\n"; 
			$SUBJECT_ID="HF$1"; }
else {print "No subject Id found!! \n"; exit;}

$DUP_PATIENT_HASH{$SUBJECT_ID}++;


	}

foreach  $dup_patients ( keys %DUP_PATIENT_HASH ) 
	{

if( ($DUP_PATIENT_HASH{$dup_patients}) > 1  )  {  print $dup_patients . ";" . $DUP_PATIENT_HASH{$dup_patients} .";\n"; }
	
	
	}


}
return 1;
