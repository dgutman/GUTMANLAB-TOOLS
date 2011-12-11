#!/usr/bin/perl


if(!open(FP_MAPPING,"shapes_original_version/shape_mappings.csv") )   {  print "Unable to open map file... \n";exit;}


 %INTENSITY_MAPPINGS;


while(<FP_MAPPING>)
	{	
	chomp;
	@COLS=split(/,/);

	$shape_name = $COLS[2];
	chomp($shape_name);
#	print $COLS[1] . ";" . $COLS[2] . "\n";
	$INTENSITY_MAPPINGS{$COLS[1]} = $shape_name;
	}


@SHAPE_IMAGES = glob("shapes_original_version/*.dx");


foreach $shape_file (@SHAPE_IMAGES)
	{

	$shape_file =~ m/\/(\d+)_QEM/;

	$shape_index = $1;
#	print $shape_file ;
#	print "Found $shape_index which maps to " . $INTENSITY_MAPPINGS{$shape_index} . "\n";

	$statement = "cp $shape_file shapes_roinames_volumeintensity/" ;
	$statement .=  $INTENSITY_MAPPINGS{$shape_index};
	$statement .=  "_${shape_index}_QEM.dx";


	print $statement ."\n";
	`$statement`;
	}
#drwxr-xr-x 2 dgutman dgutman  4096 2011-11-28 00:01 shapes_roinames_volumeintensity

