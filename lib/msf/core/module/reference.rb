require 'msf/core'

###
#
# A reference to some sort of information.  This is typically a URL, but could
# be any type of referential value that people could use to research a topic.
#
###
class Msf::Module::Reference

	#
	# Serialize a reference from a string.
	#
	def self.from_s(str)
		return self.new(str)
	end

	#
	# Initializes a reference from a string.
	#
	def initialize(in_str)
		self.str = in_str
	end

	#
	# Compares references to see if their equal.
	#
	def ==(tgt)
		return (tgt.to_s == to_s)
	end

	#
	# Returns the reference as a string.
	#
	def to_s
		return self.str
	end

	#
	# Serializes the reference instance from a string.
	#
	def from_s(in_str)
		self.str = in_str
	end

	#
	# The reference string.
	#
	attr_reader :str

protected

	attr_writer :str # :nodoc:

end

###
#
# A reference to a website.
#
###
class Msf::Module::SiteReference < Msf::Module::Reference

	#
	# Class method that translates a URL into a site reference instance.
	#
	def self.from_s(str)
		instance = self.new

		if (instance.from_s(str) == false)
			return nil
		end

		return instance
	end

	#
	# Initializes a site reference from an array.  ary[0] is the site and
	# ary[1] is the site context identifier, such as OSVDB.
	#
	def self.from_a(ary)
		return nil if (ary.length < 2)

		self.new(ary[0], ary[1])
	end

	#
	# Initialize the site reference.
	#
	def initialize(in_ctx_id = 'Unknown', in_ctx_val = '')
		self.ctx_id  = in_ctx_id
		self.ctx_val = in_ctx_val

		if (in_ctx_id == 'OSVDB')
			self.site = 'http://www.osvdb.org/' + in_ctx_val.to_s
		elsif (in_ctx_id == 'CVE')
			self.site = 'http://cve.mitre.org/cgi-bin/cvename.cgi?name=' + in_ctx_val.to_s
		elsif (in_ctx_id == 'BID')
			self.site = 'http://www.securityfocus.com/bid/' + in_ctx_val.to_s
		elsif (in_ctx_id == 'MSB')
			self.site = 'http://www.microsoft.com/technet/security/bulletin/' + in_ctx_val.to_s + '.mspx'
		elsif (in_ctx_id == 'MIL')
			self.site = 'http://milw0rm.com/metasploit/' + in_ctx_val.to_s
		elsif (in_ctx_id == 'WVE')
			self.site = 'http://www.wirelessve.org/entries/show/WVE-' + in_ctx_val.to_s
		elsif (in_ctx_id == 'URL')
			self.site = in_ctx_val.to_s
		else
			self.site  = in_ctx_id
			self.site += " (#{in_ctx_val.to_s})" if (in_ctx_val)
		end
	end

	#
	# Returns the absolute site URL.
	#
	def to_s
		return site || ''
	end

	#
	# Serializes a site URL string.
	#
	def from_s(str)
		if (/(http:\/\/|https:\/\/|ftp:\/\/)/.match(str))
			self.site = str
		else
			return false
		end

		return true
	end

	#
	# The site being referenced.
	#
	attr_reader :site
	#
	# The context identifier of the site, such as OSVDB.
	#
	attr_reader :ctx_id
	#
	# The context value of the reference, such as MS02-039
	#
	attr_reader :ctx_val

protected

	attr_writer :site, :ctx_id, :ctx_val

end


