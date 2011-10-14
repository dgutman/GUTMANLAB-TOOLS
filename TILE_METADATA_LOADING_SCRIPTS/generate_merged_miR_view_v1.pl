#!/usr/bin/perl
#!/usr/bin/perl
use File::stat;
use Time::localtime;
use DBI;

connect_to_mysql_v2();



$select_db = $realdbh->prepare("truncate table miRNA_master_pivot");
$select_db->execute() || die "Could not execute SQL statement:$sqltxt";
$select_db = $realdbh->prepare("insert into  miRNA_master_pivot ( geneid,miRNA_ID ) select geneid, miRNA_ID from geneid_mirna_interaction  group by geneid,miRNA_ID order by geneid asc, miRNA_ID ASC ");
$select_db->execute() || die "Could not execute SQL statement:$sqltxt";



## going to delete the values for the curretn database first that I am eventually going to insert results into
$select_db = $realdbh->prepare("select count(*) as count, geneid,miRNA_ID,database_prediction from geneid_mirna_interaction group by geneid,miRNA_ID,database_prediction");
$select_db->execute() || die "Could not execute SQL statement:$sqltxt";

$records_found = 0;

while( @INTERACTION_LIST = $select_db->fetchrow_array() )
	{
$records_found++;

$times_found = $INTERACTION_LIST[0];
$GENE_SYMBOL = $INTERACTION_LIST[1];
$MIRNA_ID = $INTERACTION_LIST[2];
$DATABASE_PREDICTION = $INTERACTION_LIST[3];

update_pivot_interaction( $GENE_SYMBOL, $MIRNA_ID, $DATABASE_PREDICTION, $times_found ); # $k in this case is the ID of the database with the prediction

if($records_found % 5000 ==0 ) { print "Scanning $records_found so far.... \n"; }

	}


print "A total of $records_found interactions were detected for " . ${CURRENT_DATABASE_TO_SCAN}[$k] ." \n";


## BELOW WILL REMOVE DUPLLICATE TABLES..
##create table testtable2 select id, field1, field2, field3 from testtable1 group by field1,field2;

sub update_pivot_interaction( $GENE_SYMBOL, $MIRNA_ID, $k,$times_found)
	{
	$CURRENT_GENE_SYMBOL = $_[0];
	$CURRENT_MIRNA_ID = $_[1];
	$CURRENT_DATABASE_INDEX = $_[2];
	$times_found = $_[3];


$CURRENT_GENE_SYMBOL =~ s/\[//;
$CURRENT_GENE_SYMBOL =~ s/\]//;


$sql_line_insert_statement  = " update miRNA_master_pivot set db" . ($CURRENT_DATABASE_INDEX) . "_count=$times_found";

$sql_line_insert_statement .= " where geneid=" . $realdbh->quote($CURRENT_GENE_SYMBOL) ." and miRNA_ID=";
$sql_line_insert_statement .= $realdbh->quote($CURRENT_MIRNA_ID) . " ";


#print $sql_line_insert_statement . "\n";exit;

$insert_db = $realdbh->prepare($sql_line_insert_statement);
$insert_db->execute();



	}


#create table mirna_predict_pivot select 

#create table testtable2 select id, field1, field2, field3 from testtable1 group by field1,field2;




#$statement = "insert into S

 


sub connect_to_mysql_v2      
{
my $dbhost = 'sideshowbob.psy.emory.edu';
my $sqldbuser = 'mirnauser';
my $sqldbpass = 'cancersuckz!';
my $dbname='mirna';

    $realdbh =
DBI->connect("dbi:mysql:database=$dbname;host=$dbhost",
"$sqldbuser", "$sqldbpass");
    if ($DBI::errstr) {
        if ($DBI::err == 1034) {
            print "The Mysql database is currently down.\n";
        }              
        else {            
            print "Unable to connect: $DBI::errstr\n";
        }
        exit;
    }
}

