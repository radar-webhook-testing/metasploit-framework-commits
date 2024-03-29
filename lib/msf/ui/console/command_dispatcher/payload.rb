require 'rex/parser/arguments'

module Msf
module Ui
module Console
module CommandDispatcher

###
#
# Payload module command dispatcher.
#
###
class Payload

	include Msf::Ui::Console::ModuleCommandDispatcher

	@@generate_opts = Rex::Parser::Arguments.new(
		"-b" => [ true,  "The list of characters to avoid: '\\x00\\xff'"        ],
		"-e" => [ true,  "The name of the encoder module to use."               ],
		"-h" => [ false, "Help banner."                                         ],
		"-o" => [ true,  "A comma separated list of options in VAR=VAL format." ],
		"-s" => [ true,  "NOP sled length."                                     ],
		"-t" => [ true,  "The output type: ruby, perl, c, or raw."              ])

	#
	# Returns the hash of commands specific to payload modules.
	#
	def commands
		{
			"generate" => "Generates a payload",	
		}
	end

	#
	# Returns the command dispatcher name.
	#
	def name
		return "Payload"
	end

	#
	# Generates a payload.
	#
	def cmd_generate(*args)

		# Parse the arguments
		encoder_name = nil
		sled_size    = nil
		option_str   = nil
		badchars     = nil
		type         = "ruby"

		@@generate_opts.parse(args) { |opt, idx, val|
			case opt
				when '-b'
					badchars = Rex::Text.hex_to_raw(val)
				when '-e'
					encoder_name = val
				when '-o'
					option_str = val
				when '-s'
					sled_size = val.to_i
				when '-t'
					type = val
				when '-h'
					print(
						"Usage: generate [options]\n\n" +
						"Generates a payload.\n" +
						@@generate_opts.usage)
					return true
			end
		}

		# Generate the payload
		begin
			buf = mod.generate_simple(
				'BadChars'    => badchars,
				'Encoder'     => encoder_name,
				'Format'      => type,
				'NopSledSize' => sled_size,
				'OptionStr'   => option_str)
		rescue
			log_error("Payload generation failed: #{$!}")
			return false
		end

		# Display generated payload
		print(buf)

		return true

	end

end

end end end end
