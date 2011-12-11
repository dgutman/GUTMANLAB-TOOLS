<?
require_once('JSON.php');
setlocale(LC_ALL, 'en_US.UTF8'); # or any other locale that can handle multibyte characters.
/* DO MYSQL CONNECTION */        


$link = mysql_connect('localhost', 'root', 'r121919nx!');
if (!$link) {     die('Could not connect: ' . mysql_error());}
echo "Connected successfully \n";
mysql_select_db('tile_thumb_datastore', $link) or die('Could not select database.');


$root_cancer_type = "gbm";

$database_name = "clinical_slide_public_${root_cancer_type}";

echo "should be queryind $database_name ";



$sql = "select * from $database_name where bcr_sample_barcode_col0 like 'TCGA-02-0001%'";
echo $sql;
$function_result = mysql_query($sql);

#echo $result;
echo mysql_error();

if (!$function_result) {    die('Invalid query: ' . mysql_error());}

$returnArray = array();

while( $database_keys = mysql_fetch_assoc($function_result) )
        {
 array_push($returnArray, $database_keys);
print_r($database_keys) . "\n";
        }

$json = new Services_JSON();
#echo $json->encode($returnArray);

$big_ass_string = $json->encode($returnArray);

$big_ass_string = preg_replace("/_col(\d+)/","",$big_ass_string);

echo $big_ass_string;

 mysql_close();


