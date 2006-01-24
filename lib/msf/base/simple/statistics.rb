module Msf
module Simple

###
#
# This class provides an interface to various statistics about the
# framework instance.
#
###
class Statistics
	include Msf::Framework::Offspring

	#
	# Initializes the framework statistics.
	#
	def initialize(framework)
		self.framework = framework
	end

	#
	# Returns the number of encoders in the framework.
	#
	def num_encoders
		self.framework.encoders.length
	end

	#
	# Returns the number of exploits in the framework.
	#
	def num_exploits
		self.framework.exploits.length
	end

	#
	# Returns the number of NOP generators in the framework.
	#
	def num_nops
		self.framework.nops.length
	end

	#
	# Returns the number of payloads in the framework.
	#
	def num_payloads
		self.framework.payloads.length
	end

	#
	# Returns the number of auxiliary modules in the framework.
	#
	def num_auxiliary
		self.framework.auxiliary.length
	end

	#
	# Returns the number of stages in the framework.
	#
	def num_payload_stages
		self.framework.payloads.stages.length
	end

	#
	# Returns the number of stagers in the framework.
	#
	def num_payload_stagers
		self.framework.payloads.stagers.length
	end

	#
	# Returns the number of singles in the framework.
	#
	def num_payload_singles
		self.framework.payloads.singles.length
	end
end

end
end
