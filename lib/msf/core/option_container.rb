require 'resolv'
require 'Msf/Core'

module Msf

###
#
# OptBase
# -------
#
# The base class for all options.
#
###
class OptBase

	def initialize(in_name, attrs = [])
		self.name     = in_name
		self.advanced = false
		self.required = attrs[0] || false
		self.desc     = attrs[1] || nil
		self.default  = attrs[2] || nil
	end

	def required?
		return required
	end

	def advanced?
		return advanced
	end

	def type?(in_type)
		return (type == in_type)
	end

	# If it's required and the value is nil or empty, then it's not valid.
	def valid?(value)
		return (required? and (value == nil or value.to_s.empty?)) ? false : true
	end

	attr_reader   :name, :required, :desc, :default
	attr_writer   :name
	attr_accessor :advanced

protected

	attr_writer   :required, :desc, :default
end

###
#
# Core option types.  The core supported option types are:
#
# OptString  - Multi-byte character string
# OptRaw     - Multi-byte raw string
# OptBool    - Boolean true or false indication
# OptPort    - TCP/UDP service port
# OptAddress - IP address or hostname
# OptPath    - Path name on disk
#
###

class OptString < OptBase
	def type 
		return 'string' 
	end
end

class OptRaw < OptBase
	def type
		return 'raw'
	end
end

class OptBool < OptBase
	def type
		return 'bool'
	end

	def valid?(value)
		if ((value != nil and value.empty? == false) and
		    (value.match(/^(y|n|t|f|0|1)$/i) == nil))
			return false
		end
	end

	def is_true?
		return (value.match(/^(y|t|1)$/i) != nil) ? true : false
	end

	def is_false?
		return !is_true?
	end
end

class OptPort < OptBase
	def type 
		return 'port' 
	end

	def valid?(value)
		if ((value != nil and value.to_s.empty? == false) and
		    ((value.to_i < 0 or value.to_i > 65535)))
			return false
		end

		return super
	end
end

class OptAddress < OptBase
	def type 
		return 'address' 
	end

	def valid?(value)
		if (value != nil and value.empty? == false)
			begin
				Resolv.getaddress(value)
			rescue
				return false
			end
		end

		return super
	end
end

class OptPath < OptBase
	def type 
		return 'path' 
	end

	def valid?(value)
		if ((value != nil and value.empty? == false) and
		    (File.exists?(value) == false))
			return false
		end

		return super
	end
end

###
#
# OptionContainer
# ---------------
#
# The options purpose in life is to associate named options
# with arbitrary values at the most simplistic level.  Each
# module contains a OptionContainer that is used to hold the 
# various options that the module depends on.  Example of options
# that are stored in the OptionContainer are rhost and rport for
# payloads or exploits that need to connect to a host and
# port, for instance.
#
###
class OptionContainer < Hash

	# Merges in the supplied options and converts them to a OptBase
	# as necessary.
	def initialize(opts = {})
		add_options(opts)
	end

	# Return the value associated with the supplied name
	def [](name)
		return get(name)
	end

	# Return the option associated with the supplied name
	def get(name)
		return fetch(name)
	end

	# Adds one or more options
	def add_options(opts)
		return false if (opts == nil)

		opts.each_key { |name|
			option = opts[name]

			# Skip flags
			next if (name.match(/^_Flag/))

			if (option.kind_of?(Array))
				option = option.shift.new(name, option)
			elsif (!option.kind_of?(OptBase))
				raise ArgumentError, 
					"The option named #{name} did not come in a compatible format.", 
					caller
			end

			option.name = name

			# If the advanced flag was supplied, flag the new option as being
			# an advanced option
			if (opts['_FlagAdvanced'] == true)
				option.advanced = true
			end

			self.store(name, option)
		}
	end

	# Alias to add advanced options that sets the proper state flag
	def add_advanced_options(opts = {})
		opts['_FlagAdvanced'] = true if (opts)

		add_options(opts)
	end

	# Make sures that each of the options has a value of a compatible 
	# format and that all the required options are set
	def validate(datastore)
		errors = []

		each_pair { |name, option| 
			if (!option.valid?(datastore[name]))
				errors << name
			end
		}
		
		if (errors.empty? == false)
			raise OptionValidateError.new(errors), 
				"One or more options failed to validate", caller
		end

		return true
	end

	# Enumerates each option name
	def each_option(&block)
		each_pair(&block)
	end

end

module Test

begin
###
#
# OptionContainerTestCase
# -----------------------
#
# This class implements some testing routines for ensuring that the option
# container is operating correctly.
#
###
class OptionContainerTestCase < ::Test::Unit::TestCase
	# Tests the initialization of the OptionContainer object
	def test_initialize
		# Make sure initialization works
		options = nil

		assert_block("initialize failed") {
			options = OptionContainer.new(
				'rhost' => [ OptAddress, true, nil, 'host.com' ],
				'rport' => [ OptPort,    true, nil, 1234       ])

			if (options == nil)
				false
			end

			true
		}

		# Make sure there are 2 options
		assert_equal(2, options.length, "invalid number of options #{options.length}")

		# Make sure that the constructor raises an argument error when
		# an invalid option is supplied
		assert_raise(ArgumentError, "initialize invalid failed") {
			OptionContainer.new(
				'rhost' => 'invalid');
		}
	end

	# Tests getting the value of an option
	def test_get
		options = OptionContainer.new(
			'rport' => [ OptPort, true, nil, 1234 ])

		assert_equal(1234, options.get('rport').default, 
				"option default does not match")
		assert_equal(true, options.get('rport').required?, 
				"option required does not match")
		assert_equal('rport', options['rport'].name, 
				"option name does not match")
	end

	# Tests validation
	def test_validate
		# Test validating required options
		options = OptionContainer.new(
			'rhost' => [ OptAddress, true ],
			'rport' => [ OptPort,    true ],
			'Lib'   => [ OptString        ])

		ds = DataStore.new

		assert_raise(OptionValidateError, "required validation failed") {
			options.validate(ds)
		}

		ds['rhost'] = 'www.invalid.host.tldinvalid'
		ds['rport'] = 1234

		assert_raise(OptionValidateError, "host validation failed") {
			options.validate(ds)
		}

		# Make sure address validation does work
		ds['rhost'] = 'www.google.com'

		assert_equal(true, options.validate(ds), "overall validation failed")

		# Make sure port validation does work
		ds['rport'] = 23423423

		assert_raise(OptionValidateError, "port validation failed") {
			options.validate(ds)
		}
	end

	# Make sure advanced additions work
	def test_advanced
		options = OptionContainer.new

		options.add_advanced_options(
			'DONKEY' => [ OptString, false ])
			
		assert_equal(true, options.get('DONKEY').advanced?, 
				"advanced option failed")
	end
end
rescue
end

end

end
