#!/usr/bin/ruby

require 'Rex/Encoding/Xor/Generic'

#
# Routine for xor encoding a buffer by a 2-byte (intel word) key.  The perl
# version used to pad this buffer out to a 2-byte boundary, but I can't think
# of a good reason to do that anymore, so this doesn't.
#

module Rex
module Encoding
module Xor

class DWord < Generic

	def DWord.keysize
		4
	end

end end end end # Word/Xor/Encoding/Rex
