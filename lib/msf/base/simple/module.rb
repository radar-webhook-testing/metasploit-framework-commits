require 'msf/base'

module Msf
module Simple

###
#
# Simple module wrapper that provides some common methods for dealing with
# modules, such as importing options and other such things.
#
###
module Module

	#
	# Imports extra options from the supplied hash either as a string or as a
	# hash.
	#
	def _import_extra_options(opts)
		# If options were supplied, import them into the payload's
		# datastore
		if (opts['Options'])
			self.datastore.import_options_from_hash(opts['Options'])
		elsif (opts['OptionStr'])
			self.datastore.import_options_from_s(opts['OptionStr'])
		end
	end

	#
	# Initializes the simplified interface.
	#
	def init_simplified
		load_config
	end

	#
	# Populates the datastore from the config file.
	#
	def load_config
		self.datastore.from_file(Msf::Config.config_file, self.refname)
	end

	#
	# Saves the module's datastore to the file.
	#
	def save_config
		self.datastore.to_file(Msf::Config.config_file, self.refname)
	end

end

end
end
