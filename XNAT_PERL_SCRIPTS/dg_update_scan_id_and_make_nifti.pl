#!/usr/bin/perl
use Text::CSV;

require('xnat_update_field_module.pl');

$connect_params = " -host http://xnat.cci.psy.emory.edu:8080/xnat -u nbia -p nbia ";

$BASE_COMMAND = " /home/dgutman/xnat_tools/XNATRestClient $connect_params ";

$current_project="DG_TESTING";

 my $csv = Text::CSV->new();

xnat_update_subject_level_variable ("NBIA_TCGA","TCGA-06-0134","karnscore","666");
exit;


#####
### SO I am going to specify a subject ID... and then get the corresponding URI...
## I am then going to get the correspidning EXPERIMENT ID for htat aubject... so first things' first... 


 update_scan_name('/REST/experiments/CCIXNAT_E00456','800','DTI_FU');
 update_scan_name('/REST/experiments/CCIXNAT_E00456','801','DTI_B0');
 update_scan_name('/REST/experiments/CCIXNAT_E00456','802','DTI_MD');


exit;

$SUBJECT_ID_TO_LOOK_FOR="TCGA_06-0130";


##LIST SUBJET EXPERIMENTS

###http://xnat.cci.psy.emory.edu:8080/xnat/REST/projects/DG_TESTING/subjects/TCGA_06-0130/experiments
$GET_SUBJECT_STRING = "\"/REST/projects/$current_project/subjects/${SUBJECT_ID_TO_LOOK_FOR}/experiments?format=csv\"";

$FULL_SYNTAX = $BASE_COMMAND . " -m GET -remote " . $GET_SUBJECT_STRING;
print $FULL_SYNTAX. "\n";
@FULL_SUBJECT_EXPERIMENT_LIST_INFO = `$FULL_SYNTAX`;

#http://xnat.cci.psy.emory.edu:8080/xnat/REST/experiments?format=html&columns=xnat:mrSessionData/ID,xnat:imageScanData/type,xnat:imageScanData/ID,ID,label,subject_ID,subject_label

#--list subjects
#GET http://xnat.cci.psy.emory.edu:8080/xnat/REST/projects/NBIA_TCGA/subjects?format=html
 
#--list experiments
#GET http://xnat.cci.psy.emory.edu:8080/xnat/REST/projects/NBIA_TCGA/subjects/CCIXNAT_S00001/experiments?format=html
 
#--indivdual session
#GET http://xnat.cci.psy.emory.edu:8080/xnat/REST/experiments/CCIXNAT_E00001?format=html
 
#-list scans
#GET http://xnat.cci.psy.emory.edu:8080/xnat/REST/experiments/CCIXNAT_E00001/scans?format=html
 
#--modify scan typePUT 
#http://xnat.cci.psy.emory.edu:8080/xnat/REST/experiments/CCIXNAT_E00001/scans/1?quality=unusable&type=SOMETHING
 




	


undef @EXPERIMENT_URI_FOR_PATIENT;


exit;

for($x=0; $x<=$#FULL_SUBJECT_EXPERIMENT_LIST_INFO; $x++)
	{
#print $FULL_SUBJECT_EXPERIMENT_LIST_INFO[$x];

$csv->parse($FULL_SUBJECT_EXPERIMENT_LIST_INFO[$x]);
my @columns = $csv->fields();
print "@columns\n";
push(@EXPERIMENT_URI_FOR_PATIENT, $columns[7]);
	}


print "Now listing the experiment URI's for the patient... this is really only a single column of values...\n";
for($x=1;$x<=$#EXPERIMENT_URI_FOR_PATIENT;$x++)
	{
print $EXPERIMENT_URI_FOR_PATIENT[$x] . "\n";

### now that I have the URI... I am going to query the server again...
$GET_SCAN_STRING = $EXPERIMENT_URI_FOR_PATIENT[$x] . "/scans?format=csv";
print $GET_SCAN_STRING . "\n";


$FULL_SYNTAX = $BASE_COMMAND . " -m GET -remote " . $GET_SUBJECT_STRING;
print $FULL_SYNTAX. "\n";
@FULL_SCAN_LIST_INFO = `$FULL_SYNTAX`;
	for($y=0;$y<=$#FULL_SCAN_LIST_INFO;$y++)
		{
	$csv->parse($FULL_SCAN_LIST_INFO[$x]);
	my @columns = $csv->fields();
	print "@columns\n";
	### I am going to try and pull the data for a dicom session using the rest command...
	
###-user_session AAAABBBBCCCC00001111222233334444	

###$ /home/dgutman/usr/bin/mcverter -o TCGA-06-0130/NIFTI_TEST -d -v -n -f nifti CRAP0/*.dcm




		}


	}






###ernode1 CRAP0]$ unzip -j bigmama   this is how i will do it


#rnode1 xnat_tools]$ 
#[dgutman@trauma-computernode1 xnat_tools]$ 
#[dgutman@trauma-computernode1 xnat_tools]$ ./XNATRestClient -host "http://xnat.cci.psy.emory.edu:8080/xnat" -u nbia -p nbia -m GET -remote 
#"/REST/experiments/CCIXNAT_E0045
#6/scans/801/files?format=zip"  > bigmama
#[dgutman@trauma-computernode1 xnat_tools]$ unzi pbi
#[dgutman@trauma-computernode1 xnat_too


my $DICOM_CACHE = "/IMAGING_SCRATCH/TCGA_DICOM_CACHE";


###### NEXT THING I AM GOING TO DO IS FOR A GIVEN EXPERIMENT... LIST ALL THE SCAN INFO...

sub pull_dicom_session( $EXPERIMENT_ROOT_URI, $SCAN_ID )
	{
### This will attempt to pull all of the dicom files associated with a given scan id.. i.e. "scan701 for experiment1234")
### note in this scenario I am pulling my the NUMBER.. not by the name... I may actually want to try and pull by name.. as it may make more sense
### for now to make my life easier ill just pull by the scan...

$EXPERIMENT_URI = $_[0];
$SCAN_ID = $_[1];


### TRYING TO DO A PUT
#http://xnat.cci.psy.emory.edu:8080/xnat/REST/experiments/CCIXNAT_E00001/scans/1?quality=unusable&type=SOMETHING

### UPDATE SCANTYPE given a scan id..
### TRYING TO DO A PUT
#http://xnat.cci.psy.emory.edu:8080/xnat/REST/experiments/CCIXNAT_E00001/scans/1?quality=unusable&type=SOMETHING




	}



sub update_scan_name ( $EXPERIMENT_ROOT_URI, $SCAN_ID, $NEW_NAME )
	{
### This will attempt to pull all of the dicom files associated with a given scan id.. i.e. "scan701 for experiment1234")
### note in this scenario I am pulling my the NUMBER.. not by the name... I may actually want to try and pull by name.. as it may make more sense
### for now to make my life easier ill just pull by the scan...

$EXPERIMENT_URI = $_[0];
$SCAN_ID = $_[1];
$NEW_NAME = $_[2];
$QUALITY = "unusable";

print "Received $EXPERIMENT_URI for $SCAN_ID and want to make it $NEW_NAME \n";



$UPDATE_SCAN_ID = "$EXPERIMENT_URI/scans/$SCAN_ID?quality=$QUALITY&type=$NEW_NAME";

$FULL_SYNTAX = $BASE_COMMAND . " -m PUT -remote \"" . $UPDATE_SCAN_ID ."\"";;

print "update string should be $FULL_SYNTAX \n";

`$FULL_SYNTAX`;

### TRYING TO DO A PUT
#http://xnat.cci.psy.emory.edu:8080/xnat/REST/experiments/CCIXNAT_E00001/scans/1?quality=unusable&type=SOMETHING

### UPDATE SCANTYPE given a scan id..
### TRYING TO DO A PUT
#http://xnat.cci.psy.emory.edu:8080/xnat/REST/experiments/CCIXNAT_E00001/scans/1?quality=unusable&type=SOMETHING




	}


exit;

###

### EXAMPLE COMMANDS:::
## THIS WILL GET ALL THE SUBJECTS FOR THE NBIA_TCGA PROJECT...
$REST_PART = "\"/REST/projects/$current_project/subjects?format=csv\"";
$FULL_SYNTAX = $BASE_COMMAND . " -m GET -remote " . $REST_PART;
@FULL_SUBJECT_LIST_INFO = `$FULL_SYNTAX`;
print @FULL_SUBJECT_LIST_INFO;
exit;
###  I NNOW HAVE AN ARRAY LISTING the csv output from the above command as a line


#print $FULL_SUBJECT_LIST_INFO;
for($i=1;$i<=$#FULL_SUBJECT_LIST_INFO;$i++)
	{
	$line = $FULL_SUBJECT_LIST_INFO[$i];
	chomp($line);
	$line =~ s/\"//g;

	($ID,$project,$label,$insert_date,$insert_user,$URI)  = split(/,/,$line);
	#print "$i;$ID,$label,$URI\n";
#	print $line . "\n";
	### NOW FOR EACH PATIENT/LABEL I WANT TO GET SOME MORE INFO... LIKE THE SCAN IDS or more importantly.. the LABELS for the individuals..
	
	##  THIS STATEMENT WILL GET ALL OF THE INIDIVUDAL SCAN SESSIONS FOR THAT PATIENT.. WOO HOO..
	$new_rest_statement = "\"/REST/projects/$current_project/subjects/$label/experiments?format=csv\"";
	$FULL_SYNTAX = $BASE_COMMAND . " -m GET -remote ". $new_rest_statement;

#	print $FULL_SYNTAX  ."\n";
	@EXPERIMENT_STATUS = `$FULL_SYNTAX`;
if($#EXPERIMENT_STATUS == 0 ) { print "We ain't found shit\n";}
elsif ($#EXPERIMENT_STATUS > 0 )	
			{
			#print "YEAH!!! THIS SUBJECT ACTUALLY HAS EXPERIMENTS... IVE NEVER BEEN MORE EXCITED!!!!! $label!!! \n";

			for($j=0;$j<=$#EXPERIMENT_STATUS;$j++)
				{
				$EXPERIMENT_STATUS[$j] =~ s/\"//g;
				$other_line = $EXPERIMENT_STATUS[$j];
				chomp($other_line);
				($subjectasseor,$ID_2,$project_2,$date,$type,$label_2, $ins_date, $URI ) = split(/,/,$other_line);
				print "$j;$ID_2;$label_2;$URI\n";



				}

			}

			$new_new_rest_statement = "\"/REST/projects/$current_project/subjects/$label/experiments/$label_2/scans?format=csv\"";
			$FULL_SYNTAX = $BASE_COMMAND . " -m GET -remote ". $new_new_rest_statement;
			@sessions = `$label_2`;
			print @sessions
		
#	system($FULL_SYNTAX);

#	exit;

	}

