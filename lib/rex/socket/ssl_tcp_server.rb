require 'rex/socket'
require 'rex/socket/tcp_server'
require 'rex/io/stream_server'
require 'openssl'

###
#
# This class provides methods for interacting with an SSL wrapped TCP server.  It
# implements the StreamServer IO interface.
#
###
module  Rex::Socket::SslTcpServer
	include Rex::Socket::TcpServer
	
	##
	#
	# Factory
	#
	##

	def initsock(params = nil)
		self.sslctx  = makessl()
		super
	end

	def accept(opts = {})
		sock = super()
		if (sock)
			sock.extend(Rex::Socket::Tcp)
			sock.context = self.context
			pn = sock.getpeername

			sock.peerhost = pn[1]
			sock.peerport = pn[2]
        end
		t = OpenSSL::SSL::SSLSocket.new(sock, self.sslctx)
		t.extend(Rex::Socket::Tcp)
		t.accept
	
        t
	end


	def makessl
		key = OpenSSL::PKey::RSA.new(512){ }
		
		cert = OpenSSL::X509::Certificate.new
		cert.version = 2
		cert.serial = rand(0xFFFFFFFF)
		# name = OpenSSL::X509::Name.new([["C","JP"],["O","TEST"],["CN","localhost"]])
		subject = OpenSSL::X509::Name.new([
				["C","US"], 
				['ST', Rex::Text.rand_state()], 
				["L", Rex::Text.rand_text_alpha(rand(20) + 10)],
				["O", Rex::Text.rand_text_alpha(rand(20) + 10)],
				["CN", Rex::Text.rand_hostname],
			])
		issuer = OpenSSL::X509::Name.new([
				["C","US"], 
				['ST', Rex::Text.rand_state()], 
				["L", Rex::Text.rand_text_alpha(rand(20) + 10)],
				["O", Rex::Text.rand_text_alpha(rand(20) + 10)],
				["CN", Rex::Text.rand_hostname],
			])

		cert.subject = subject
		cert.issuer = issuer
		cert.not_before = Time.now
		cert.not_after = Time.now + 3600
		cert.public_key = key.public_key
		ef = OpenSSL::X509::ExtensionFactory.new(nil,cert)
		cert.extensions = [
			ef.create_extension("basicConstraints","CA:FALSE"),
			ef.create_extension("subjectKeyIdentifier","hash"),
			ef.create_extension("extendedKeyUsage","serverAuth"),
			ef.create_extension("keyUsage","keyEncipherment,dataEncipherment,digitalSignature")
		]
		ef.issuer_certificate = cert
		cert.add_extension ef.create_extension("authorityKeyIdentifier", "keyid:always,issuer:always")
		cert.sign(key, OpenSSL::Digest::SHA1.new)
		
		ctx = OpenSSL::SSL::SSLContext.new()
		ctx.key = key
		ctx.cert = cert

		ctx.session_id_context = OpenSSL::Digest::MD5.hexdigest($0)

		return ctx
	end

	attr_accessor :sslctx
end
