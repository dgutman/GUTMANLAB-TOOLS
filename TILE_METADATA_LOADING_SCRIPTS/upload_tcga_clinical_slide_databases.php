<?

setlocale(LC_ALL, 'en_US.UTF8'); # or any other locale that can handle multibyte characters.
/* DO MYSQL CONNECTION */        


$link = mysql_connect('localhost', 'root', 'r121919nx!');
if (!$link) {     die('Could not connect: ' . mysql_error());}
echo "Connected successfully \n";
mysql_select_db('tile_thumb_datastore', $link) or die('Could not select database.');

$statement = "find  /data2/TCGA_MIRROR/tcga-data.nci.nih.gov/tcgafiles/ftp_auth/distro_ftpusers/anonymous/tumor/ -name 'clinical_*.txt'";
#echo $statement;

$output_from_find = array();

 exec($statement, $output_from_find); 

#print_r($output_from_find);

foreach ( $output_from_find as $current_slide_file )
	{
	echo $current_slide_file  . "\n";


$working_database_name = determine_csv_header_and_create_db_if_not_exist($current_slide_file);
echo "Should be loading/updating $working_database_name \n";
# load_csv_into_sql( $FILE_TO_LOAD[$i] , $working_database_name);
#function determine_csv_header_and_create_db_if_not_exist( $current_database_file_name )
# optimize_data_table ( $working_database_name );

	}	
/* NOW ITERATE THROUGH FILES I WANT TO LOAD AND/OR CREATE DATABASES FOR */

exit;







function determine_csv_header_and_create_db_if_not_exist( $current_database_file_name )
	{
echo $current_database_file_name ;
echo "Creating database .. \n";
echo "Basename is " . basename($current_database_file_name) . "\n";
/* I also wnat to remove the extension in case it's there*/
$path_info =pathinfo($current_database_file_name);
$file_name_only = basename($current_database_file_name,'.'.$path_info['extension']);
echo "$file_name_only is file name only\n";

$cur_table_name = $file_name_only;

if( mysql_num_rows( mysql_query("SHOW TABLES LIKE '".$cur_table_name."'")))
{
echo "Found it!!\n";
}
else {
	echo "Need to create a table.. .\n";

	### GOING TO READ FIRST LINE OF CSV FILE AND CREATE DATABASE WITH THAT STRCTURE

$handle = fopen("$current_database_file_name", "r");
// Read first (headers) record only)
$data = fgetcsv($handle, 2000, "\t");
$sql= 'CREATE TABLE `' . $cur_table_name . '` (';
for($i=0;$i<count($data); $i++) {

$cur_col_name = str_replace(" ","_",$data[$i]);
$cur_col_name = str_replace("-","_",$cur_col_name);

print "Cur col name is $cur_col_name \n";
$cur_col_name .= "_col". $i;

$sql .= $cur_col_name.' VARCHAR(50), ';

			}
//The line below gets rid of the comma
$sql = substr($sql,0,strlen($sql)-2);
$sql .= ')';
echo $sql;
$result = mysql_query($sql);
echo $result;
echo mysql_error();
fclose($handle);
	}

return($cur_table_name);


	}





function optimize_data_table ( $database_name )
	{

$sql_optimize = "SELECT * FROM $database_name PROCEDURE ANALYSE(5,1024)"; 
$result = mysql_query($sql_optimize);

while( $data = mysql_fetch_assoc($result) )
	{
	print_r ($data);

	}


	}



#e:  head -n <rows+1> myfile > myfile.shorter
# me:  is that bash syntax?

function load_csv_into_sql( $csv_file_name , $database_name)
	{

echo "Should be trying to parse" . $csv_file_name . "\n\n\n";


$content = file($csv_file_name);
echo $content[0];

$sql = "LOAD DATA LOCAL INFILE '$csv_file_name' INTO TABLE `$database_name` FIELDS TERMINATED BY '\\t' LINES TERMINATED BY '\\n'";
#$sql = "LOAD DATA LOCAL INFILE '$csv_file_name' INTO TABLE `$database_name` FIELDS TERMINATED BY ',' LINES TERMINATED BY '\\n'";
#$sql = "LOAD DATA LOCAL INFILE '$csv_file_name' INTO TABLE `$database_name` FIELDS TERMINATED BY ',' ENCLOSED BY '\"' LINES TERMINATED BY '\\n'";
echo $sql;
$result = mysql_query($sql);

echo $result;
echo mysql_error();
	}


?>

