#
#		<* Wrriten By Tomer Ben Harush *>
#

use DBI;
use POSIX qw(strftime);
use JSON;

my $errorFromQuery;
my $errorCounter = 0;
$datestring = strftime "%Y/%m/%d %T", localtime;
my $query = '"output_type=json',
'&query=select d.device_pk as device_id, hw.name as hw_model, d.hardware_fk as hw_model_id,'
 'd.in_service, array_to_string(array_agg( distinct concat(ip.ip_address)),\'|\') as ip_addresses,',
 've.name as manufacturer, d.name ,d.service_level,d.type,d.os_name,dc.\"<Optional Your Custom Field1>\", dc.\"<Optional Your Custom Field2>\"',
 ',dc.\"<Optional Your Custom Field3>\", dc.\"SLA\" from view_device_v1 as d ',
 'left join view_hardware_v1 hw on d.hardware_fk=hw.hardware_pk ',
 'left join view_device_custom_fields_flat_v1 dc on dc.device_fk = d.device_pk ',
 'left join view_vendor_v1 ve on hw.vendor_fk=ve.vendor_pk ',
 'left join view_ipaddress_v1 as ip on d.device_pk=ip.device_fk ',
 'group by 1,2,3,4,6,7,8,9,10,11,12,13,14"';

my $request = `curl -X POST -d $query -u "<username>:<password>" 'https://<D42 ADDRESS>/services/data/v1.0/query/' --insecure` ;

my $dataHush = decode_json($request);
if (length($request)<2000 )
{
	`snmptrap -v2c -c public<Destenation IP IF its failore> .1.3.6.1.4.1.27004.914 .1.3.6.1.4.1.27004.914.1 s "Problem with Getting Data From Device42, Response is:  $request"`;
	exit ;
}

# Desire DB for storing the Data
my %db = (
	RND_ProdDB =>{
			username => "<schema / username>",
                        password => "<password>",
                        sid      => "<DB>",
                        host     => "<DB server HOSTNAME>",
                        clrQuery => "Truncate Table <D42 table>"
		     },
# Optional for other teams			 
	DbaProdDb  =>{
			username => "<schema / username>",
                        password => "<password>",
                        sid      => "<DB>",
                        host     => "<DB server HOSTNAME>",
                        clrQuery => "Truncate Table <D42 table>"     
		}
);


for my $dbKey(keys %db)
{
	$db{$dbKey}{dbConnection} = DBI->connect("dbi:Oracle:host=$db{$dbKey}{'host'};sid=$db{$dbKey}{'sid'};port=1521", $db{$dbKey}{'username'}, $db{$dbKey}{'password'}) 
		or die `snmptrap -v2c -c public <Destenation trap on failore> .1.3.6.1.4.1.27004.914 .1.3.6.1.4.1.27004.914.1 s "Connection Error: $DBI::errstr"`;
}
$db{ShobProdDB}{dbConnection} -> prepare( $db{ShobProdDB}{'clrQuery'} ) -> execute();
$db{DbaProdDb}{dbConnection} -> prepare( $db{DbaProdDb}{'clrQuery'} ) -> execute();

for my $item(@{$dataHush}){
#	Set Up 
	$ip		= $item->{ip_addresses};
	$os             = $item->{os_name};
        $HAN            = $item->{'<Optional Your Custom Field1>'};
        $HSO            = $item->{'<Optional Your Custom Field2>'};
        $HAO            = $item->{'<Optional Your Custom Field3>'};
        $sla            = $item->{SLA};
        $name           = $item->{name};
        $manufacturer   = $item->{manufacturer};
	$service_level	= $item->{service_level};
        $type           = $item->{type};
#	take Only The First ip address
	if (index($ip, "|") != -1)
	{ 
		$ip = (split /\|/ ,$ip)[0];
	}

#	Clean diffrent unicodes
 	$os 		=~s/[^a-zA-Z0-9,\.\- ]//g;
        $HAN 		=~s/[^a-zA-Z0-9,\.\- ]//g;
        $HSO		=~s/[^a-zA-Z0-9,\.\- ]//g;
        $HAO		=~s/[^a-zA-Z0-9,\.\- ]//g;
        $sla		=~s/[^a-zA-Z0-9,\-\- ]//g;
        $name		=~s/[^a-zA-Z0-9,\-\. ]//g;
	$manufacturer 	=~s/[^a-zA-Z0-9,\.\- ]//g;
        $sla 		=~s/[^a-zA-Z0-9,\.\- ]//g;
        $type 		=~s/[^a-zA-Z0-9,\.\- ]//g;
        if ( !($name =~/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/) and (index($name,".") != -1) )
	{
		$name = (split /\./, $name)[0];
	}
	eval
	{
		$sqlQueryShob="INSERT INTO device42<table name> (HOST_NAME,OS_NAME,ENVIRONMENT_NAME,MANUFACTURER_NAME,IP_ADDRESS,APP_OWNER_NAME,SRV_OWNER_NAME,SLA,ROLE_NAME,INSERT_TIME,EQUIP_DESC) VALUES ('$name','$os','$service_level','$manufacturer','$ip','$HAO','$HSO','$sla','$HAN',TO_DATE('$datestring','YYYY/MM/DD HH24:MI:SS'),'$type')";
		$sqlQueryDba="INSERT INTO device42<other table name> (HOSTNAME,IP_ADDRESS,ENVIRONMENT,SERVER_TYPE) VALUES ('$Name','$IP','$ServiceLevel','$Type')";
		$db{ShobProdDB}{dbConnection} -> prepare( $sqlQueryShob ) -> execute();
		$db{DbaProdDb}{dbConnection} -> prepare( $sqlQueryDba ) -> execute();
	}
        or do
	{
		$errorFromQuery = $DBI::errstr;
		$errorCounter += 1;
	}
}

if ($errorCounter > 0)
{
        `snmptrap -v2c -c public <Destenation ip on failore> .1.3.6.1.4.1.27004.914 .1.3.6.1.4.1.27004.914.1 s "Number of Errors: $errorCounter , Error summery: $errorFromQuery"`;
	print $errorFromQuery;
}
for my $dbKey(keys %db)
{
	$db{$dbKey}{dbConnection}->disconnect();
}


