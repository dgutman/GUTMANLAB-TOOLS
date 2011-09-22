#!/usr/bin/perl

my %SUBJECT_LEVEL_TAG_TO_XML;

## some of the tags are incredibly complited/long... so I am going to try and facilitate this wiith aliases

$SUBJECT_LEVEL_TAG_TO_XML{"gender"} = "gender";
##$SUBJECT_LEVEL_TAG_TO_XML{"karnscore"} = "xnat:subjectData/fields/fields%5Bname%3Dkarnscore%5D/field"; #turns out this encoding isn't needed
$SUBJECT_LEVEL_TAG_TO_XML{"karnscore"} = "xnat:subjectData/fields/field[name=karnscore]/field";
$SUBJECT_LEVEL_TAG_TO_XML{"days_to_tumor_progression"} = "xnat:subjectData/fields/field[name=days_to_tumor_progression]/field";


if(!open(FP_LOG,">/home/dgutman/xnat_tools/xnat_updates_log_file.txt") )
	{
	print "Unable to open log file for today... probably a permissions problem...\n";exit;
	}


#This wound up being quite complicated... I had to encode the "\s as %5B...
#PUT 
#http://xnat.cci.psy.emory.edu:8080/xnat/REST/projects/NBIA_TCGA/subjects/CCIXNAT_S00001?xnat:subjectData/fields/field%5Bname%3Dbcr_surgery_barcode%5D/field=SOME_VALUE


sub xnat_update_subject_level_variable ( $PROJECT_ID, $SUBJECT_ID, $FIELD_TO_UPDATE, $NEW_VALUE)
	{
### This function will go to my XNAT instance and update a given field (like gender, age) and other base parameters
### this will also allow me to update "complex" / or custom fields... but this is a bit tricker
## as the name I need to pass is a bit more complicated..
### I will take the subject_ID since it's easier... but may want to take the universal subject id

$PROJECT_ID= $_[0];
$SUBJECT_ID = $_[1];
$FIELD_TO_UPDATE = $_[2];
$NEW_VALUE = $_[3];


if(  ! $SUBJECT_LEVEL_TAG_TO_XML{$FIELD_TO_UPDATE} ) { print "This tag is not currently supported or I don't know the Xpath...\n"; exit; }

print "This group will try and update the field $FIELD_TO_UPDATE for patient $SUBJECT_ID in $PROJECT_ID and set it to $NEW_VALUE \n";
### VALID tags include gender,
### before I do an update... I think I am also going to do a get and log all the values... seems like a great thing to do...


$GET_SUBJECT_TAG_VALUE = "/REST/projects/$PROJECT_ID/subjects/$SUBJECT_ID?" . $SUBJECT_LEVEL_TAG_TO_XML{$FIELD_TO_UPDATE} . "?format=csv";

$FULL_SYNTAX = $BASE_COMMAND . " -m GET -remote \"" . $GET_SUBJECT_TAG_VALUE ."\"";;
print "update string should be $FULL_SYNTAX \n";
$current_value_to_grad = `$FULL_SYNTAX`;

print "$current_value_to_grab is what is there now \n";
exit;

$UPDATE_SUBJECT_TAG = "/REST/projects/$PROJECT_ID/subjects/$SUBJECT_ID?" . $SUBJECT_LEVEL_TAG_TO_XML{$FIELD_TO_UPDATE} . "=$NEW_VALUE";

print $UPDATE_SUBJECT_TAG ."\n";


$FULL_SYNTAX = $BASE_COMMAND . " -m PUT -remote \"" . $UPDATE_SUBJECT_TAG ."\"";;
print "update string should be $FULL_SYNTAX \n";

#`$FULL_SYNTAX`;






	}


return(1);
