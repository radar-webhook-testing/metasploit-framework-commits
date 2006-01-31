require 'base64'
require 'md5'
require 'stringio'

begin
	require 'zlib'
rescue LoadError
end

module Rex

###
#
# This class formats text in various fashions and also provides
# a mechanism for wrapping text at a given column.
#
###
module Text
	
	##
	#
	# Constants
	#
	##
	
	UpperAlpha   = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	LowerAlpha   = "abcdefghijklmnopqrstuvwxyz"
	Numerals     = "0123456789"
	Alpha        = UpperAlpha + LowerAlpha
	AlphaNumeric = Alpha + Numerals
	DefaultWrap  = 60
	AllChars	 = 	
		"\xff\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c" +
		"\x0d\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a" +
		"\x1b\x1c\x1d\x1e\x1f\x20\x21\x22\x23\x24\x25\x26\x27\x28" +
		"\x29\x2a\x2b\x2c\x2d\x2e\x2f\x30\x31\x32\x33\x34\x35\x36" +
		"\x37\x38\x39\x3a\x3b\x3c\x3d\x3e\x3f\x40\x41\x42\x43\x44" +
		"\x45\x46\x47\x48\x49\x4a\x4b\x4c\x4d\x4e\x4f\x50\x51\x52" +
		"\x53\x54\x55\x56\x57\x58\x59\x5a\x5b\x5c\x5d\x5e\x5f\x60" +
		"\x61\x62\x63\x64\x65\x66\x67\x68\x69\x6a\x6b\x6c\x6d\x6e" +
		"\x6f\x70\x71\x72\x73\x74\x75\x76\x77\x78\x79\x7a\x7b\x7c" +
		"\x7d\x7e\x7f\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8a" +
		"\x8b\x8c\x8d\x8e\x8f\x90\x91\x92\x93\x94\x95\x96\x97\x98" +
		"\x99\x9a\x9b\x9c\x9d\x9e\x9f\xa0\xa1\xa2\xa3\xa4\xa5\xa6" +
		"\xa7\xa8\xa9\xaa\xab\xac\xad\xae\xaf\xb0\xb1\xb2\xb3\xb4" +
		"\xb5\xb6\xb7\xb8\xb9\xba\xbb\xbc\xbd\xbe\xbf\xc0\xc1\xc2" +
		"\xc3\xc4\xc5\xc6\xc7\xc8\xc9\xca\xcb\xcc\xcd\xce\xcf\xd0" +
		"\xd1\xd2\xd3\xd4\xd5\xd6\xd7\xd8\xd9\xda\xdb\xdc\xdd\xde" +
		"\xdf\xe0\xe1\xe2\xe3\xe4\xe5\xe6\xe7\xe8\xe9\xea\xeb\xec" +
		"\xed\xee\xef\xf0\xf1\xf2\xf3\xf4\xf5\xf6\xf7\xf8\xf9\xfa" +
		"\xfb\xfc\xfd\xfe"		

	DefaultPatternSets = [ Rex::Text::UpperAlpha, Rex::Text::LowerAlpha, Rex::Text::Numerals ]

	##
	#
	# Serialization
	#
	##

	#
	# Converts a raw string into a ruby buffer
	#
	def self.to_ruby(str, wrap = DefaultWrap)
		return hexify(str, wrap, '"', '" +', '', '"')
	end

	#
	# Creates a ruby-style comment
	#
	def self.to_ruby_comment(str, wrap = DefaultWrap)
		return wordwrap(str, 0, wrap, '', '# ')
	end

	#
	# Converts a raw string into a C buffer
	#
	def self.to_c(str, wrap = DefaultWrap, name = "buf")
		return hexify(str, wrap, '"', '"', "unsigned char #{name}[] = \n", '";')
	end

	#
	# Creates a c-style comment
	#
	def self.to_c_comment(str, wrap = DefaultWrap)
		return "/*\n" + wordwrap(str, 0, wrap, '', ' * ') + " */\n"
	end

	#
	# Converts a raw string into a perl buffer
	#
	def self.to_perl(str, wrap = DefaultWrap)
		return hexify(str, wrap, '"', '" .', '', '";')
	end

	#
	# Creates a perl-style comment
	#
	def self.to_perl_comment(str, wrap = DefaultWrap)
		return wordwrap(str, 0, wrap, '', '# ')
	end

	#
	# Returns the raw string
	#
	def self.to_raw(str)
		return str
	end

	#
	# Returns the hex version of the supplied string
	#
	def self.to_hex(str, prefix = "\\x")
		return str.gsub(/./) { |s| prefix + s.unpack('H*')[0] }
	end

	#
	# Converts standard ASCII text to 16-bit unicode
	#
	# By default, little-endian unicode.  By providing non-nil value for
	# endian, convert to 16-bit big-endian unicode.  NOTE, most systems require
	# a marker to specify that the unicode text being provided is in
	# big-endian.  Use 0xFEFF, which is not a "legal" unicode code point.
	#
	def self.to_unicode(str='', endian = nil)
		if endian.nil?
			return str.unpack('C*').pack('v*')
		else 
			return str.unpack('C*').pack('n*')
		end
	end
	
	#
	# Converts a hex string to a raw string
	#
	def self.hex_to_raw(str)
		[ str.downcase.gsub(/'/,'').gsub(/\\?x([a-f0-9][a-f0-9])/, '\1') ].pack("H*")
	end

	#
	# Wraps text at a given column using a supplied indention
	#
	def self.wordwrap(str, indent = 0, col = DefaultWrap, append = '', prepend = '')
		return str.gsub(/.{1,#{col - indent}}(?:\s|\Z)/){
			( (" " * indent) + prepend + $& + append + 5.chr).gsub(/\n\005/,"\n").gsub(/\005/,"\n")}
	end

	#
	# Converts a string to a hex version with wrapping support
	#
	def self.hexify(str, col = DefaultWrap, line_start = '', line_end = '', buf_start = '', buf_end = '')
		output   = buf_start
		cur      = 0
		count    = 0
		new_line = true

		# Go through each byte in the string
		str.each_byte { |byte|
			count  += 1
			append  = ''

			# If this is a new line, prepend with the
			# line start text
			if (new_line == true)
				append   += line_start
				new_line  = false
			end

			# Append the hexified version of the byte
			append += sprintf("\\x%.2x", byte)
			cur    += append.length

			# If we're about to hit the column or have gone past it,
			# time to finish up this line
			if ((cur + line_end.length >= col) or
			    (cur + buf_end.length  >= col))
				new_line  = true
				cur       = 0

				# If this is the last byte, use the buf_end instead of
				# line_end
				if (count == str.length)
					append += buf_end + "\n"
				else
					append += line_end + "\n"
				end
			end

			output += append
		}

		# If we were in the middle of a line, finish the buffer at this point
		if (new_line == false)
			output += buf_end + "\n"
		end	

		return output
	end

	##
	#
	# Transforms
	#
	##

	#
	# Base64 encoder
	#
	def self.encode_base64(str)
		Base64.encode64(str).chomp
	end

	#
	# Base64 decoder
	#
	def self.decode_base64(str)
		Base64.decode64(str)
	end

	#
	# Raw MD5 digest of the supplied string
	#
	def self.md5_raw(str)
		MD5.digest(str)	
	end

	#
	# Hexidecimal MD5 digest of the supplied string
	#
	def self.md5(str)
		MD5.hexdigest(str)
	end

	##
	#
	# Generators
	#
	##
	
	# Base text generator method
	def self.rand_base(len, bad, *foo)
		# Remove restricted characters
		(bad || '').split('').each { |c| foo.delete(c) }

		# Return nil if all bytes are restricted
		return nil if foo.length == 0
	
		buff = ""
	
		# Generate a buffer from the remaining bytes
		if foo.length >= 256
			len.times { buff << Kernel.rand(256) }
		else 
			len.times { buff += foo[ rand(foo.length) ] }
		end

		return buff
	end

	# Generate random bytes of data
	def self.rand_text(len, bad='', chars = AllChars)
		foo = chars.split('')
		rand_base(len, bad, *foo)
	end

	# Generate random bytes of alpha data
	def self.rand_text_alpha(len, bad='')
		foo = []
		foo += ('A' .. 'Z').to_a
		foo += ('a' .. 'z').to_a
		rand_base(len, bad, *foo )
	end

	# Generate random bytes of lowercase alpha data
	def self.rand_text_alpha_lower(len, bad='')
		rand_base(len, bad, *('a' .. 'z').to_a)
	end

	# Generate random bytes of uppercase alpha data
	def self.rand_text_alpha_upper(len, bad='')
		rand_base(len, bad, *('A' .. 'Z').to_a)
	end

	# Generate random bytes of alphanumeric data
	def self.rand_text_alphanumeric(len, bad='')
		foo = []
		foo += ('A' .. 'Z').to_a
		foo += ('a' .. 'z').to_a
		foo += ('0' .. '9').to_a
		rand_base(len, bad, *foo )
	end

	# Generate random bytes of english-like data
	def self.rand_text_english(len, bad='')
		foo = []
		foo += (0x21 .. 0x7e).map{ |c| c.chr }
		rand_base(len, bad, *foo )
	end
	
	#
	# Creates a pattern that can be used for offset calculation purposes.  This
	# routine is capable of generating patterns using a supplied set and a
	# supplied number of identifiable characters (slots).  The supplied sets
	# should not contain any duplicate characters or the logic will fail.
	#
	def self.pattern_create(length, sets = [ UpperAlpha, LowerAlpha, Numerals ])
		buf = ''
		idx = 0
		offsets = []

		sets.length.times { offsets << 0 }

		until buf.length >= length
			begin
				buf += converge_sets(sets, 0, offsets, length)
			rescue RuntimeError
				break
			end
		end

		buf[0..length]
	end

	#
	# Calculate the offset to a pattern
	#
	def self.pattern_offset(pattern, value)
		if (value.kind_of?(String))
			pattern.index(value)
		elsif (value.kind_of?(Fixnum) or value.kind_of?(Bignum))
			pattern.index([ value ].pack('V'))
		else
			raise ArgumentError, "Invalid class for value: #{value.class}"
		end
	end

	#
	# Compresses a string, eliminating all superfluous whitespace before and
	# after lines and eliminating all lines.
	#
	def self.compress(str)
		str.gsub(/\n/m, ' ').gsub(/\s+/, ' ').gsub(/^\s+/, '').gsub(/\s+$/, '')
	end

	# Returns true if zlib can be used.
	def self.zlib_present?
		begin
			Zlib
			return true
		rescue
			return false
		end
	end
	
	# backwards compat for just a bit...
	def self.gzip_present?
		self.zlib_present?
	end

	#
	# Compresses a string using zlib
	#
	def self.zlib_deflate(str)
		raise RuntimeError, "Gzip support is not present." if (!zlib_present?)
		return Zlib::Deflate.deflate(str)
	end

	#
	# Uncompresses a string using zlib
	#
	def self.zlib_inflate(str)
		raise RuntimeError, "Gzip support is not present." if (!zlib_present?)
		return Zlib::Inflate.inflate(str)
	end

	#
	# Compresses a string using gzip
	#
	def self.gzip(str, level = 9)
		raise RuntimeError, "Gzip support is not present." if (!zlib_present?)
		raise RuntimeError, "Invalid gzip compression level" if (level < 1 or level > 9)

		s = ""
		gz = Zlib::GzipWriter.new(StringIO.new(s), level)
		gz << str
		gz.close
		return s
	end
	
	#
	# Uncompresses a string using gzip
	#
	def self.ungzip(str)
		raise RuntimeError, "Gzip support is not present." if (!zlib_present?)

		s = ""
		gz = Zlib::GzipReader.new(StringIO.new(str))
		s << gz.read
		gz.close
		return s
	end
	
	#
	# Return the index of the first badchar in data, otherwise return
	# nil if there wasn't any badchar occurences.
	#
	def self.badchar_index(data, badchars = '')
		badchars.each_byte { |badchar|
			pos = data.index(badchar)
			return pos if pos
		}
		return nil
	end

	#
	# This method removes bad characters from a string.
	#
	def self.remove_badchars(data, badchars = '')
		data.delete(badchars)
	end

	#
	# This method returns all chars but the supplied set
	#
	def self.charset_exclude(keepers)
		[*(0..255)].pack('C*').delete(keepers)
	end

	#
	#  Shuffles a byte stream
	#
	def self.shuffle_s(str)
		shuffle_a(str.unpack("C*")).pack("C*")
	end

	#
	# Performs a Fisher-Yates shuffle on an array
	#
	def self.shuffle_a(arr)
		len = arr.length
		max = len - 1
		cyc = [* (0..max) ]
		for d in cyc
			e = rand(d+1)
			next if e == d
			f = arr[d];
			g = arr[e];
			arr[d] = g;
			arr[e] = f;
		end
		return arr
	end

protected

	def self.converge_sets(sets, idx, offsets, length) # :nodoc:
		buf = sets[idx][offsets[idx]].chr

		# If there are more sets after use, converage with them.
		if (sets[idx + 1])
			buf += converge_sets(sets, idx + 1, offsets, length)
		else
			# Increment the current set offset as well as previous ones if we
			# wrap back to zero.
			while (idx >= 0 and ((offsets[idx] = (offsets[idx] + 1) % sets[idx].length)) == 0)
				idx -= 1
			end

			# If we reached the point where the idx fell below zero, then that
			# means we've reached the maximum threshold for permutations.
			if (idx < 0)
				raise RuntimeError, "Maximum permutations reached"
			end
		end

		buf
	end

end
end
