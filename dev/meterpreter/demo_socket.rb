#!/usr/bin/env ruby -I. -I../../lib

require 'DemoClient'
require 'Rex/Socket/Parameters'

host   = ARGV[0] || '127.0.0.1'
port   = ARGV[1] || '12345'
client = DemoClient.new(host, port).client

# Create a parameter representation class based on the perl-style hash
# elements
params = Rex::Socket::Parameters.new(
		'PeerHost' => '128.242.160.3',
		'PeerPort' => 25,
		'Proto'    => 'tcp')

# Create the socket for this connection
socket = client.net.socket.create(params)

# Send GET / HTTP/1.0
socket.send("HELO hick.org\r\n")

data = socket.recv

puts "#{data}"

socket.send("QUIT\r\n")

socket.sock.shutdown(1)

while ((data = socket.recv) != nil)
	puts "#{data}"
end

puts "Finished"

#while (1)
#	select nil, nil, nil, 5
#end
