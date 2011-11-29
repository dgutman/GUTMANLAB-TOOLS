#!/usr/bin/perl
use File::Basename;

$base_input_directory =
"/home/dgutman/Dropbox/GIT_ROOT/PIPELINE_ITERATIONS/PIPELINE_DATA_ANALYSIS_SCRIPTS/SAMPLE_DATA/left_hippocamp_11_26";


@SHAPE_FILES_TO_PROCESS = glob("${base_input_directory}/*/*.dx");


foreach $shape_file ( @SHAPE_FILES_TO_PROCESS) 
	{
	chomp($shape_file);
	($file,$dir ) = fileparse($shape_file);
	
	
	$file =~ m/(.*)_(.*)_colormap.dx/;
	$parameter_name = $1;
	$statistic_type = $2;
	
	if( $dir =~ m/radialdistance/) { $feature_type = "radialdistance"; }
	elsif($dir =~ m/displacementfeature/) { $feature_type = "displacementfeature";}
	
	print $file. " has $parameter_name and $statistic_type for $feature_type ";
	
	analyze_shape_file($shape_file,$statistic_type);
	
	}

sub analyze_shape_file( $input_shape_file ) 
	{
	$input_shape_file = $_[0];
	$stat_type = $_[1];	

#	print "Analyzing $input_shape_file ... \n";
	
	$input_file_removed_root = $input_shape_file;
	$input_file_removed_root =~ s/\Q$base_input_directory\E//;


#	print "$input_shape_file is now the base.. \n";

	
	if(!open(FP_IN,"<$input_shape_file") )
		{
		print "Unable to open $input_shape_file .... \n"; exit; 
		}
		
		
		$lines_found = 0;
	
	$OBJECT_3_START = 0;
	$OBJECT_3_END = 0;
	
	$significant_values = 0;
	
	while(<FP_IN>)
		{
		chomp;
		$line = $_;
		$lines_found++;
				
		if($OBJECT_3_START && ! $OBJECT_3_END)	
			{
			$vertex_p_value = $_;
			if($vertex_p_value < 0.05 ) {   $significant_values++; }
 			$vertex_index++;
			}
		
		if( $_ =~ m/object 3 class array type float rank 1/) 
			{ 
		#	print "Found results object .. starting to collect data\n"; 
				$OBJECT_3_START = 1;
			}
		if( $OBJECT_3_START && ($_ =~ m/attribute/) ) 
		{ $OBJECT_3_END = 1; 
	#	print "Found the end... and there were $significant_values significant values \n";
		print ":$significant_values significant values \n";
		 last;} 

		## object 3 seems to contain the stats values... this is what I want to capture..
##		object 3 class array type float rank 1 items 16384 shape 1 data follows

		
		}
	
	
	
	close(FP_IN);
	
	}
