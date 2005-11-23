require 'rex/proto/http'

module Rex
module Proto
module Http

DefaultProtocol = '1.1'

###
#
# This class represents an HTTP packet.
#
###
class Packet

	#
	# Parser processing codes
	#
	module ParseCode
		Completed = 1
		Partial   = 2
		Error     = 3
	end

	#
	# Parser states
	#
	module ParseState
		ProcessingHeader = 1
		ProcessingBody   = 2
		Completed        = 3
	end

	require 'rex/proto/http/header'

	#
	# Initializes an instance of an HTTP packet.
	#
	def initialize()
		self.headers = Header.new
		self.auto_cl = true

		reset
	end

	#
	# Return the associated header value, if any.
	#
	def [](key)
		self.headers[key]
	end

	#
	# Set the associated header value.
	#
	def []=(key, value)
		self.headers[key] = value
	end

	#
	# Parses the supplied buffer.  Returns one of the two parser processing
	# codes (Completed, Partial, or Error).
	#
	def parse(buf)

		# Append the incoming buffer to the buffer queue.
		self.bufq += buf

		begin
			# If we're processing headers, do that now.
			if (self.state == ParseState::ProcessingHeader)
				parse_header
			end
	
			# If we're processing the body (possibly after having finished
			# processing headers), do that now.
			if (self.state == ParseState::ProcessingBody)
				parse_body
			end
		rescue
			self.error = $!

			puts "#{self.error}: \n#{$@.join("\n")}"

			return ParseCode::Error
		end

		# Return completed or partial to the parsing status to the caller
		(self.state == ParseState::Completed) ? ParseCode::Completed : ParseCode::Partial
	end

	#
	# Reset the parsing state and buffers.
	#
	def reset
		self.bufq  = ''
		self.state = ParseState::ProcessingHeader
		self.headers.reset
		self.body  = ''
		self.transfer_chunked = nil
		self.inside_chunk = nil
	end

	#
	# Returns whether or not parsing has completed.
	#
	def completed?
		comp = false

		# If the parser state is processing the body and there are an
		# undetermined number of bytes left to read, we just need to say that
		# things are completed as it's hard to tell whether or not they really
		# are.
		if ((self.state == ParseState::ProcessingBody) and
		    (self.body_bytes_left < 0) )
			comp = true
		# Or, if the parser state actually is completed, then we're good.
		elsif (self.state == ParseState::Completed)
			comp = true
		end

		return comp
	end

	#
	# Converts the packet to a string.
	#
	def to_s
		# Update the content length field in the header with the body length.
		if (self.body and self.auto_cl)
			self.headers['Content-Length'] = self.body.length
		end

		str  = self.headers.to_s(cmd_string)
		str += self.body || ''
	end

	#
	# Converts the packet from a string.
	#
	def from_s(str)
		reset

		parse(str)
	end

	#
	# Returns the command string, such as:
	#
	# HTTP/1.0 200 OK for a response
	#
	# or
	# 
	# GET /foo HTTP/1.0 for a request
	#
	def cmd_string
		self.headers.cmd_string
	end

	attr_reader   :headers
	attr_reader   :error
	attr_accessor :state
	attr_accessor :bufq
	attr_accessor :body
	attr_accessor :auto_cl
	attr_accessor :max_data
	attr_reader   :incomplete
	
protected

	attr_writer   :headers
	attr_writer   :error
	attr_writer   :incomplete
	attr_accessor :body_bytes_left
	attr_accessor :transfer_chunked
	attr_accessor :inside_chunk

	##
	#
	# Overridable methods
	#
	##
	
	#
	# Allows derived classes to split apart the command string.
	#
	def update_cmd_parts(str)
	end

	##
	#
	# Parsing
	#
	##

	#
	# Parses the header portion of the request.
	#
	def parse_header
		
		# Does the buffer queue contain the entire header?  If so, parse it and
		# transition to the body parsing phase.
		idx = self.bufq.index(/\r*\n\r*\n/)
		
		if (idx == -1)
			self.headers.from_s(self.bufq)
		else
			idx += 4
		end
		
		if (idx >= 0)
			# Extract the header block
			head = self.bufq.slice!(0, idx)

			# Serialize the headers
			self.headers.from_s(head)

			# Extract the content length, if any.
			if (self.headers['Content-Length'])
				self.body_bytes_left = self.headers['Content-Length'].to_i
			else
				self.body_bytes_left = -1
			end

			if (self.headers['Transfer-Encoding'])
				self.transfer_chunked = 1 if self.headers['Transfer-Encoding'] =~ /chunked/i
			end

			connection    = self.headers['Connection']
			comp_on_close = false

			if (connection and connection == 'close')
				comp_on_close = true
			end
			
			# Change states to processing the body if we have a content length of
			# the connection type is close.
			if ((self.body_bytes_left > 0) or (comp_on_close) or self.transfer_chunked)
				self.state = ParseState::ProcessingBody
			else
				self.state = ParseState::Completed
			end
		end
		
		# No command string?  Wack.
		if (self.headers.cmd_string == nil)
			raise RuntimeError, "Invalid command string", caller
		end

		# Allow derived classes to update the parts of the command string
		self.update_cmd_parts(self.headers.cmd_string)

	end

	#
	# Parses the body portion of the request.
	#
	def parse_body

		# Just return if the buffer is empty
		if (self.bufq.length == 0)
			return
		end

		# Handle chunked transfer-encoding responses
		if (self.transfer_chunked and self.inside_chunk != 1 and self.bufq.length) 
			
			# Remove any leading newlines or spaces
			self.bufq.lstrip!
			
			# Extract the actual hexadecimal length value
			clen = self.bufq.slice!(/.*\r*\n/)
			clen.rstrip!
			
			self.body_bytes_left = clen.hex
			if (self.body_bytes_left == 0)
				self.bufq.rstrip!
				return self.state = ParseState::Completed
			end
			
			self.inside_chunk = 1
		end

		# If there are bytes remaining, slice as many as we can and append them
		# to our body state.
		if (self.body_bytes_left > 0)
			part = self.bufq.slice!(0, self.body_bytes_left)

			self.body += part
			self.body_bytes_left -= part.length
		# Otherwise, just read it all.
		else
			self.body += self.bufq
			self.bufq  = ''
		end

		# Finish this chunk and move on to the next one
		if (self.transfer_chunked and self.body_bytes_left == 0)
			self.inside_chunk = 0
			return self.parse_body
		end

		# If there are no more bytes left, then parsing has completed and we're
		# ready to go.
		if (self.transfer_chunked != 1 and self.body_bytes_left <= 0)
			return self.state = ParseState::Completed
		end
	end

end

end
end
end
