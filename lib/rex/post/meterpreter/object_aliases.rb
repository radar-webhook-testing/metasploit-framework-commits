#!/usr/bin/ruby

module Rex
module Post
module Meterpreter

###
#
# ObjectAliasesContainer
# ----------------------
#
# Mixin for classes that wish to have object aliases but do not
# really need to inherit from the ObjectAliases class.
#
###
module ObjectAliasesContainer

	# Initialize the instance's aliases
	def initialize_aliases(aliases = {})
		self.aliases = aliases
	end

	# Pass-thru aliases
	def method_missing(symbol, *args)
		return self.aliases[symbol.to_s];
	end

	# Recursively dumps all of the aliases registered with a class that
	# is kind_of? ObjectAliases
	def dump_alias_tree(parent_path, current = nil)
		items = []

		if (current == nil)
			current = self
		end

		# If the current object may have object aliases...
		if (current.kind_of?(Rex::Post::Meterpreter::ObjectAliases))
			current.aliases.each_key { |x|
				current_path = parent_path + '.' + x

				items << current_path

				items.concat(dump_alias_tree(current_path, 
					current.aliases[x]))
			}
		end

		return items
	end

	attr_accessor :aliases
end

###
#
# ObjectAliases
# -------------
#
# Generic object aliases from a class instance referenced symbol to an 
# associated object of an arbitrary type
#
###
class ObjectAliases
	include Rex::Post::Meterpreter::ObjectAliasesContainer
	
	##
	#
	# Constructor
	#
	##
	
	# An instance
	def initialize(aliases = {})
		initialize_aliases(aliases)
	end
end


end; end; end
