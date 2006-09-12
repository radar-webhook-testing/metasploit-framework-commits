require 'rex/ui'

module Rex
module Ui
module Text

require 'rex/io/stream_abstraction'

###
#
# This class implements input against a socket.
#
###
class Input::Buffer < Rex::Ui::Text::Input

	def initialize
		@sock = Rex::IO::StreamAbstraction.new

		@sock.initialize_abstraction
	end

	def close
		@sock.cleanup_abstraction
	end

	def supports_readline
		false
	end

	def sysread(len = 1)
		@sock.rsock.sysread(1)
	end

	def put(msg)
		@sock.lsock.write(msg)
	end

	#
	# Wait for a line of input to be read from a socket.
	#
	def gets
		# Initialize the line buffer
		line = ''
		
		# Read data one byte at a time until we see a LF
		while (true)
			break if line.include?("\n")
			
			# Read another character of input
			char = @sock.rsock.getc
			
			# Append this character to the string
			line << char
		end
		
		return line
	end

	#
	# Print a prompt and flush to the socket.
	#
	def _print_prompt(prompt)
		@sock.rsock.write(prompt)
		@sock.rsock.flush
	end

	#
	# Returns whether or not EOF has been reached on stdin.
	#
	def eof?
		@sock.lsock.closed?
	end

	#
	# Returns the file descriptor associated with a socket.
	#
	def fd
		return @sock.rsock
	end
end

end
end
end