require 'thread'
require 'rex/socket'

module Rex
module Services

###
#
# This service acts as a local TCP relay whereby clients can connect to a
# local listener that forwards to an arbitrary remote endpoint.  Interaction
# with the remote endpoint socket requires that it implement the
# Rex::IO::Stream interface.
#
###
class LocalRelay

	include Rex::Service

	###
	#
	# This module is used to extend streams such that they can be associated
	# with a relay context and the other side of the stream.
	#
	###
	module Stream

		#
		# This method is called when the other side has data that has been read
		# in.
		#
		def on_other_data(data)
			if (relay.on_other_data_proc)
				relay.on_other_data_proc.call(relay, self, data)
			# By default, simply push all the data to our side.
			else
				put(data)
			end
		end

		attr_accessor :relay
		attr_accessor :other_stream
	end

	###
	#
	# This module is used to extend stream servers such that they can be
	# associated with a relay context.
	#
	###
	module StreamServer

		#
		# This method is called when the stream server receives a local
		# connection such that the remote half can be allocated.  The return
		# value of the callback should be a Stream instance.
		#
		def on_local_connection(relay, lfd)
			if (relay.on_local_connection_proc)
				relay.on_local_connection_proc.call(relay, lfd)
			end
		end

		attr_accessor :relay
	end

	
	###
	#
	# This class acts as an instance of a given local relay.
	#
	###
	class Relay

		def initialize(name, listener, opts = {})
			self.name                     = name
			self.listener                 = listener
			self.opts                     = opts
			self.on_local_connection_proc = opts['OnLocalConnection']
			self.on_conn_close_proc       = opts['OnConnectionClose']
			self.on_other_data_proc       = opts['OnOtherData']
		end

		def shutdown
			listener.shutdown if (listener)
		end

		def close
			listener.close if (listener)
			listener = nil
		end

		attr_reader :name, :listener, :opts
		attr_accessor :on_local_connection_proc
		attr_accessor :on_conn_close_proc
		attr_accessor :on_other_data_proc
	protected
		attr_writer :name, :listener, :opts

	end

	#
	# Initializes the local tcp relay monitor.
	#
	def initialize
		self.relays       = Hash.new
		self.rfds         = Array.new
		self.relay_thread = nil
		self.relay_mutex  = Mutex.new
	end

	##
	#
	# Service interface implementors
	#
	##

	#
	# Returns the hardcore alias for the local relay service.
	#
	def self.hardcore_alias(*args)
		"__#{args.to_s}"
	end

	#
	# Returns the alias for this service.
	#
	def alias
		super || "Local Relay"
	end

	#
	# Starts the thread that monitors the local relays.
	#
	def start
		if (!self.relay_thread)
			self.relay_thread = Thread.new { 
				begin
					monitor_relays
				rescue ::Exception
					elog("Error in #{self} monitor_relays: #{$!}", 'rex')
				end
			}
		end
	end

	#
	# Stops the thread that monitors the local relays and destroys all local
	# listeners.
	#
	def stop
		if (self.relay_thread)
			self.relay_thread.kill
			self.relay_thread = nil
		end

		self.relay_mutex.synchronize {
			self.relays.delete_if { |k, v|
				v.shutdown
				v.close
				true
			}
		}

		# Flush the relay list and read fd list
		self.relays.clear
		self.rfds.clear
	end

	##
	#
	# Adding/removing local tcp relays
	#
	##

	#
	# Starts a local TCP relay.
	#
	def start_tcp_relay(lport, opts = {})
		# Make sure our options are valid
		if ((opts['PeerHost'] == nil or opts['PeerPort'] == nil) and (opts['Stream'] != true))
			raise ArgumentError, "Missing peer host or peer port.", caller
		end

		listener = Rex::Socket.create_tcp_server(
			'LocalHost' => opts['LocalHost'],
			'LocalPort' => lport)
	
		opts['LocalPort']   = lport
		opts['__RelayType'] = 'tcp'

		start_relay(listener, lport.to_s + (opts['LocalHost'] || '0.0.0.0'), opts)
	end

	#
	# Starts a local relay on the supplied local port.  This listener will call
	# the supplied callback procedures when various events occur.
	#
	def start_relay(stream_server, name, opts = {})
		# Create a Relay instance with the local stream and remote stream
		relay = Relay.new(name, stream_server, opts)

		# Extend the stream_server so that we can associate it with this relay
		stream_server.extend(StreamServer)
		stream_server.relay = relay

		# Add the stream associations the appropriate lists and hashes
		self.relay_mutex.synchronize {
			self.relays[name] = relay

			self.rfds << stream_server
		}
	end

	#
	# Stops relaying on a given local port.
	#
	def stop_tcp_relay(lport, lhost = nil)
		stop_relay(lport.to_s + (lhost || '0.0.0.0'))
	end

	#
	# Stops a relay with a given name.
	#
	def stop_relay(name)
		rv = false

		self.relay_mutex.synchronize {
			relay = self.relays[name]

			if (relay)
				close_relay(relay) 
				rv = true
			end
		}

		rv
	end

	#
	# Enumerate each TCP relay
	#
	def each_tcp_relay(&block)
		self.relays.each_pair { |name, relay|
			next if (relay.opts['__RelayType'] != 'tcp')

			yield(
				relay.opts['LocalHost'] || '0.0.0.0', 
				relay.opts['LocalPort'],
				relay.opts['PeerHost'], 
				relay.opts['PeerPort'],
				relay.opts)
		}
	end

protected

	attr_accessor :relays, :relay_thread, :relay_mutex
	attr_accessor :rfds

	#
	# Closes an cleans up a specific relay
	#
	def close_relay(relay)
		self.rfds.delete(relay.listener)
		self.relays.delete(relay.name)
		
		begin
			relay.shutdown 
			relay.close
		rescue IOError
		end
	end

	#
	# Closes a specific relay connection without tearing down the actual relay
	# itself.
	#
	def close_relay_conn(fd)
		relay = fd.relay
		ofd   = fd.other_stream

		self.rfds.delete(fd)

		begin
			if (relay.on_conn_close_proc)
				relay.on_conn_close_proc.call(fd)
			end

			fd.shutdown
			fd.close
		rescue IOError
		end
	
		if (ofd)
			self.rfds.delete(ofd)

			begin
				if (relay.on_conn_close_proc)
					relay.on_conn_close_proc.call(ofd)
				end

				ofd.shutdown
				ofd.close
			rescue IOError
			end
		end
	end

	#
	# Accepts a client connection on a local relay.
	#
	def accept_relay_conn(srvfd)
		relay = srvfd.relay

		begin
			dlog("Accepting relay client connection...", 'rex', LEV_3)

			# Accept the child connection
			lfd = srvfd.accept
			dlog("Got left side of relay: #{lfd}", 'rex', LEV_3)

			# Call the relay's on_local_connection method which should return a
			# remote connection on success
			rfd = srvfd.on_local_connection(relay, lfd)

			dlog("Got right side of relay: #{rfd}", 'rex', LEV_3)
		rescue
			wlog("Failed to get remote half of local connection on relay #{relay.name}: #{$!}", 'rex')
		end

		# If we have both sides, then we rock.  Extend the instances, associate
		# them with the relay, associate them with each other, and add them to
		# the list of polling file descriptors
		if (lfd and rfd)
			lfd.extend(Stream)
			rfd.extend(Stream)

			lfd.relay = relay
			rfd.relay = relay

			lfd.other_stream = rfd
			rfd.other_stream = lfd

			self.rfds << lfd
			self.rfds << rfd
		# Otherwise, we don't have both sides, we'll close them.
		else
			close_relay_conn(lfd)
		end
	end

	#
	# Monitors the relays for data and passes it in both directions.
	#
	def monitor_relays
		begin	

			# Poll all the streams...
			begin
				socks = select(rfds, nil, nil, 0.2)
			rescue StreamClosedError => e
				dlog("monitor_relays: closing stream #{e.stream}", 'rex', LEV_3)

				# Close the relay connection that is associated with the stream
				# closed error
				if (e.stream.kind_of?(Stream))
					close_relay_conn(e.stream)
				end
				
				dlog("monitor_relays: closed stream #{e.stream}", 'rex', LEV_3)

				next
			rescue 
				elog("Error in #{self} monitor_relays select: #{$!}", 'rex')
				return
			end

			# If socks is nil, go again.
			next unless socks

			# Process read-ready file descriptors, if any.
			socks[0].each { |rfd|

				# If this file descriptor is a server, accept the connection
				if (rfd.kind_of?(StreamServer))
					accept_relay_conn(rfd)
				# Otherwise, it's a relay connection, read data from one side
				# and write it to the other
				else
					begin
						# Read from the read fd
						data = rfd.sysread(16384)

						dlog("monitor_relays: sending #{data.length} bytes from #{rfd} to #{rfd.other_stream}",
							'rex', LEV_3)

						# Pass the data onto the other fd, most likely writing it.
						rfd.other_stream.on_other_data(data)
					# If we catch an EOFError, close the relay connection.
					rescue EOFError
						close_relay_conn(rfd)
					rescue
						elog("Error in #{self} monitor_relays read: #{$!}", 'rex')
					end
				end

			} if (socks[0])

		end while true
	end

end

end
end
