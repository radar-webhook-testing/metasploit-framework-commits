#
# Log severities
#
LOG_ERROR = 'error'
LOG_DEBUG = 'debug'
LOG_INFO  = 'info'
LOG_WARN  = 'warn'
LOG_RAW   = 'raw'

##
#
# Log levels
#
##

# 
# LEV_0 - Default
#
# This log level is the default log level if none is specified.  It should be
# used when a log message should always be displayed when logging is enabled.
# Very few log messages should occur at this level aside from necessary
# information logging and error/warning logging.  Debug logging at level zero
# is not advised.
#
LEV_0     = 0

#
# LEV_1 - Extra
#
# This log level should be used when extra information may be needed to
# understand the cause of an error or warning message or to get debugging
# information that might give clues as to why something is happening.  This 
# log level should be used only when information may be useful to understanding
# the behavior of something at a basic level.  This log level should not be
# used in an exhaustively verbose fashion.
#
LEV_1     = 1

#
# LEV_2 - Verbose
#
# This log level should be used when verbose information may be needed to
# analyze the behavior of the framework.  This should be the default log
# level for all detailed information not falling into LEV_0 or LEV_1.
# It is recommended that this log level be used by default if you are
# unsure.
#
LEV_2     = 2

#
# LEV_3 - Insanity
#
# This log level should contain very verbose information about the 
# behavior of the framework, such as detailed information about variable
# states at certain phases including, but not limited to, loop iterations,
# function calls, and so on.  This log level will rarely be displayed, 
# but when it is the information provided should make it easy to analyze
# any problem.
#
LEV_3     = 3


#
# Architecture constants
#
ARCH_ANY   = '_any_'
ARCH_X86   = 'x86'
ARCH_MIPS  = 'mips'
ARCH_PPC   = 'ppc'
ARCH_SPARC = 'sparc'
ARCH_CMD   = 'cmd'
ARCH_PHP   = 'php'
ARCH_TYPES =
	[
		ARCH_X86,
		ARCH_MIPS,
		ARCH_PPC,
		ARCH_SPARC,
		ARCH_CMD,
		ARCH_PHP
	]

ARCH_ALL = ARCH_TYPES

#
# Endian constants
#
ENDIAN_LITTLE = 0
ENDIAN_BIG    = 1

IS_ENDIAN_LITTLE = ( [1].pack('s')[0] == 1 ) ? true : false
IS_ENDIAN_BIG    = ( not IS_ENDIAN_LITTLE )

