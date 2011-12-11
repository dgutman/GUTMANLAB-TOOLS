<?

setlocale(LC_ALL, 'en_US.UTF8'); # or any other locale that can handle multibyte characters.
/* DO MYSQL CONNECTION */        


require_once('/includes/cerebro_tagger_login_info.php');

#mysql_select_db('centroid_nuclei_db', $link) or die('Could not select database.');



$sql = "select count(*) as count, tcluster_label as cluster_label from features_list group by tcluster_label";
echo $sql;
$result = mysql_query($sql);

while($data = mysql_fetch_assoc($result) )
	{
#	echo $data["count"] . ";"  .$data["cluster_label"] . "\n";

	$slide_statistics_query = "select distinct slide from features_list where tcluster_label='". $data["cluster_label"] . "'" ;
	echo $slide_statistics_query ;
	$slide_result = mysql_query($slide_statistics_query);


	$distinct_slides = 0;

		$unique_patients = array();

	while($slide_data = mysql_fetch_assoc($slide_result) )
		{
#		print_r($slide_data) . "\n";
		
		$patient_id = $slide_data["slide"];
	
		 preg_match("/TCGA-(\d+)-(\d+)-/",$patient_id,$matches);

#		echo "\ntcga should be " . $matches[0]  . "-" . $matches[1] . " and also" . $matches[2] . "\n";
		$patient_id = "TCGA-" . $matches[1] . "-" . $matches[2];
	
		$unique_patients["$patient_id"]=1;
		$distinct_slides++;
		}
	echo "array contained " . count($unique_patients) . " elements ... \n";
	print_r($unique_patients);
	$insert_statement = "replace into cluster_statistics (clustering_instance_id,cluster_label,count,unique_images,unique_patients) Values('1', ";
	$insert_statement .= "'" . $data["cluster_label"] . "','" . $data["count"] . "','$distinct_slides','" . count($unique_patients) . "')";   
	echo $insert_statement;
	$insert_query = mysql_query($insert_statement);

	}

exit;


