require 'rex/ui'
require 'rex/post/meterpreter'
require 'rex/logging'

module Rex
module Post
module Meterpreter
module Ui

###
#
# This class provides a shell driven interface to the meterpreter client API.
#
###
class Console

	include Rex::Ui::Text::DispatcherShell

	# Dispatchers
	require 'rex/post/meterpreter/ui/console/interactive_channel'
	require 'rex/post/meterpreter/ui/console/command_dispatcher'
	require 'rex/post/meterpreter/ui/console/command_dispatcher/core'

	#
	# Initialize the meterpreter console.
	#
	def initialize(client)
		if (Rex::Compat.is_windows())
			super("meterpreter")
		else
			super("%umeterpreter%c")
		end

		# The meterpreter client context
		self.client = client

		# Queued commands array
		self.commands = []

		# Point the input/output handles elsewhere
		reset_ui

		enstack_dispatcher(Console::CommandDispatcher::Core)
	end

	#
	# Called when someone wants to interact with the meterpreter client.  It's
	# assumed that init_ui has been called prior.
	#
	def interact(&block)
		# Run queued commands
		commands.delete_if { |ent|
			run_single(ent)
			true
		}

		# Run the interactive loop
		run { |line|
			# Run the command
			run_single(line)

			# If a block was supplied, call it, otherwise return false
			if (block)
				block.call
			else
				false
			end
		}
	end

	#
	# Interacts with the supplied channel.
	#
	def interact_with_channel(channel)
		channel.extend(InteractiveChannel) unless (channel.kind_of?(InteractiveChannel) == true)

		channel.interact(input, output)
		channel.reset_ui
	end

	#
	# Queues a command to be run when the interactive loop is entered.
	#
	def queue_cmd(cmd)
		self.commands << cmd
	end

	#
	# Runs the specified command wrapper in something to catch meterpreter
	# exceptions.
	#
	def run_command(dispatcher, method, arguments)
		begin
			super
		rescue TimeoutError
			log_error("Operation timed out.")
		rescue RequestError => info
			log_error(info.to_s)
		rescue
			log_error("Error running command #{method}: #{$!}")
		end
	end

	#
	# Logs that an error occurred and persists the callstack.
	#
	def log_error(msg)
		print_error(msg)

		elog(msg, 'meterpreter')

		dlog("Call stack:\n#{$@.join("\n")}", 'meterpreter')
	end

	attr_reader :client # :nodoc:

protected
	
	attr_writer :client # :nodoc:
	attr_accessor :commands # :nodoc:

end

end
end
end
end
