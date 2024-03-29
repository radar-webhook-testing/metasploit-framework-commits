#    This file is part of Metasm, the Ruby assembly manipulation suite
#    Copyright (C) 2007 Yoann GUILLOT
#
#    Licence is LGPL, see LICENCE in the top-level directory


require 'metasm/mips/opcodes'
require 'metasm/encode'

module Metasm
class MIPS
	private
	def encode_instr_op(section, instr, op)
		base = op.bin
		set_field = proc { |f, v|
			base |= (v & @fields_mask[f]) << @fields_shift[f]
		}

		val, mask, shift = 0, 0, 0

		op.args.zip(instr.args).each { |sym, arg|
			case sym
			when :rs, :rt, :rd
				set_field[sym, arg.i]
			when :ft
				set_field[sym, arg.i]
			when :rs_i16
				set_field[:rs, arg.base.i]
				val, mask, shift = arg.offset, @fields_mask[:i16], @fields_shift[:i16]
			when :sa, :i16
				val, mask, shift = arg, @fields_mask[sym], @fields_shift[sym]
			when :i26
				val, mask, shift = Expression[arg, :>>, 2], @fields_mask[sym], @fields_shift[sym]
			end
		}
		# F%SK&*cks PE base relocation detection
		Expression[base, :+, [[val, :&, mask], :<<, shift]].encode(:u32, @endianness)
	end
end
end
