#
#	Metric.pm
#	Perl class that handles one Introscope metric.
#	Usage:
#		my $metric = new Metric('Root|Sub:Name', 'IntAverage');
#		$metric->collect(100); $metric->collect(200); ...
#		print STDOUT $metric-asXML, "\n";
#
#	Jens Riboe, jens.riboe AT ribomation.com
#	Ribomation AB, http://www.ribomation.com/
#
package Metric;
use strict;
use Carp;

######################################
# Constructor
# ------------------------------------
sub new {
    my ($target, $metricName, $metricType) = @_;
    my $class    = ref($target) || $target;    
    my $this     = bless {}, $class;
    
    $this->clear;
    $this->{name}  = trim( $metricName ) || croak('IntroscopeMetric: Must specify a metric name');
    $this->{type}  = trim( $metricType ) || 'IntAverage';
    $this->{value} = 0;   
    
    return $this;
}

######################################
# Properties
# ------------------------------------
sub name {
    my ($this) = @_;
    return $this->{name};
}

sub type {
    my ($this) = @_;
    return $this->{type};
}

sub value {
    my ($this) = @_;
    return $this->{value};
}

sub canEmit {
    my ($this) = @_;
    return $this->{emitable};
}
sub setEmittable {
    my ($this, $value) = @_;
    $this->{emitable} = $value;
}
sub doneEmit {
    my ($this) = @_;
    $this->setEmittable(0);
}

######################################
# Operators
# ------------------------------------

sub collect {
    my ($this, $value) = @_;
    $this->{value} = $value;
	$this->setEmittable(1);
	return $this;
}
sub collectDelta {
    my ($this, $value) = @_;
    $this->{value} += $value;
	$this->setEmittable(1);
	return $this;
}
sub increment {
	my ($this) = @_;
	$this->collectDelta(+1);
	return $this;
}
sub decrement {
	my ($this) = @_;
	$this->collectDelta(-1);
	return $this;
}

sub clear {
    my ($this) = @_;
    $this->{value} = 0;        
	return $this;
}

sub toString() {
    my ($this) = @_;
	my $name  = $this->name;
    my $type  = $this->type;
    my $value = $this->value;
    my $emitable = $this->{emitable};
    return qq(Metric[name=$name, value=$value, emitable=$emitable, type=$type]);
}


######################################
# Emitters
# ------------------------------------

sub asXML {
    my ($this) = @_;
    my $name  = $this->name;
    my $type  = $this->type;
    my $value = $this->value;

    return qq(<metric type="$type" name="$name" value="$value"/>);
}

sub asURI {
    my ($this) = @_;
    my $name  = $this->name;
    my $type  = $this->type;
    my $value = $this->value;
      
    return qq(?metricType=$type&metricName=$name&metricValue=$value);
}

sub asSimple {
    my ($this) = @_;
    my $name  = $this->name;
    my $value = $this->value;
      
    return qq($name=$value);
}


######################################
# Class methods
# ------------------------------------

sub forceAutoFlush {
    # Force auto-flush on STDOUT and STDERR 
    my $oldfh = select(STDOUT); $| = 1; 
    select(STDERR);             $| = 1; 
    select($oldfh);
}

######################################
# Internal Helpers
# ------------------------------------
sub trim {
    my ($txt) = @_;
    return undef unless defined($txt) && length($txt) > 0;

    $txt =~ s/^\s*(.*)\s*$/$1/;
    $txt =~ s/&/&amp;/g;
    $txt =~ s/</&lt;/g;
    $txt =~ s/>/&gt;/g;
    $txt =~ s/"/&quot;/g;
    $txt =~ s/'/&apos;/g;

    return $txt;
}

######################################
1;
