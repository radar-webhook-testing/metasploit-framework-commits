require 'msf/core'

###
#
# This data type represents an author of a piece of code in either
# the framework, a module, a script, or something entirely unrelated.
#
###
class Msf::Module::Author

	# A hash of known author names
	Known =
		{
			'hdm'       => 'hdm' + 0x40.chr + 'metasploit.com',
			'spoonm'    => 'spoonm' + 0x40.chr + 'no$email.com',
			'skape'     => 'mmiller' + 0x40.chr + 'hick.org',
			'vlad902'   => 'vlad902' + 0x40.chr + 'gmail.com',
			'optyx'     => 'optyx' + 0x40.chr + 'no$email.com',
			'anonymous' => 'anonymous-contributor' + 0x40.chr + 'metasploit.com',
			'stinko'    => 'vinnie' + 0x40.chr + 'metasploit.com',
			'MC'        => 'y0' + 0x40.chr + 'w00t-shell.net',
			'cazz'      => 'bmc' + 0x40.chr + 'shmoo.com',
			'pusscat'   => 'pusscat' + 0x40.chr + 'metasploit.com',
			'skylined'  => 'skylined' + 0x40.chr + 'edup.tudelft.nl',
		}

	#
	# Class method that translates a string to an instance of the Author class,
	# if it's of the right format, and returns the Author class instance
	#
	def self.from_s(str)
		instance = self.new

		# If the serialization fails...
		if (instance.from_s(str) == false)
			return nil
		end

		return instance
	end

	#
	# Transforms the supplied source into an array of authors
	#
	def self.transform(src)
		Rex::Transformer.transform(src, Array, [ self ], 'Author')
	end

	def initialize(name = nil, email = nil)
		self.name  = name
		self.email = email || Known[name]
	end

	#
	# Compares authors
	#
	def ==(tgt)
		return (tgt.to_s == to_s)
	end

	#
	# Serialize the author object to a string in form:
	#
	# name <email>
	#
	def to_s
		str = "#{name}"

		if (email != nil)
			str += " <#{email}>"
		end

		return str
	end

	#
	# Translate the author from the supplied string which may
	# have either just a name or also an email address
	#
	def from_s(str)


		# Supported formats:
		#   known_name
		#   user@host.tld
		#   Name <user@host.rld>
		#   user[at]host.tld
		#   Name <user [at] host.tld>

		
		if ((m = str.match(/^\s*([^<]+)<([^>]+)>\s*$/)))
			self.name  = m[1].sub(/<.*/, '')
			self.email = m[2].sub(/\s*\[at\]\s*/, '@')
		else
			if (Known[str])
				self.email = Known[str]
				self.name  = str
			else
				self.email = str.sub(/\s*\[at\]\s*/, '@').gsub(/^<|>$/, '')
				m = self.email.match(/([^@]+)@/)
				self.name = m ? m[1] : 'unknown'
			end
		end

		if self.name
			self.name.gsub!(/\s+$/, '')
		end
		
		return true
	end

	#
	# Sets the name of the author and updates the email if it's a known author.
	#
	def name=(name)
		self.email = Known[name] if (Known[name])
		@name = name
	end

	attr_accessor :email
	attr_reader   :name
end
