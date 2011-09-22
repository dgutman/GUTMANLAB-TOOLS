#!/usr/bin/perl


while(<STDIN>)
	{
	chomp;
	($SCAN_ID,$PATIENT_ID,$T1_SCAN_NUM,$T1_POST_GD_SCAN_NUM,$fourth,$fifth)=split(/,/);




	print "$SCAN_ID,$PATIENT_ID,$T1_SCAN_NUM,$T1_POST_GD_SCAN_NUM \n";

$dummy_variable = $T1_SCAN_NUM ;

$dummy_variable =~ m/(\d+)(.)/;

$scan_number = $1;
$scan_usability = $2;

print "Split out scan is $scan_number which had a usability of $scan_usability\n";

	}
