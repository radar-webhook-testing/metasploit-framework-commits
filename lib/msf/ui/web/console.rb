module Msf
module Ui
module Web

###
#
# This class implements a console instance for use by the web interface
#
###

class WebConsole
	attr_accessor :pipe
	attr_accessor :console
	attr_accessor :console_id
	attr_accessor :last_access
	attr_accessor :framework
	attr_accessor :thread

	class WebConsolePipe < Rex::IO::BidirectionalPipe

=begin	
		def fd(*args)
			# Remove the following line to enable full sessions via the console
			# We really should just hook the on_session() instead...
			raise ::RuntimeError, "Session interaction should be performed via the Sessions tab"
			self.pipe_input.fd(*args)
		end
=end

	end

	#
	# Provides some overrides for web-based consoles
	#
	module WebConsoleShell

		def supports_color?
			false
		end
	end

	def initialize(framework, console_id)
		# Configure the framework
		self.framework = framework

		# Configure the ID
		self.console_id = console_id

		# Create a new pipe
		self.pipe = WebConsolePipe.new

		# Create a read subscriber
		self.pipe.create_subscriber('msfweb')

		# Initialize the console with our pipe
		self.console = Msf::Ui::Console::Driver.new(
			'msf',
			'>',
			{
				'Framework'   => self.framework,
				'LocalInput'  => self.pipe,
				'LocalOutput' => self.pipe,
				'AllowCommandPassthru' => false,
			}
		)

		self.console.extend(WebConsoleShell)

		self.thread = Thread.new { self.console.run }

		update_access()
	end

	def update_access
		self.last_access = Time.now
	end

	def read
		update_access

		self.pipe.read_subscriber('msfweb')
	end

	def write(buf)
		update_access
		self.pipe.write_input(buf)
	end

	def execute(cmd)
		self.console.run_single(cmd)
	end

	def prompt
		self.pipe.prompt
	end

	def tab_complete(cmd)
		self.console.tab_complete(cmd)
	end

	def shutdown
		self.pipe.killed = true
		self.pipe.close
		self.thread.kill
	end
end


end
end
end