##
# $Id:$
##

##
# This file is part of the Metasploit Framework and may be subject to 
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/projects/Framework/
##


require 'msf/core'
require 'rex/encoder/nonupper'

module Msf
module Encoders
module X86

class NonUpper < Msf::Encoder::NonUpper

	Rank = LowRanking

	def initialize
		super(
			'Name'             => "Non-Upper Encoder",
			'Version'          => '$Revision$',
			'Description'      => %q{
				Encodes payloads a non-alpha based bytes. This allows
                payloads to bypass both tolower() calls,
                but will fail isalpha(). Table based design from 
                Russel Sanford. 
			},
			'Author'           => [ 'pusscat'],
			'Arch'             => ARCH_X86,
			'License'          => BSD_LICENSE,
			'EncoderType'      => Msf::Encoder::Type::NonUpper,
			'Decoder'          =>
				{
					'BlockSize' => 1,
				})
	end

	#
	# Returns the decoder stub that is adjusted for the size of the buffer
	# being encoded.
	#
	def decoder_stub(state)
        state.key                   = ""
        state.decoder_key_size      = 0
		Rex::Encoder::NonUpper::gen_decoder()
	end

	#
	# Encodes a one byte block with the current index of the length of the
	# payload.
	#
	def encode_block(state, block)
		newchar, state.key, state.decoder_key_size = Rex::Encoder::NonUpper::encode_byte(datastore['badchars'], block.unpack('C')[0], state.key, state.decoder_key_size)
	    return newchar
    end

	#
	# Fix stuff, and add the table :)
	#
	def encode_end(state)
	    state.encoded.gsub!(/A/, state.decoder_key_size.chr)
	    state.encoded.gsub!(/B/, (state.decoder_key_size+5).chr)
        state.encoded[0x24, 0] = state.key
    end
end

end end end
