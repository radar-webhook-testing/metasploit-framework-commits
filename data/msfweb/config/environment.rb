ENV['RAILS_ENV'] = 'production'


# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '1.2.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|

end


msfbase = File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__
$:.unshift(File.join(File.dirname(msfbase), '..', '..', '..', 'lib'))

require 'rex'
require 'msf/ui'
require 'msf/base'

$msfweb      = Msf::Ui::Web::Driver.new({'LogLevel' => 5})
$msframework = $msfweb.framework

if ($browser_start)
	Thread.new do
		
		select(nil, nil, nil, 0.5)
		
		case RUBY_PLATFORM
		when /mswin32/
			system("start #{$browser_url}")
		when /darwin/
			system("open #{$browser_url}")
		else
			system("firefox #{$browser_url} &")
		end
	end
end
