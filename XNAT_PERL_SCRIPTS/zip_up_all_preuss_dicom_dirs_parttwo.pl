#!usr/bin/perl
use File::Basename;


$WORKING_DIRECTORY = "/drobo/BITC_MIRROR/preuss_data/preuss/xiaodongAnatomical/";


if(!open(FP_DCM_ERRORS,">>dicom_Error_log.txt" ))
	{
	print "unable to open log file.. \n";
	}


$ZIP_TARGET =  $WORKING_DIRECTORY . "ZIP_ARCHIVE/";


print "Should be archiving everything at $ZIP_TARGET ..\n";

if(! -d $ZIP_TARGET) { `mkdir -p $ZIP_TARGET`;}

@DIRS_TO_ZIP  = glob("${WORKING_DIRECTORY}*");

foreach $CURRENT_DIR ( @DIRS_TO_ZIP )
	{
	if( -d $CURRENT_DIR)
		{
		print $CURRENT_DIR . " for directory \n";
		($file,$dir) = fileparse($CURRENT_DIR);

		if($file =~ m/AGINGSubject(/d/d/d)_(.*)/)
			{
		print $file . " is current file for $1\n";
		
		$zip_file = $file;
		$zip_file =~ s/,//;
		$zip_file =~ s/\s+//g;
		print "Target zip is $zip_file \n";
## need to check and see if it exists and has alreayd been uploaded


$zip_path =  $ZIP_TARGET . $zip_file  .".zip";
print $zip_path . "\n";


if( -f $zip_path) { print "Zip file already exists\n";}
else {
	print "need to make zip ..\n";#
	}


#		make_zip_file($CURRENT_DIR,$zip_file);
			}	

		}

	}

sub make_zip_file($CURRENT_DIR,$zip_file)
	{
$dir_to_zip = $_[0];
$output_file = $_[1];

print "Received $dir_to_zip and $output_file \n";

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
	

	printf FP_DCM_ERRORS "DICOM EXTENSION UNREADABLE FILE;$potential_dicom_file\n";

	}


if($files_added_to_zip % 25==1) { print "$files_added_to_zip were added to $ZIP_TARGET$output_file.zip\n"; }

	}

	}


