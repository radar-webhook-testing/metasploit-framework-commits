require 'rex/constants'

module Rex


###
#
# This module provides generalized methods for performing operations that are
# architecture specific.  Furthermore, the modules contained within this
# module provide features that are specific to a given architecture.
#
###
module Arch

	#
	# Architecture classes
	#
	require 'rex/arch/x86'
	require 'rex/arch/sparc'

	#
	# This routine adjusts the stack pointer for a given architecture.
	#
	def self.adjust_stack_pointer(arch, adjustment)
		case arch
			when /x86/
				Rex::Arch::X86.adjust_reg(Rex::Arch::X86::ESP, adjustment)
			else
				nil
		end
	end

	#
	# This route provides address packing for the specified arch
	#
	def self.pack_addr(arch, addr)
		case arch
			when ARCH_X86
				[addr].pack('V')
			when ARCH_MIPS # ambiguous
				[addr].pack('N')
			when ARCH_PPC  # ambiguous
				[addr].pack('N')			
			when ARCH_SPARC
				[addr].pack('N')			
		end
	end

	#
	# This routine reports the endianess of a given architecture
	#
	def self.endian(arch)
	
		if ( arch.is_a?(::Array))
			arch = arch[0]
		end
		
		case arch
			when ARCH_X86
				return ENDIAN_LITTLE
			when ARCH_MIPS # ambiguous
				return ENDIAN_BIG
			when ARCH_PPC  # ambiguous
				return ENDIAN_BIG
			when ARCH_SPARC
				return ENDIAN_BIG
		end
		
		return ENDIAN_LITTLE
	end

end
end
