#!/usr/bin/perl
use File::Basename;

$statement = "find  /data2/TCGA_MIRROR/tcga-data.nci.nih.gov/tcgafiles/ftp_auth/distro_ftpusers/anonymous/tumor/ -name 'clinical_*.txt'";


#example file would be..

##/data2/TCGA_MIRROR/tcga-data.nci.nih.gov/tcgafiles/ftp_auth/distro_ftpusers/anonymous/tumor/blca/bcr/minbiotab/clin/clinical_slide_public_blca.txt

@CLINICAL_FILES = `$statement`;


for $text_file ( @CLINICAL_FILES )
	{
chomp($text_file);
print $text_file ."\n";

if($text_file =~ m/clinical_slide/) 
		{
if(!open(FP_IN,"<$text_file") )
		{
		print "unable to open $text_file .. \n";
		exit;
		}
		($file,$dir) = fileparse($text_file);
		
		$file =~ m/_(.*)\.txt/;

		print "Scanning for cancer type $1 \n";
		$cancer_base_symbol = $1;		


		$HEADER_COL = <FP_IN>;
		print $HEADER_COL . "\n";
		

	
		close(FP_IN);
		}
	}
	

