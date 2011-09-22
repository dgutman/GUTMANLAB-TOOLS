#!/usr/bin/perl
use Text::CSV;

require('xnat_update_field_module.pl');

$connect_params = " -host http://xnat.cci.psy.emory.edu:8080/xnat -u nbia -p nbia ";

$BASE_COMMAND = " /home/dgutman/xnat_tools/XNATRestClient $connect_params ";

$current_project="DG_TESTING";

 my $csv = Text::CSV->new();


 update_experiment_info('/REST/experiments/CCIXNAT_E00456','visit_id','PREOP');


exit;
xnat_update_subject_level_variable ("NBIA_TCGA","TCGA-06-0134","karnscore","666");
xnat_update_experiment_level_variable ("NBIA_TCGA","TCGA-06-0134","visit_it","666");
exit;


#####
### SO I am going to specify a subject ID... and then get the corresponding URI...
## I am then going to get the correspidning EXPERIMENT ID for htat aubject... so first things' first... 


 update_scan_name('/REST/experiments/CCIXNAT_E00456','800','DTI_FU');
 update_scan_name('/REST/experiments/CCIXNAT_E00456','801','DTI_B0');
 update_scan_name('/REST/experiments/CCIXNAT_E00456','802','DTI_MD');


exit;

exit;

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
sub update_experiment_info ( $EXPERIMENT_ROOT_URI, $field_ID, $NEW_NAME )
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
exit;
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

