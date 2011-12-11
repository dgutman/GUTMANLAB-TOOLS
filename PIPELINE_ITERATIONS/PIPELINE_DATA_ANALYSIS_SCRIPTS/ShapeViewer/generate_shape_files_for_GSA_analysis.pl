#!/usr/bin/perl
use File::Basename;


my %SCENE_INDEX_TO_STRUCTURE_MAP;
get_scene_roi_information();


$COLOR_MAP[0]=1;  #blue alpha of 1
$COLOR_MAP[1]=2;
$COLOR_MAP[2]=3;
$COLOR_MAP[3]=4;



if(!open(FP_MAPPING,"shapes_original_version/shape_mappings.csv") )   {  print "Unable to open map file... \n";exit;}


 %INTENSITY_MAPPINGS;
	while(<FP_MAPPING>)
	{	
	chomp;
	@COLS=split(/,/);
	$shape_name = $COLS[2];
	chomp($shape_name);
	$INTENSITY_MAPPINGS{$COLS[1]} = $shape_name;
	}


if(!open(FP_INPUT,"INPUT_FILES/PTSD_56_roi_initial_analysis.txt") )   {  print "Unable to open map file... \n";exit;}


##################### THIS IS READING IN THE INPUT FILE WHICH IS POORLY FORMATTEd.. BUT ITS BASICALLY A 2D ARRAY

my @matrix; #declare 2d array
my $i=0; #counter
while(<FP_INPUT>)
{
chomp $_;
my @row=split(/\s+/,$_);
for ($j=0; $j<@row;$j++)
{
$matrix[$i][$j]=$row[$j]; #fill 2d matrix with data
}
$i++;
}

#################################################

#print @matrix;

$lines_read =0;
@array_2d = @matrix;

for($i=1;$i<=5;$i++)
	{
	print "Analyzing features for: " . $matrix[$i][0] . "\n";
	undef %SHAPES_TO_COLOR;

	$current_structure_list = "";

	for($k=1;$k<=56;$k++)
		{
		$current_value = $matrix[$i][$k];
		if($current_value <= 0.05 ) { 
							print "$current_value was found for $matrix[0][$k] ... need to modify strucutre in output\n"; 
						$structure_list .= $matrix[0][$k] . "," ;
							}
		}	
	print "\n";

	print "Passing structure list which contains $structure_list \n";

generate_scene_for_analysis( $matrix[$i][0],$structure_list  );
a
	}



sub generate_scene_for_analysis($output_file_name,$rois_to_recolor  )
	{

$output_file_name = $_[0];
$rois_to_recolor = $_[1];

undef %ROI_HASH;

@ROI_LIST = split(/,/,$rois_to_recolor);

foreach $roi ( @ROI_LIST)	{	$ROI_HASH{$roi} = 1;	}

### $rois_to_recolor gets passed

if(!open(FP_BASE,"<entire_3dbrain_render_greyed.scene"))	{ print "Unable to open base file... \n";	}
if(!open(FP_SCENE_OUT,">OUTPUT_RESULTS/${output_file_name}_recolord_scene.scene"))	{ print "Unable to open some scene file... \n";	}

	while(<FP_BASE>)
		{
	chomp;
	printf FP_SCENE_OUT  $_ ."\n";
	$current_line = $_;
        if( $_ =~ m/<shape index=\"(\d+)\" griducf=\"false\"/)
		{
		print "At index $1 which should be shape ... "  ;
		$current_shape_index = $1;
		print $SCENE_INDEX_TO_STRUCTURE_MAP{$current_shape_index}  ." \n";
		if($ROI_HASH{  $SCENE_INDEX_TO_STRUCTURE_MAP{$current_shape_index} } ) { print "FOUND ONE!! \n"; }

		}		
	else { printf FP_SCENE_OUT $_ . "\n"; 		}
	
		}

close(FP_BASE);
close(FP_SCENE_OUT);
	}




sub get_scene_roi_information(  )
	{

## since the index/order of the various shapes may vary... this will generate an map of index_id--> file name so I can then do substitiions later

### $rois_to_recolor gets passed

### this will generate a hash of all the index/name pairs I need for doing the color coding...

if(!open(FP_BASE,"<entire_3dbrain_render_greyed.scene"))	{ print "Unable to open base file... \n";	}

	while(<FP_BASE>)
		{
	chomp;
#	print $_ ."\n";

	if( $_ =~ m/<shape index=\"(\d+)\" griducf=\"false\"/)
		{
#		print "Index $1 was foind... \n";
		$current_roi_index = $1;
		$next_line = <FP_BASE>;
#		print "info should be embedded in $next_line \n";
#		print $next_line ."\n";

		if( 		$next_line =~ m/\\([^\\]*)_(\d+)_QEM\.dx\"/ )
		{		
#		print "$file was found.. $1 $2  \n"; 
		$SCENE_INDEX_TO_STRUCTURE_MAP{$current_roi_index} = $1;
		}

		}

		}


close(FP_BASE);
close(FP_SCENE_OUT);
	}



