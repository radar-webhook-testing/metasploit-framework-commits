require 'rex/socket'
require 'rex/encoder/xdr'

module Rex
module Proto
module SunRPC

# XXX: CPORT!
class Client 
	AUTH_NULL = 0
	AUTH_UNIX = 1
	
	PMAP_PROG = 100000
	PMAP_VERS = 2
	PMAP_GETPORT = 3
	
	CALL = 0
	
	MSG_ACCEPTED = 0

	SUCCESS = 0		# RPC executed successfully
	PROG_UMAVAIL = 1	# Remote hasn't exported program
	PROG_MISMATCH = 2	# Remote can't support version #
	PROC_UNAVAIL = 3	# Program can't support procedure
	GARBAGE_ARGS = 4	# Procedure can't decode params
	
	attr_reader :rhost, :rport, :proto, :program, :version
	attr_accessor :pport

	attr_accessor :should_fragment

	def initialize(rhost, rport, proto, program, version)
		if proto.downcase !~ /^(tcp|udp)$/
			raise ArgumentError, 'Protocol is not "tcp" or "udp"'
		end

		@rhost, @rport, @program, @version, @proto = \
			rhost, rport, program, version, proto.downcase

		@pport = nil
		
		@auth_type = AUTH_NULL
		@auth_data = ''
		
		@call_sock = nil
	end
	
# XXX: Add optional parameter to have proto be something else
	def create()
		proto_num = 0
		if @proto.eql?('tcp')
			proto_num = 6
		elsif @proto.eql?('udp')
			proto_num = 17
		end

		buf =
			Rex::Encoder::XDR.encode(CALL, 2, PMAP_PROG, PMAP_VERS, PMAP_GETPORT,
				@auth_type, [@auth_data, 400], AUTH_NULL, '',
				@program, @version, proto_num, 0)
		
		sock = make_rpc(@proto, @rhost, @rport)
		send_rpc(sock, buf)
		ret = recv_rpc(sock)
		close_rpc(sock)

		arr = Rex::Encoder::XDR.decode!(ret, Integer, Integer, Integer, String, Integer,
			Integer)
		if arr[1] != MSG_ACCEPTED || arr[4] != SUCCESS || arr[5] == 0
# Check PRO[CG]_*/GARBAGE_ARGS
			raise RuntimeError, 'create failed'
		end

		@pport = arr[5]
	end
	
	def call(procedure, buffer)
		buf =
			Rex::Encoder::XDR.encode(CALL, 2, @program, @version, procedure,
				@auth_type, [@auth_data, 400], AUTH_NULL, '')+
			buffer
		
		if !@call_sock
			@call_sock = make_rpc(@proto, @rhost, @pport)
		end

		send_rpc(@call_sock, buf)
		ret = recv_rpc(@call_sock)
		
		arr = Rex::Encoder::XDR.decode!(ret, Integer, Integer, Integer, String, Integer)
		if arr[1] != MSG_ACCEPTED || arr[4] != SUCCESS
			raise 'call failed'
		end
		
		return ret
	end
	
	def destroy
		close_rpc(@call_sock) if @call_sock
		@call_sock = nil
	end
	
	
	def authnull_create
		@auth_type = AUTH_NULL
		@auth_data = ''
	end
	
	def authunix_create(host, uid, gid, groupz)
		raise ArgumentError, 'Hostname length is too long' if host.length > 255
# 10?
		raise ArgumentError, 'Too many groups' if groupz.length > 10
		
		@auth_type = AUTH_UNIX
		@auth_data =
			Rex::Encoder::XDR.encode(0, host, uid, gid, groupz) # XXX: TIME! GROUPZ?!
	end
	
	
# XXX: Dirty, integrate some sort of request system into create/call?
	def portmap_req(host, port, rpc_vers, procedure, buffer)
		buf = Rex::Encoder::XDR.encode(CALL, 2, PMAP_PROG, rpc_vers, procedure,
			AUTH_NULL, '', AUTH_NULL, '') + buffer
		
		sock = make_rpc('tcp', host, port)
		send_rpc(sock, buf)
		ret = recv_rpc(sock)
		close_rpc(sock)
		
		arr = Rex::Encoder::XDR.decode!(ret, Integer, Integer, Integer, String, Integer)
		if arr[1] != MSG_ACCEPTED || arr[4] != SUCCESS || arr[5] == 0
			raise 'portmap_req failed'
		end
		
		return ret
	end
	
# Msf::Config.data_directory
#	def Client.program2name(number)
#		File.foreach('data/rpc_names') { |line|
#			next if line.empty? || line =~ /^\s*#/
#			
#			if line =~ /^(\S+?)\s+(\d+)/ && number == $2.to_i
#				return $1
#			end
#		}
#		
#		return "UNKNOWN-#{number}"
#	end
	
	private
	def make_rpc(proto, host, port)
		Rex::Socket.create(
			'PeerHost'	=> host,
			'PeerPort'	=> port,
			'Proto'		=> proto)
	end

	def build_tcp(buf)
		if !self.should_fragment
			return Rex::Encoder::XDR.encode(0x80000000 | buf.length) + buf
		end
		
		str = buf.dup

		fragmented = ''
		
		while (str.size > 0)
			frag = str.slice!(0, rand(3) + 1)
			len = frag.size
			if str.size == 0
				len |= 0x80000000
			end

			fragmented += Rex::Encoder::XDR.encode(len) + frag
		end

		return fragmented
	end

	def send_rpc(sock, buf)
		buf = gen_xid() + buf
		if sock.type?.eql?('tcp')
			buf = build_tcp(buf)
		end
		sock.write(buf)
	end
	
	def recv_rpc(sock)
		buf = sock.get(5)
		buf.slice!(0..3)
		if sock.type?.eql?('tcp')
			buf.slice!(0..3)
		end
		return buf
	end
	
	def close_rpc(sock)
		sock.close
	end
	
	def gen_xid
		return Rex::Encoder::XDR.encode(rand(0xffffffff) + 1)
	end
end

end
end
end
