#!/usr/bin/ruby

require 'Rex/Post/Process'

module Rex
module Post
module DispatchNinja

class Process < Rex::Post::Process
	class <<self
		attr_accessor :client
	end

	def Process.getresuid()

		# gotta fix this, getresuid could fail
		# I don't transfer the return value on the wire...

		client.sendmodule('getresuid')
		data = client.sockread(12)

		client.checksig()
		return data.unpack('l3')
	end

	def Process.pid()
		client.sendmodule('getpid')
		data = client.sockread(4)
		client.checksig
		return data.unpack('V')[0]
	end

	def Process.ppid()
		client.sendmodule('getppid')
		data = client.sockread(4)
		client.checksig
		return data.unpack('V')[0]
	end
end

end; end; end # DispatchNinja/Post/Rex

