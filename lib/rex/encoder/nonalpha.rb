#!/usr/bin/env ruby

require 'rex/text'

module Rex
module Encoder

class NonAlpha
	
	def NonAlpha.gen_decoder()
	    decoder = 
            "\xEB\x19"  +               # Jmp to table
            "\x5E"      +               # pop esi
            "\x8B\xFE"  +               # mov edi, esi      - Get table addr
            "\x8B\xD6"  +               # mov edx, edi      - Hold end of table ptr
            "\x83\xC7"  + "A" +         # add edi, tablelen - Get shellcode addr
            "\x3B\xFA"  +               # cmp edx, edi
            "\x7E\x0B"  +               # jle to end
            "\xB0\x7B"  +               # mov eax, 0x7B     - Set up eax with magic
            "\xF2\xAE"  +               # repne scasb       - Find magic!
            "\xFF\xCF"  +               # dec edi           - scasb purs us one ahead
            "\xAC"      +               # lodsb
            "\x28\x07"  +               # subb [edi], al
            "\xEB\xF1"  +               # jmp BACK!
            "\xEB"      + "B" +         # jmp [shellcode]
            "\xE8\xE2\xFF\xFF\xFF"  
    end

	def NonAlpha.encode_byte(block, table, tablelen)
	    if (block >= 0x41 and block <= 0x51) or (block >= 0x61 and block <= 0x7A ) or (block == 0x7B)
            # gen offset, return magic
            offset = 0x7b - block;
            table += offset
            tablelen = tablelen + 1
            block = "\x7B"
        end

        if tablelen > 256
            return "\x00"
        end
        
        return block.chr
    end

	def NonAlpha.encode(buf)
        table = ""
        tablelen = 0
        nonascii = ""
        encoded = gen_decoder()
		buf.each_byte {
			|block|

			newchar = encode_byte(block.unpack('C')[0], table, tablelen)
            if newchar == "\x00"
                # FAIL
            end
            nonascii += newchar
		}
        encoded.gsub!(/A/, tablelen)
        encoded.gsub!(/B/, tablelen+5)
        encoded += table
		encoded += nonascii
	end

end end end
