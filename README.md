Introscope EPA (Perl) Scripts
=============================

This a collection of CA-Wily Introscope EPAgent scripts, written in Perl.

Introscope is a commercial tool for application performance management 
(APM) of (large) Java applications in production. EPAgent is a stand-alone
agent that can execute scripts that retrieve performance from non-Java systems.

Requirements
------------

* Valid license for CA-Wily Introscope
* EPAgent installed
* Perl 5

General installation instructions
---------------------------------

Grap the interesting Perl (*.pl) script from GitHub (https://github.com/ribomation/EPAgentScripts)
together with its dependent Perl modules (*.pm) and copy them into $epagent/epaplugins/ribomation.

All scripts can be run on the command-line, to test them out before configuring EPA. All scripts
takes a --debug parameter, that enables DEBUG printouts.


Apache Server Status
====================

Reads Apache HTTPd mod-status performance data.

Files
-----

* apache-status.pl
* Metric.pm

Typical EPA configuration
-------------------------

	introscope.epagent.plugins.stateless.names=APACHE
	introscope.epagent.stateless.APACHE.command=perl ./epaplugins/ribomation/apache-status.pl --host=www.apache.org 
	introscope.epagent.stateless.APACHE.delayInSeconds=15

Parameters
----------

<table>
	<tr> <th>Parameter</th> <th>Default</th> <th>Description</th> </tr>
	<tr> <td>prefix</td> <td>Apache Status</td> <td>Metric root node name</td> </tr>
	<tr> <td>host</td>   <td>localhost</td>     <td>Hostname or IP of Apache HTTPd server</td> </tr>
	<tr> <td>port</td>   <td>80</td>            <td>Non-standard port number</td> </tr>
	<tr> <td>https</td>  <td></td>              <td>Enable HTTPS access</td> </tr>
	<tr> <td>debug</td>  <td></td>              <td>Enable DEBUG printouts to STDERR</td> </tr>
	<tr> <td>help</td>   <td></td>              <td>Print HELP and exit</td> </tr>
</table>


IPC Status
====================

Reads IPC status performance data, using the command /usr/bin/ipcs.

Files
-----

* ipc-status.pl
* Metric.pm

Typical EPA configuration
-------------------------

	introscope.epagent.plugins.stateless.names=APACHE
	introscope.epagent.stateless.APACHE.command=perl ./epaplugins/ribomation/ipc-status.pl
	introscope.epagent.stateless.APACHE.delayInSeconds=15

Parameters
----------

<table>
	<tr> <th>Parameter</th> <th>Default</th> <th>Description</th> </tr>
	<tr> <td>prefix</td> <td>IPC Status</td>    <td>Metric root node name</td> </tr>
	<tr> <td>debug</td>  <td></td>              <td>Enable DEBUG printouts to STDERR</td> </tr>
	<tr> <td>help</td>   <td></td>              <td>Print HELP and exit</td> </tr>
</table>


