require 'msf/core'

module Msf

###
#
# This class is used to track the state of a single encoding operation
# from start to finish.
#
###
class EncoderState

	#
	# Initializes a new encoder state, optionally with a key.
	#
	def initialize(key = nil)
		reset(key)
	end

	#
	# Reset the encoder state by initializing the encoded buffer to an empty
	# string.
	#
	def reset(key = nil)
		init_key(key)

		self.encoded  = ''
	end

	#
	# Set the initial encoding key.
	#
	def init_key(key)
		self.key      = key
		self.orig_key = key
	end

	#
	# Set the raw buffer and the original buffer if one has not been set.
	#
	def buf=(buf)
		@orig_buf = buf if (@orig_buf == nil or @buf == nil)
		@buf = buf
	end

	attr_accessor :key # :nodoc:
	attr_accessor :orig_key # :nodoc:
	attr_reader   :buf # :nodoc:
	attr_reader   :orig_buf # :nodoc:
	attr_accessor :encoded # :nodoc:
	attr_accessor :context # :nodoc:
	attr_accessor :badchars # :nodoc:

	# Decoder settings
	attr_accessor :decoder_key_offset, :decoder_key_size, :decoder_key_pack # :nodoc:
	attr_accessor :decoder_stub # :nodoc:

end

###
#
# This class is the base class that all encoders inherit from.
#
###
class Encoder < Module

	#
	# The type set that encoders can fall within.  This classifies the type of
	# output generated by the encoder in terms of the general character set
	# that is used as well as other potential attributes.
	#
	module Type
		#
		# 'A' - 'Z', '0' - '9'
		#
		AlphanumUpper        = "alpha_upper"
		#
		# 'a' - 'z', 'A' - 'Z', '0' - '9'
		#
		AlphanumMixed        = "alpha_mixed"
		#
		# Unicode-safe 'A' - 'Z', '0' - '9'
		#
		AlphanumUnicodeUpper = "alpha_unicode_upper"
		#
		# Unicode-safe 'a' - 'z', 'A' - 'Z', '0' - '9'
		#
		AlphanumUnicodeMixed = "alpha_unicode_mixed"
        #
        # toupper/tolower safe ascii - not 'a' - 'z', 'A' - 'Z' 
        #
        NonAlpha = "non_alpha"
		# 
		# All characters
		#
		Raw                  = "raw"
	end

	#
	# Initializes an encoder module instance using the supplied information
	# hash.
	#
	def initialize(info)
		super({
				'Platform' => '' # All platforms by default
			}.update(info))
	end

	##
	#
	# Encoder information accessors that can be overriden
	# by derived classes
	#
	##

	#
	# Returns MODULE_ENCODER to indicate that this is an encoder module.
	#
	def self.type
		return MODULE_ENCODER
	end

	#
	# Returns MODULE_ENCODER to indicate that this is an encoder module.
	#
	def type
		return MODULE_ENCODER
	end

	#
	# Returns the type or types of encoders that this specific module
	# classifies as.  If there is more than one type, the values should be
	# separated by whitespace.
	#
	def encoder_type
		module_info['EncoderType'] || Type::Raw
	end

	#
	# Returns the decoder stub to use based on the supplied state.
	#
	def decoder_stub(state)
		return decoder_hash['Stub'] || ''
	end

	#
	# Returns the offset to the key associated with the decoder stub.
	#
	def decoder_key_offset
		return decoder_hash['KeyOffset']
	end

	#
	# Returns the size of the key, in bytes.
	#
	def decoder_key_size
		return decoder_hash['KeySize']
	end

	#
	# Returns the size of each logical encoding block, in bytes.  This
	# is typically the same as decoder_key_size.
	#
	def decoder_block_size
		return decoder_hash['BlockSize']
	end

	#
	# Returns the byte-packing character that should be used to encode
	# the key.
	#
	def decoder_key_pack
		return decoder_hash['KeyPack'] || 'V'
	end

	#
	# Returns the module's decoder hash or an empty hash.
	#
	def decoder_hash
		module_info['Decoder'] || {}
	end

	##
	#
	# Encoding
	#
	##

	#
	# This method generates an encoded version of the supplied buffer in buf
	# using the bad characters as guides.  On success, an encoded and
	# functional version of the supplied buffer will be returned.  Otherwise,
	# an exception will be thrown if an error is encountered during the
	# encoding process.
	#
	def encode(buf, badchars = nil, state = nil)
		# Initialize an empty set of bad characters
		badchars = '' if (!badchars)

		# Initialize the encoding state and key as necessary
		if (state == nil)
			state = EncoderState.new
		end

		# Prepend data to the buffer as necessary
		buf = prepend_buf + buf

		init_state(state)

		# Save the buffer in the encoding state
		state.badchars = badchars
		state.buf      = buf

		# If this encoder is key-based and we don't already have a key, find one
		if ((decoder_key_size) and
		    (state.key == nil))
			# Find a key that doesn't contain and wont generate any bad
			# characters
			state.init_key(find_key(buf, badchars, state))

			if (state.key == nil)
				raise NoKeyError, "A key could not be found for the #{self.name} encoder.", caller
			end
		end

		# Reset the encoded buffer at this point since it may have been changed
		# while finding a key.
		state.encoded = ''

		# Call encode_begin to do any encoder specific pre-processing
		encode_begin(state)

		# Perform the actual encoding operation with the determined state
		do_encode(state)

		# Call encoded_end to do any encoder specific post-processing
		encode_end(state)

		# Return the encoded buffer to the caller
		return state.encoded
	end

	#
	# Performs the actual encoding operation after the encoder state has been
	# initialized and is ready to go.
	#
	def do_encode(state)
		# Copy the decoder stub since we may need to modify it
		stub = decoder_stub(state).dup

		if (state.key != nil and state.decoder_key_offset)
			# Substitute the decoder key in the copy of the decoder stub with the
			# one that we found
			stub[state.decoder_key_offset,state.decoder_key_size] = [ state.key.to_i ].pack(state.decoder_key_pack)
		else
			stub = encode_finalize_stub(state, stub)
		end
		
		# Walk the buffer encoding each block along the way
		offset = 0

		if (decoder_block_size)
			while (offset < state.buf.length)
				block = state.buf[offset, decoder_block_size]
	
				state.encoded += encode_block(state, 
						block + ("\x00" * (decoder_block_size - block.length)))
			     
				offset += decoder_block_size
			end
		else
			state.encoded = encode_block(state, state.buf)
		end

		# Prefix the decoder stub to the encoded buffer
		state.encoded = stub + state.encoded

		# Last but not least, do one last badchar pass to see if the stub +
		# encoded payload leads to any bad char issues...
		if ((badchar_idx = has_badchars?(state.encoded, state.badchars)) != nil)
			raise BadcharError.new(state.encoded, badchar_idx, stub.length, state.encoded[badchar_idx]), 
					"The #{self.name} encoder failed to encode without bad characters.", 
					caller
		end

		return true
	end

	##
	#
	# Buffer management
	#
	##

	#
	# Returns a string that should be prepended to the encoded version of the
	# buffer before returning it to callers.
	#
	def prepend_buf
		return ''
	end

	##
	#
	# Pre-processing, post-processing, and block encoding stubs
	#
	##

	#
	# Called when encoding is about to start immediately after the encoding
	# state has been initialized.
	#
	def encode_begin(state)
		return nil
	end

	#
	# This callback allows a derived class to finalize a stub after a key have
	# been selected.  The finalized stub should be returned.
	#
	def encode_finalize_stub(state, stub)
		stub
	end

	#
	# Called after encoding has completed.
	#
	def encode_end(state)
		return nil
	end

	#
	# Called once for each block being encoded based on the attributes of the
	# decoder.
	#
	def encode_block(state, block)
		return block
	end

	#
	# Provides the encoder with an opportunity to return the native format (as
	# in the format the code will be in when it executes on the target).  In
	# general, the same buffer is returned to the caller.  However, for things
	# like unicode, the buffer is unicod encoded and then returned.
	#
	def to_native(buf)
		buf
	end

protected

	#
	# Initializes the encoding state supplied as an argument to the attributes
	# that have been defined for this decoder stub, such as key offset, size,
	# and pack.
	#
	def init_state(state)
		# Update the state with default decoder information
		state.decoder_key_offset = decoder_key_offset
		state.decoder_key_size   = decoder_key_size
		state.decoder_key_pack   = decoder_key_pack
		state.decoder_stub       = nil

		# Restore the original buffer in case it was modified.
		state.buf                = state.orig_buf
	end

	#
	# This method finds a compatible key for the supplied buffer based also on
	# the supplied bad characters list.  This is meant to make encoders more
	# reliable and less prone to bad character failure by doing a fairly
	# complete key search before giving up on an encoder.
	#
	def find_key(buf, badchars, state = nil)
		key_bytes = [ ]
		cur_key   = [ ]
		bad_keys  = find_bad_keys(buf, badchars)
		found     = false
		allset    = [*(0..255)]
		
		# Keep chugging until we find something...right
		while (!found)
			# Scan each byte position
			0.upto(decoder_key_size - 1) { |index|
				
			# Subtract the bad and leave the good
			good_keys = allset-bad_keys[index].keys

			# Was there anything left for this index?
			if (good_keys.length == 0)
				# Not much we can do about this :(
				return nil
			end

			# Set the appropriate key byte
			key_bytes[index] = good_keys[ rand(good_keys.length) ]
			}

			# Assume that we're going to rock this shit...
			found = true

			# Scan each byte and see what we've got going on to make sure
			# no funny business is happening
			key_bytes.each { |byte|
				if (badchars.index(byte) != nil)
					found = false
				end
			}
			
			found = find_key_verify(buf, key_bytes, badchars) if found
		end

		# Do we have all the key bytes accounted for?
		if (key_bytes.length != decoder_key_size)
			return nil
		end

		return key_bytes_to_integer(key_bytes)
	end

	#
	# Returns the list of bad keys associated with this encoder.
	#
	def find_bad_keys
		return [ {}, {}, {}, {} ]
	end

	#
	# Returns the index of any bad characters found in the supplied buffer.
	#
	def has_badchars?(buf, badchars)
		badchars.each_byte { |badchar|
			idx = buf.index(badchar)

			if (idx != nil)
				return idx
			end	
		}

		return nil
	end

	#
	# Convert individual key bytes into a single integer based on the 
	# decoder's key size and packing requirements
	#
	def key_bytes_to_integer(key_bytes)
		return key_bytes_to_buffer(key_bytes).unpack(decoder_key_pack)[0]
	end

	#
	# Convert individual key bytes into a byte buffer
	#
	def key_bytes_to_buffer(key_bytes)
		return key_bytes.pack('C' + decoder_key_size.to_s)
	end

	#
	# Convert an integer into the individual key bytes based on the 
	# decoder's key size and packing requirements
	#
	def integer_to_key_bytes(integer)
		return [ integer.to_i ].pack(decoder_key_pack).unpack('C' + decoder_key_size.to_s)
	end

	#
	# Determines if the key selected by find_key is usable
	#
	def find_key_verify(buf, key_bytes, badchars)
		true
	end

end

end

require 'msf/core/encoder/xor'
require 'msf/core/encoder/xor_additive_feedback'
require 'msf/core/encoder/alphanum'
require 'msf/core/encoder/nonalpha'
