#!/usr/bin/ruby

$:.unshift(File.join(File.dirname(__FILE__), '..', '..'))

require 'test/unit'
require 'Rex/Socket/SslTcp'

class Rex::Socket::SslTcp::UnitTest < Test::Unit::TestCase

	def test_ssltcp

		# Create an SslTcp instance
		t = nil
		assert_nothing_raised {
			t = Rex::Socket::SslTcp.create(
				'PeerHost' => 'www.google.com',
				'PeerPort' => 443)
		}
		assert_kind_of(Rex::Socket::SslTcp, t, "valid ssl tcp")

		# Send a HEAD request and make sure we get some kind of response
		head_request = "HEAD / HTTP/1.0\r\n\r\n"

		assert_equal(true, t.put(head_request), "sending head request")

		head_response = ""

		assert_nothing_raised {
			head_response = t.get(nil) || ""
		}

		assert_match(/^HTTP\/1./, head_response, "valid head response")
	end

end
