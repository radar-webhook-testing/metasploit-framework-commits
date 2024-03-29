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

class Auxiliary::Scanner::Mssql::Mssql_login < Msf::Auxiliary
        
	include Exploit::Remote::MSSQL
	include Auxiliary::Scanner
	
	def initialize
		super(	
			'Name'           => 'MSSQL Login Utility',
			'Version'        => '$Revision$',
			'Description'    => 'This module simply queries the MSSQL instance for a null SA account.',
			'Author'         => 'MC',
			'License'        => MSF_LICENSE
		)
	
		register_options(
			[
				Opt::RPORT(1433)
			], self.class)
	end
		
	def run_host(ip)

		info = mssql_login

		if (info == true)
			print_status("Target #{ip} DOES have a null sa account!")
		else
			print_status("Target #{ip} does not have a null sa account...")
		end
	end	

end
end
