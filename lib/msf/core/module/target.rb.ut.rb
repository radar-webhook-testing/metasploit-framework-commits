#!/usr/bin/ruby

$:.unshift(File.join('..', '..', '..', File.dirname(__FILE__)))

require 'test/unit'
require 'Msf/Core'

module Msf

class Module::Target::UnitTest < Test::Unit::TestCase
	def test_target
		t = Target.from_a(['Universal', {
				'Platform' => 'winxpsp0',
				'Ret'      => 0x12345678 
			}])

		assert_equal('Universal', t.name)
		assert_equal(true, t.platforms.supports?(Msf::Module::PlatformList.transform('winxpsp0')))
		assert_equal(false, t.platforms.supports?(Msf::Module::PlatformList.transform('winxpsp1')))
		assert_equal(0x12345678, t['Ret'])
		assert_equal(0x12345678, t.ret)
	end
end

end
