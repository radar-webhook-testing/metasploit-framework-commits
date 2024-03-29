##
# $Id$
##

##
# This file is part of the Metasploit Framework and may be subject to 
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/projects/Framework/
##


require 'msf/core'

module Msf

class Auxiliary::TestPcap < Msf::Auxiliary

	include Auxiliary::Report
	include Msf::Exploit::Capture
	
	def initialize
		super(
			'Name'        => 'Simple Network Capture Tester',
			'Version'     => '$Revision$',
			'Description' => 'This module sniffs HTTP GET requests from the network',
			'Author'      => 'hdm',
			'License'     => MSF_LICENSE,
			'Actions'     =>
				[
				 	[ 'Sniffer' ]
				],
			'PassiveActions' => 
				[
					'Sniffer'
				],
			'DefaultAction'  => 'Sniffer'
		)
	end

	def run
		print_status("Opening the network interface...")
		open_pcap()
		print_status("Sniffing HTTP requests...")
		capture.each_packet do |pkt|
			next if not pkt.tcp?
			next if not pkt.tcp_data
			if (pkt.tcp_data =~ /^GET\s+([^\s]+)\s+HTTP/)
				print_status("GET #{$1}")
			end
		end
	end
	
end

end
