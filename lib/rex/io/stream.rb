module Rex
module IO

###
#
# Stream
# ------
# 
# This mixin is an abstract representation of a streaming connection.
#
###
module Stream

	##
	#
	# Abstract methods
	#
	##

	#
	# Set the stream to blocking or non-blocking
	#
	def blocking=(tf)
	end

	#
	# Check to see if the stream is blocking or non-blocking
	#
	def blocking
	end

	#
	# Writes data to the stream.
	#
	def write(buf, opts = {})
	end

	#
	# Reads data from the stream.
	#
	def read(length = nil, opts = {})
	end

	#
	# Shuts down the stream for reading, writing, or both.
	#
	def shutdown(how = SW_BOTH)
	end

	#
	# Closes the stream and allows for resource cleanup
	#
	def close
	end

	#
	# Polls the stream to see if there is any read data available.  Returns a
	# value that is greater than or equal to zero if data is available,
	# otherwise nil is returned.
	#
	def poll_read(timeout = nil)
		return nil
	end

	##
	#
	# Common methods
	#
	##

	#
	# Writes data to the stream
	#
	def <<(buf)
		return write(buf)
	end

	#
	# Writes to the stream, optionally timing out after a period of time
	#
	def timed_write(buf, wait = def_write_timeout, opts = {})
		if (wait and wait > 0)
			timeout(wait) {
				return write(buf, opts)
			}

			raise TimeoutError, "Write operation timed out.", caller
		else
			return write(buf, opts)
		end
	end

	#
	# Reads from the stream, optionally timing out after a period of time
	#
	def timed_read(length = nil, wait = def_read_timeout, opts = {})
		if (wait and wait > 0)
			timeout(wait) {
				return read(length, opts)
			}
			
			raise TimeoutError, "Read operation timed out.", caller
		else
			return read(length, opts)
		end
	end

	#
	# Write the full contents of the supplied buffer
	#
	def put(buf, opts = {})
		send_buf = buf.dup()
		send_len = send_buf.length
		wait     = opts['Timeout'] || 0

		# Keep writing until our send length drops to zero
		while (send_len > 0)
			curr_len  = timed_write(send_buf, wait, opts)
			send_len -= curr_len
			send_buf.slice!(0, curr_len)
		end

		return true
	end

	#
	# Read as much data as possible from the pipe
	#
	def get(timeout = def_read_timeout, ltimeout = def_read_loop_timeout, opts = {})
		# No data in the first place? bust.
		if (!poll_read(timeout))
			return nil
		end

		buf = ""
		lps = 0

		# Keep looping until there is no more data to be gotten..
		while (poll_read(ltimeout))
			temp = recv(def_block_size)

			break if (temp.empty?)

			buf += temp
			lps += 1
			
			break if (lps >= def_max_loops)
		end

		# Return the entire buffer we read in
		return buf
	end

	##
	#
	# Defaults
	#
	##

	def def_write_timeout
		return 10
	end

	def def_read_timeout
		return 10
	end
	
	def def_read_loop_timeout
		return 0.5
	end

	def def_max_loops
		return 1024
	end

	def def_block_size
		return 16384
	end

protected

end

end end
