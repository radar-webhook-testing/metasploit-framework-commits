require 'msf/core'
require 'rex/encoder/alpha2/unicode_mixed'

module Msf
module Encoders
module X86

class UnicodeMixed < Msf::Encoder::Alphanum

	Rank = LowRanking

	def initialize
		super(
			'Name'             => "Alpha2 Alphanumeric Unicode Mixedcase Encoder",
			'Version'          => '$Revision$',
			'Description'      => %q{
				Encodes payloads as unicode-safe mixedcase text.  This encoder uses 
				SkyLined's Alpha2 encoding suite.
         	},
			'Author'           => [ 'pusscat', 'skylined' ],
			'Arch'             => ARCH_X86,
			'EncoderType'      => Msf::Encoder::Type::AlphanumUnicodeMixed,
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
		reg    = datastore['BufferRegister']    || 'EAX' 
		offset = datastore['BufferOffset'].to_i || 0

		Rex::Encoder::Alpha2::UnicodeMixed::gen_decoder(reg, offset) 
	end

	#
	# Encodes a one byte block with the current index of the length of the
	# payload.
	#
	def encode_block(state, block)
		Rex::Encoder::Alpha2::UnicodeMixed::encode_byte(block.unpack('C')[0])
	end

	#
	# Tack on our terminator
	#
	def encode_end(state)
		state.encoded += Rex::Encoder::Alpha2::UnicodeMixed::add_terminator()
	end

	#
	# Returns the unicode version of the supplied buffer.
	#
	def to_native(buffer)
		Rex::Text.to_unicode(buffer)
	end

end

end end end
