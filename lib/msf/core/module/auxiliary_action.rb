require 'msf/core'

###
#
# A target for an exploit.
#
###
class Msf::Module::AuxiliaryAction


	#
	# Serialize from an array to a Target instance.
	#
	def self.from_a(ary)
		return nil if (ary.length < 2)

		self.new(ary.shift, ary.shift)
	end

	#
	# Transforms the supplied source into an array of AuxiliaryActions.
	#
	def self.transform(src)
		Rex::Transformer.transform(src, Array, [ self, String ], 'AuxiliaryAction')
	end


	def initialize(name, opts={})
		self.name           = name
		self.opts           = opts
	end

	#
	# Index the options directly.
	#
	def [](key)
		opts[key]
	end

	#
	# The name of the action ('info')
	#
	attr_reader :name
	#
	# Action specific parameters
	#
	attr_reader :opts

protected

	attr_writer :name, :opts # :nodoc:

end
