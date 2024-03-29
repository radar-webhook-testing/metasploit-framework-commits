require 'singleton'
require 'rex/socket'
require 'rex/socket/tcp'
require 'rex/socket/ssl_tcp'
require 'rex/socket/ssl_tcp_server'
require 'rex/socket/udp'
require 'timeout'

###
#
# Local communication class factory.
#
###
class Rex::Socket::Comm::Local

	include Singleton
	include Rex::Socket::Comm

	#
	# Creates an instance of a socket using the supplied parameters.
	#
	def self.create(param)
		case param.proto
			when 'tcp'
				return create_by_type(param, ::Socket::SOCK_STREAM, ::Socket::IPPROTO_TCP)
			when 'udp'
				return create_by_type(param, ::Socket::SOCK_DGRAM, ::Socket::IPPROTO_UDP)
			else
				raise Rex::UnsupportedProtocol.new(param.proto), caller
		end
	end

	#
	# Creates a socket using the supplied Parameter instance.
	#
	def self.create_by_type(param, type, proto = 0)

		# Whether to use IPv6 addressing
		usev6 = false
			
		# Detect IPv6 addresses and enable IPv6 accordingly
		if ( Rex::Socket.support_ipv6?())

			# Allow the caller to force IPv6
			if (param.v6)
				usev6 = true
			end

			# Force IPv6 mode for non-connected UDP sockets
			if (type == ::Socket::SOCK_DGRAM and not param.peerhost)
				usev6 = true
			end
		
			local = Rex::Socket.resolv_nbo(param.localhost) if param.localhost
			peer  = Rex::Socket.resolv_nbo(param.peerhost) if param.peerhost
			
			if (local and local.length == 16)
				usev6 = true			
			end
			
			if (peer and peer.length == 16)
				usev6 = true			
			end
			
			if (usev6)
				if (local and local.length == 4)
					if (local == "\x00\x00\x00\x00")
						param.localhost = '::'
					else
						param.localhost = '::ffff:' + Rex::Socket.getaddress(param.localhost)
					end
				end
				
				if (peer and peer.length == 4)
					if (peer == "\x00\x00\x00\x00")
						param.peerhost = '::'
					else
						param.peerhost = '::ffff:' + Rex::Socket.getaddress(param.peerhost)
					end
				end
				
				param.v6 = true
			end	
		else
			# No IPv6 support
			param.v6 = false
		end
		
		# Notify handlers of the before socket create event.
		self.instance.notify_before_socket_create(self, param)

		# Create the socket
		sock = nil
		if (param.v6)
			sock = ::Socket.new(::Socket::AF_INET6, type, proto)		
		else
			sock = ::Socket.new(::Socket::AF_INET, type, proto)
		end

		# Bind to a given local address and/or port if they are supplied
		if (param.localhost || param.localport)
			begin	
				if (param.server?)
					sock.setsockopt(::Socket::SOL_SOCKET, ::Socket::SO_REUSEADDR, 1)
				end

				sock.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)

				sock.bind(Rex::Socket.to_sockaddr(param.localhost, param.localport))

			rescue Errno::EADDRINUSE
				sock.close
				raise Rex::AddressInUse.new(param.localhost, param.localport), caller
			end
		end

		# If a server TCP instance is being created...
		if (param.server?)
			sock.listen(32)

			return sock if (param.bare?)

			klass = Rex::Socket::TcpServer
			if (param.ssl)
				klass = Rex::Socket::SslTcpServer
			end
			sock.extend(klass)

			sock.initsock(param)
		# Otherwise, if we're creating a client...
		else
			chain = []

			# If we were supplied with host information
			if (param.peerhost)
				begin
					if param.proxies
						chain = param.proxies.dup
						chain.push(['host',param.peerhost,param.peerport])
						ip = chain[0][1]
						port = chain[0][2].to_i
						
						begin
							timeout(param.timeout) do
							    sock.connect(Rex::Socket.to_sockaddr(ip, port))
							end
						rescue ::Timeout::Error
							raise ::Errno::ETIMEDOUT
						end						
					else
						begin
							timeout(param.timeout) do
							    sock.connect(Rex::Socket.to_sockaddr(param.peerhost, param.peerport))
							end
						rescue ::Timeout::Error
							raise ::Errno::ETIMEDOUT
						end
					end
				
				rescue Errno::EHOSTUNREACH, ::Errno::ENETUNREACH
					sock.close
					raise Rex::HostUnreachable.new(param.peerhost, param.peerport), caller
				
				rescue Errno::ETIMEDOUT
					sock.close
					raise Rex::ConnectionTimeout.new(param.peerhost, param.peerport), caller
				
				rescue Errno::ECONNREFUSED
					sock.close
					raise Rex::ConnectionRefused.new(param.peerhost, param.peerport), caller
				end
			end

			if (param.bare? == false)
				case param.proto
					when 'tcp'
						klass = Rex::Socket::Tcp
	
						if (param.ssl)
							klass = Rex::Socket::SslTcp
						end
	
						sock.extend(klass)
	
						sock.initsock(param)
					when 'udp'
						sock.extend(Rex::Socket::Udp)
	
						sock.initsock(param)
				end
			end

			if chain.size > 1
				chain.each_with_index {
					|proxy, i|
					next_hop = chain[i + 1]
					if next_hop
						proxy(sock, proxy[0], next_hop[1], next_hop[2])
					end
				}
			end
		end

		# Notify handlers that a socket has been created.
		self.instance.notify_socket_created(self, sock, param)

		sock
	end
				
	def self.proxy (sock, type, host, port)
		if type == 'socks4'
			setup = [4,1,port.to_i].pack('CCn') + Socket.gethostbyname(host)[3] + "bmc\x00"
			size = sock.put(setup)
			if size != setup.length
				raise 'ack, we did not write as much as expected!'
			end
	
			begin
				ret = sock.get_once(8, 30)
			rescue IOError
				raise Rex::ConnectionRefused.new(host, port), caller
			end
	
			if (ret.nil? or ret.length < 8)
				raise 'ack, sock4 server did not respond with a socks4 response'
			end
			if ret[1] != 90
				raise "ack, socks4 server responded with error code #{ret[0]}"
			end
		else
			raise 'unsupported socks protocol', caller
		end
	end

	##
	#
	# Registration
	#
	##
	
	def self.register_event_handler(handler) # :nodoc:
		self.instance.register_event_handler(handler)
	end

	def self.deregister_event_handler(handler) # :nodoc:
		self.instance.deregister_event_handler(handler)
	end

	def self.each_event_handler(handler) # :nodoc:
		self.instance.each_event_handler(handler)
	end

end
