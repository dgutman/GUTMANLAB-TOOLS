#!usr/bin/perl
use File::Basename;


$input_directory = $ARGV[0];
$CURRENT_DIR = $input_directory;



print "$CURRENT_DIR is current directory...\n";

#$CURRENT_DIR =~ s/\/$//;

	if( -d $CURRENT_DIR)
		{
		($file,$dir) = fileparse($CURRENT_DIR);
		
## Removing special characters like spaces and commas that BREAK everything
		$zip_file = $file;
		$zip_file =~ s/,//;
		$zip_file =~ s/\s+//g;
		print "Target zip is $zip_file.zip and base dir is $dir\n";
## need to check and see if it exists and has alreayd been uploaded
		make_zip_file($CURRENT_DIR,$zip_file,$dir);


	}



sub make_zip_file($CURRENT_DIR,$zip_file)
	{
$dir_to_zip = $_[0];
$output_file = $_[1];
$base_dir = $_[2];

chdir($base_dir);

print "Received $dir_to_zip and $output_file and $base_dir\n";

@FILES_TO_SCAN_FOR_DICOM_FILE = `find '$dir_to_zip' -name "*"`;

$files_added_to_zip = 0;


foreach $potential_dicom_file ( @FILES_TO_SCAN_FOR_DICOM_FILE )
	{
#	print $potential_dicom_file ;
chomp($potential_dicom_file);
$file_type = `file -b '$potential_dicom_file'`;
#print "file type is $file_type";
chomp($file_type);
if( $file_type  eq "DICOM medical imaging data" )
	{
	#	print "found a dicom file\n";
	$statement = "zip -qgu $ZIP_TARGET$output_file.zip $potential_dicom_file";
	#print $statement . "\n";
	`$statement`;
	$files_added_to_zip++;
	}
elsif( $potential_dicom_file =~ m/\.dcm$/)
	{
	$statement = "zip -qgu $ZIP_TARGET$output_file.zip $potential_dicom_file";
	#print $statement . "\n";
	`$statement`;
	$files_added_to_zip++;

	}

if($files_added_to_zip % 50==1) { print "$files_added_to_zip were added to $ZIP_TARGET$output_file.zip\n"; }

	}

	}


