#!/usr/bin/perl -w
#
#	ipc-status.pl
#	Provides EPA metrics for semaphores, shared memory segments and message queues
#	usage: ./ipc-status.pl 
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
my$usage = 'ipc-status-pl options...
    --prefix=string     Metric name prefix, such as "IPC Status"
    --debug             Enable DEBUG printouts
';

my $exe    = '/usr/bin/ipcs';
my $prefix = 'IPC Status';
my $debug  = 0;
my $dhelp  = 0;
GetOptions(
	'prefix=s' => \$prefix,
	'debug'    => \$debug,
	'help|?'   => \$help,
);
if ($help) {print $usage; exit 0;}

##################################################################
# Verification
# ----------------
{
	open IPC, "$exe -h|" or die "Failed to open pipe to '$exe':$!\n";
	my @lines = <IPC>;
	close IPC;
	chomp @lines;
	die "Cannot find '$exe'. Ensure it's installed and executable.\n" unless $lines[0] =~ /^Usage: ipcs/;
}
$prefix = stripQuotes($prefix);


my @metrics = ();

################################
# Semaphores
# ----------
my ($maxArrays, $maxSemaphores) = valueOf(run('-s -l'), 'max number of arrays', 'max semaphores system wide');
print " max arrays=$maxArrays, max sema=$maxSemaphores\n" if $debug;
my ($usedArrays, $allocatedSemaphores) = valueOf(run('-s -u'), 'used arrays', 'allocated semaphores');
print " used=$usedArrays, allocated=$allocatedSemaphores\n" if $debug;

addMetric("Semaphores:Arrays"         , $usedArrays);
addMetric("Semaphores:Max Arrays"     , $maxArrays);
addMetric("Semaphores:Allocated"      , $allocatedSemaphores);
addMetric("Semaphores:Max Semaphores" , $maxSemaphores);
addMetric("Semaphores:Array Usage (%)", percent($usedArrays, $maxArrays) );

################################
# Shmem
# ----------
my ($maxSegments) = valueOf(run('-m -l'), 'max number of segments'); 
print " maxSegments=$maxSegments\n" if $debug;
my ($allocatedSegments) = valueOf(run('-m -u'), 'segments allocated'); 
print " allocatedSegments=$allocatedSegments\n" if $debug;

addMetric("Shared Memory Segments:Allocated", $allocatedSegments);
addMetric("Shared Memory Segments:Max"      , $maxSegments);
addMetric("Shared Memory Segments:Usage (%)", percent($allocatedSegments, $maxSegments) );

################################
# Queues
# ----------
my ($maxQueues) = valueOf(run('-q -l'), 'max queues system wide'); 
print " maxQueues=$maxQueues\n" if $debug;
my ($allocatedQueues) = valueOf(run('-q -u'), 'allocated queues'); 
print " allocatedQueues=$allocatedQueues\n" if $debug;

addMetric("Message Queues:Allocated", $allocatedQueues);
addMetric("Message Queues:Max"      , $maxQueues);
addMetric("Message Queues:Usage (%)", percent($allocatedQueues, $maxQueues) );


foreach my $m (@metrics) {
	print STDERR $m->asXML, "\n" if $debug;
	print STDOUT $m->asXML, "\n";
}


#################################################################
# helpers
# -------
sub addMetric {
    my ($metric, $value) = @_;
    push @metrics, new Metric("$prefix|$metric", 'IntAverage')->collect($value)  if defined $value;
}

sub run {
	my ($options) = @_;

    print STDERR "RUN: $exe $options\n" if $debug;
	open CMD, "$exe $options|" or die "Failed to open pipe to '$exe $options':$!\n";
	my @lines = <CMD>;
	close CMD;
	print STDERR "---RESPONSE:\n@lines---END RESPONSE\n"  if $debug;

	shift @lines; #skip first (empty) line
	shift @lines; #skip seconds (title) line
	pop   @lines; #skip last (empty) line
	chomp @lines; #trim each line
	die "No output from command: '$exe $options'\n" unless scalar(@lines);
	
	return \@lines;
}

sub valueOf {
	my $lines = shift; 
	my @result = ();
	foreach my $name (@_) {
		foreach $_ (@$lines) {
			if (/$name =? ?(\d+)/) {push @result, $1; print " value=[$1]\n" if $debug;}
		}	
	}
	return @result;
}

sub trim {
	my ($txt) = @_;
	$txt =~ s/\'//g;
	$txt =~ s/\"//g;
	return $txt;	
}

sub stripQuotes {
    my ($txt) = @_;
    $txt =~ s/['"]//g;
    return $txt;
}

sub percent {
	my ($over, $under) = @_;
	int(0.5 + 100 * $over / $under);
}

