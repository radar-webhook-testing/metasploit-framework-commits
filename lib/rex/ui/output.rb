require 'rex/ui'

module Rex
module Ui

###
#
# Output
# ------
#
# This class acts as a generic base class for outputing data.  It
# only provides stubs for the simplest form of outputing information.
#
###
class Output

	# General output
	require 'rex/ui/output/none'

	# Text-based output
	require 'rex/ui/text/output'

	#
	# Prints an error message.
	#
	def print_error(msg)
	end

	#
	# Prints a 'good' message.
	#
	def print_good(msg)
	end

	#
	# Prints a status line.
	#
	def print_status(msg)
	end

	#
	# Prints an undecorated line of information.
	#
	def print_line(msg)
	end

	#
	# Prints a message with no decoration.
	#
	def print(msg)
	end

	#
	# Flushes any buffered output.
	#
	def flush
	end

end

end
end