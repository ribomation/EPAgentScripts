#!/usr/bin/perl -w
#
#	apache-status.pl
#	Provides EPA metrics for Apache HTTPd worker stats
#	usage: ./apache-status.pl --host webhost 
#
#	October 26, 2001
#	Jens Riboe, jens.riboe AT ribomation.com
#	Ribomation AB, http://www.ribomation.com/
#
use FindBin;
use lib ("$FindBin::Bin", "$FindBin::Bin/../lib/perl");
use Getopt::Long;
use Metric;

##################################################################
# Options
# ----------------
my $usage = 'apache-status.pl options...
    --prefix=string      Metric name prefix, such as "Apache Status|Workers". Default "Apache Status"
    --host=string        Host or IP of Apache HTTPd. Default "localhost"
    --port=int           Port of HTTPd, unless 80. Default "80"
    --https              Enable HTTPS access. Default disabled.
    --debug              Enable DEBUG printouts. Default disabled.
';

my $exe    = '/usr/bin/curl';
my $prefix = 'Apache Status';
my $host   = 'localhost';
my $port   = -1;
my $https  = 0;
my $debug  = 0;
my $help   = 0;
GetOptions(
	'prefix=s' => \$prefix,
	'host=s'   => \$host,
	'port=i'   => \$port,
	'https'    => \$https,
	'debug'    => \$debug,
	'help|?'   => \$help,
);
if ($help) {print $usage; exit 0;}

##################################################################
# Verification
# ----------------
{
	open CURL, "$exe --version|" or die "Failed to open pipe to '$exe':$!\n";
	my @lines = <CURL>;
	close CURL;
	chomp @lines;
	die "Cannot find '$exe'. Ensure it's installed and executable.\n" unless $lines[0] =~ /^curl [.\d]+/;
}
$prefix = stripQuotes($prefix);
$port = 80  unless $https;
$port = 443 if $https;

##################################################################
# Main
# ----------------
my $fields = collect( run("--silent ".($https ? '--insecure https' : 'http')."://$host:$port/server-status?auto") );
if ($debug) {
    print STDERR "---FIELDS:\n";
    foreach my $key (sort keys %$fields) {
        print STDERR "$key = [" . $fields->{$key} . "]\n";
    }
    print STDERR "----END FIELDS\n";
}

my @metrics = ();
if (defined($fields->{BusyWorkers}) && defined($fields->{IdleWorkers})) {
    my $busy = $fields->{BusyWorkers};
    my $idle = $fields->{IdleWorkers};

    addMetric('Workers:Busy'     , $busy);
    addMetric('Workers:Idle'     , $idle);
    addMetric('Workers:Max'      , ($busy + $idle));
    addMetric('Workers:Usage (%)', percent($busy, $busy + $idle));	
}

if (defined($fields->{BytesPerReq}) && defined($fields->{BytesPerSec}) && defined($fields->{ReqPerSec})) {
    my $bytesPerReq    =  $fields->{BytesPerReq};
    my $bytesPerSec    =  $fields->{BytesPerSec};
    my $requestsPerSec =  $fields->{ReqPerSec};

    addMetric('Requests:Bytes / request' , int($bytesPerReq));
    addMetric('Requests:Bytes / second'  , int($bytesPerSec));
    addMetric('Requests:Requests / second', int($requestsPerSec));
}

if (defined($fields->{Scoreboard})) {
    my $scoreboard = $fields->{Scoreboard};
    addMetric('Scoreboard:Waiting'         , $scoreboard =~ tr/_//);
    addMetric('Scoreboard:Starting'        , $scoreboard =~ tr/S//);
    addMetric('Scoreboard:Reading Request' , $scoreboard =~ tr/R//);
    addMetric('Scoreboard:Sending Reply'   , $scoreboard =~ tr/W//);
    addMetric('Scoreboard:Keepalive'       , $scoreboard =~ tr/K//);
    addMetric('Scoreboard:DNS Lookup'      , $scoreboard =~ tr/D//);
    addMetric('Scoreboard:Closing'         , $scoreboard =~ tr/C//);
    addMetric('Scoreboard:Logging'         , $scoreboard =~ tr/L//);
    addMetric('Scoreboard:Finishing'       , $scoreboard =~ tr/G//);
    addMetric('Scoreboard:Idle'            , $scoreboard =~ tr/I//);
    addMetric('Scoreboard:Empty Slot'      , $scoreboard =~ tr/.//);
}

foreach my $m (@metrics) {
    print STDERR $m->asXML, "\n" if $debug;
    print STDOUT $m->asXML, "\n";
}


#################################################################
# helpers
# -------
sub addMetric {
    my ($metric, $value) = @_;
    my $p = '';
    $p = "-$port" if ($port != 80 && !$https) || ($port != 443 && $https);
    push @metrics, new Metric("$prefix|$host$p|$metric", 'IntAverage')->collect( $value )  if defined $value;
}

sub run {
    my ($options) = @_;
	
    print STDERR "RUN: $exe $options\n" if $debug;
    open CMD, "$exe $options|" or die "Failed to open pipe to '$exe $options':$!\n";
    my @lines = <CMD>;
    close CMD;
    print STDERR "---RESPONSE:\n@lines---END RESPONSE\n"  if $debug;
    chomp @lines; #trim each line	
    die "No output from command: '$exe $options'\n" unless scalar(@lines);
	
    return \@lines;
}

sub collect {
    my ($lines) = @_;
    my $fields  = {};
	
    foreach (@$lines) { 
        my ($name, $value) = split /:/;
        $value = trim($value);
        $fields->{$name} = $value;
    }
	
    return $fields;
}

sub trim {
    my ($txt) = @_;
    $txt =~ s/^\s+//;
    $txt =~ s/\s+$//;
    return $txt;	
}

sub stripQuotes {
    my ($txt) = @_;
    $txt =~ s/['"]//g;
    return $txt;
}

sub percent {
    my ($over, $under) = @_;
    return 0 unless $under;
    int(0.5 + 100 * $over / $under);
}
