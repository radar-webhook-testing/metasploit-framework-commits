require 'msf/base/simple'

module Msf
module Simple

###
#
# Framework
# ---------
#
# This class wraps the framework-core supplied Framework class and adds some
# helper methods for analyzing statistics as well as other potentially useful
# information that is directly necessary to drive the framework-core.
#
###
module Framework

	include GeneralEventSubscriber

	ModuleSimplifiers =
		{
			MODULE_ENCODER => Msf::Simple::Encoder,
			MODULE_EXPLOIT => Msf::Simple::Exploit,
			MODULE_NOP     => Msf::Simple::Nop,
			MODULE_PAYLOAD => Msf::Simple::Payload,
			MODULE_RECON   => Msf::Simple::Recon,
		}

	#
	# Create a simplified instance of the framework.  This routine takes a hash
	# of parameters as an argument.  This hash can contain:
	#
	#   OnCreateProc => A callback procedure that is called once the framework
	#   instance is created.
	#
	def self.create(opts = {})
		framework = Msf::Framework.new

		return simplify(framework, opts)
	end

	#
	# Extends a framework object that may already exist
	#
	def self.simplify(framework, opts)
		framework.extend(Msf::Simple::Framework)

		# Initialize the simplified framework
		framework.init_simplified()

		# Call the creation procedure if one was supplied
		if (opts['OnCreateProc'])
			opts['OnCreateProc'].call(framework)
		end

		# Initialize configuration and logging
		Msf::Config.init
		Msf::Logging.init

		# Load the configuration
		framework.load_config

		# Initialize the default module search paths
		if (Msf::Config.module_directory)
			framework.modules.add_module_path(Msf::Config.module_directory)
		end

		if (Msf::Config.user_module_directory)
			framework.modules.add_module_path(Msf::Config.user_module_directory)
		end

		# Set the on_module_created procedure to simplify any module
		# instance that is created
		framework.on_module_created_proc = Proc.new { |instance| 
			simplify_module(instance)
		}

		# Register the framework as its own general event subscriber in this
		# instance
		framework.events.add_general_subscriber(framework)

		return framework
	end

	#
	# Simplifies a module instance if the type is supported by extending it
	# with the simplified module interface.
	#
	def self.simplify_module(instance)
		if ((ModuleSimplifiers[instance.type]) and
		    (instance.class.include?(ModuleSimplifiers[instance.type]) == false))
			instance.extend(ModuleSimplifiers[instance.type])

			instance.init_simplified
		end
	end

	##
	#
	# Simplified interface
	#
	##

	#
	# Initializes the simplified interface
	#
	def init_simplified
		self.stats = Statistics.new(self)
	end

	#
	# Loads configuration, populates the root datastore, etc.
	#
	def load_config
		self.datastore.from_file(Msf::Config.config_file, 'framework/core')
	end

	#
	# Saves the module's datastore to the file
	#
	def save_config
		self.datastore.to_file(Msf::Config.config_file, 'framework/core')
	end

	attr_reader :stats

protected

	attr_writer :stats

end

end
end
