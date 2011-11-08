#!/usr/bin/perl
#!/usr/bin/perl
use File::stat;
use Time::localtime;
use DBI;

connect_to_mysql_v2();


if(!open(FP_IN,"<REFSEQ-SYMBOL-ENTREZ.txt") )
	{
	print "unable to open REFSEQ to GENE ID FILE... \n"; exit;
	}

%REFSEQ_TO_GENEID;

while(<FP_IN>)
	{
	chomp;
	@COLS = split(/\s+/);
	$REFSEQ_TO_GENEID{$COLS[0]} = $COLS[1];
	}


$CURRENT_DATABASE_TO_SCAN[1] = "miRecords_version3";
$CURRENT_DATABASE_SELECT_QUERY[1] = "select Target_gene_name_col3, miRNA_mature_ID_col7, Target_gene_Refseq_acc_col4  from ";
$CURRENT_DATABASE_SELECT_QUERY[1] .= $CURRENT_DATABASE_TO_SCAN[1] . " where miRNA_species_col6='Homo Sapiens' and  Target_gene_species_common_col2='human'";

$CURRENT_DATABASE_TO_SCAN[2] = "miRanda_human_predictions_S_C_aug2010";
$CURRENT_DATABASE_SELECT_QUERY[2] = "select gene_symbol, mirna_name, ext_transcript_id  from ";
$CURRENT_DATABASE_SELECT_QUERY[2] .= $CURRENT_DATABASE_TO_SCAN[2] ;


$CURRENT_DATABASE_TO_SCAN[3] = "PITA_targets_hg18_3_15_ALL";
$CURRENT_DATABASE_SELECT_QUERY[3] = "select Name, microRNA, Refseq from ";
$CURRENT_DATABASE_SELECT_QUERY[3] .= $CURRENT_DATABASE_TO_SCAN[3] ;


$CURRENT_DATABASE_TO_SCAN[4] = "PITA_targets_hg18_0_0_ALL";
$CURRENT_DATABASE_SELECT_QUERY[4] = "select Name, microRNA, Refseq  from  ";
$CURRENT_DATABASE_SELECT_QUERY[4] .= $CURRENT_DATABASE_TO_SCAN[4] ;



$CURRENT_DATABASE_TO_SCAN[5] = "Targetscan_Predicted_Targets_Info";
$CURRENT_DATABASE_SELECT_QUERY[5] = "select Gene_Symbol_col2, miR_Family_col0, Seed_match_col8 from  ";
$CURRENT_DATABASE_SELECT_QUERY[5] .= $CURRENT_DATABASE_TO_SCAN[5] . " where species_ID_col3='9606' ";


$CURRENT_DATABASE_TO_SCAN[6] = "Targetscan_Summary_Counts";
$CURRENT_DATABASE_SELECT_QUERY[6] = "select Gene_Symbol_col1, Representative_miRNA_col12,Transcript_ID_col0 from  ";
$CURRENT_DATABASE_SELECT_QUERY[6] .= $CURRENT_DATABASE_TO_SCAN[6] . " where species_ID_col3='9606' ";


$CURRENT_DATABASE_TO_SCAN[7] = "TarBase_V50";
$CURRENT_DATABASE_SELECT_QUERY[7] = "select Gene_col7, miRNA_col5 Ensembl_col9 from  ";
$CURRENT_DATABASE_SELECT_QUERY[7] .= $CURRENT_DATABASE_TO_SCAN[7] . " where Organism_col4='Human' ";


$CURRENT_DATABASE_TO_SCAN[8] = "PICTAR-hg17";
$CURRENT_DATABASE_SELECT_QUERY[8] = "select name_col4  from  ";
$CURRENT_DATABASE_SELECT_QUERY[8] .= "`" . $CURRENT_DATABASE_TO_SCAN[8] . "`";




### 9606 is the human tag
#Trandscript_ID_col0,Gene_Symbol_col1,Representative_miRNA_col12
#TargetScan_Summary_counts
#Targetscan_Predicted_TArget_Info  --- i need to filter based on the Species_ID_Col3



#for($k=1;$k<=$#CURRENT_DATABASE_TO_SCAN;$k++)
for($k=1;$k<=1;$k++)
	{
print "Currently trying to extract data from " . $CURRENT_DATABASE_TO_SCAN[$k] ." \n";

print "Query is " . $CURRENT_DATABASE_SELECT_QUERY[$k] . "\n";


## going to delete the values for the curretn database first that I am eventually going to insert results into
$select_db = $realdbh->prepare("delete from geneid_mirna_interaction where database_prediction=$k");
$select_db->execute() || die "Could not execute SQL statement:$sqltxt";


$select_db = $realdbh->prepare($CURRENT_DATABASE_SELECT_QUERY[$k]) || die "Could not prepare SQL statement:${CURRENT_DATABASE_TO_SCAN}[$k]"; ;
$select_db->execute() || die "Could not execute SQL statement:" . $CURRENT_DATABASE_SELECT_QUERY[$k] ;



$records_found = 0;
while( @INTERACTION_LIST = $select_db->fetchrow_array() )
	{

$records_found++;


$GENE_SYMBOL = $INTERACTION_LIST[0];
$MIRNA_ID = $INTERACTION_LIST[1];
$REFSEQ_ID = $INTERACTION_LIST[2];


### also need to do some shimming... for the miRNA's for database 7 I need to add the hsa- tag...
if( $k == 7 ) { $MIRNA_ID = "hsa-" . $MIRNA_ID; }

## for $k=1 i need to remove the [ ]
if( $k == 1 ) { $MIRNA_ID =~ s/\[//;    $MIRNA_ID =~ s/\]//;    	}


#print "MIRNA should now be $MIRNA_ID \n";

if($k == 8 )
	{
($REFSEQ_ID,$MIRNA_ID) = split(":",$GENE_SYMBOL);
#print "Gene symbol is now $GENE_SYMBOL and mirna is $MIRNA_ID";
	### for this one I need to do a special lookup to map REFSEQ_ID to geneid...
$GENE_SYMBOL =  $REFSEQ_TO_GENEID{$REFSEQ_ID};
if($GENE_SYMBOL eq "") { $GENE_SYMBOL = "NOREFSEQ"; }

	}



insert_interaction( $GENE_SYMBOL, $REFSEQ_ID, $MIRNA_ID, $k); # $k in this case is the ID of the database with the prediction

	}
print "A total of $records_found interactions were detected for " . ${CURRENT_DATABASE_TO_SCAN}[$k] ." \n";



	}

## BELOW WILL REMOVE DUPLLICATE TABLES..
##create table testtable2 select id, field1, field2, field3 from testtable1 group by field1,field2;

sub insert_interaction( $GENE_SYMBOL, $MIRNA_ID, $k)
	{
	$CURRENT_GENE_SYMBOL = $_[0];
	$CURRENT_REFSEQ_ID = $_[1];	
	$CURRENT_MIRNA_ID = $_[2];
	$CURRENT_DATABASE_INDEX = $_[3];


$sql_line_insert_statement  = " insert into geneid_mirna_interaction (geneid,refseq_id,miRNA_ID, database_prediction) VALUES (";
$sql_line_insert_statement .= $realdbh->quote($CURRENT_GENE_SYMBOL) . "," . $realdbh->quote($CURRENT_REFSEQ_ID) . ", " . $realdbh->quote($CURRENT_MIRNA_ID) . "," . $realdbh->quote($CURRENT_DATABASE_INDEX)  . " ) "  ;
#print $sql_line_insert_statement . "\n";exit;

$insert_db = $realdbh->prepare($sql_line_insert_statement);
$insert_db->execute();

	}

 


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

