#!/usr/bin/ruby

module Rex
module Post
module Meterpreter
module Extensions
module Stdapi

##
#
# General
#
##

TLV_TYPE_HANDLE             = TLV_META_TYPE_UINT    |  600
TLV_TYPE_INHERIT            = TLV_META_TYPE_BOOL    |  601
TLV_TYPE_PROCESS_HANDLE     = TLV_META_TYPE_UINT    |  630
TLV_TYPE_THREAD_HANDLE      = TLV_META_TYPE_UINT    |  631

##
#
# Fs
#
##

TLV_TYPE_DIRECTORY_PATH     = TLV_META_TYPE_STRING  | 1200
TLV_TYPE_FILE_NAME          = TLV_META_TYPE_STRING  | 1201
TLV_TYPE_FILE_PATH          = TLV_META_TYPE_STRING  | 1202
TLV_TYPE_FILE_MODE          = TLV_META_TYPE_STRING  | 1203
TLV_TYPE_STAT_BUF           = TLV_META_TYPE_COMPLEX | 1220

##
#
# Net
#
##
TLV_TYPE_HOST_NAME          = TLV_META_TYPE_STRING  | 1400
TLV_TYPE_PORT               = TLV_META_TYPE_UINT    | 1401

TLV_TYPE_SUBNET             = TLV_META_TYPE_RAW     | 1420
TLV_TYPE_NETMASK            = TLV_META_TYPE_RAW     | 1421
TLV_TYPE_GATEWAY            = TLV_META_TYPE_RAW     | 1422
TLV_TYPE_NETWORK_ROUTE      = TLV_META_TYPE_GROUP   | 1423

TLV_TYPE_IP                 = TLV_META_TYPE_RAW     | 1430
TLV_TYPE_MAC_ADDRESS        = TLV_META_TYPE_RAW     | 1431
TLV_TYPE_MAC_NAME           = TLV_META_TYPE_STRING  | 1432
TLV_TYPE_NETWORK_INTERFACE  = TLV_META_TYPE_GROUP   | 1433

TLV_TYPE_SUBNET_STRING      = TLV_META_TYPE_STRING  | 1440
TLV_TYPE_NETMASK_STRING     = TLV_META_TYPE_STRING  | 1441
TLV_TYPE_GATEWAY_STRING     = TLV_META_TYPE_STRING  | 1442

# Socket
TLV_TYPE_PEER_HOST          = TLV_META_TYPE_STRING  | 1500
TLV_TYPE_PEER_PORT          = TLV_META_TYPE_UINT    | 1501
TLV_TYPE_LOCAL_HOST         = TLV_META_TYPE_STRING  | 1502
TLV_TYPE_LOCAL_PORT         = TLV_META_TYPE_UINT    | 1503
TLV_TYPE_CONNECT_RETRIES    = TLV_META_TYPE_UINT    | 1504

TLV_TYPE_SHUTDOWN_HOW       = TLV_META_TYPE_UINT    | 1530

##
#
# Sys
#
##

PROCESS_EXECUTE_FLAG_HIDDEN      = (1 << 0)
PROCESS_EXECUTE_FLAG_CHANNELIZED = (1 << 1)
PROCESS_EXECUTE_FLAG_SUSPENDED   = (1 << 2)

# Registry
TLV_TYPE_HKEY               = TLV_META_TYPE_UINT    | 1000
TLV_TYPE_ROOT_KEY           = TLV_TYPE_HKEY
TLV_TYPE_BASE_KEY           = TLV_META_TYPE_STRING  | 1001
TLV_TYPE_PERMISSION         = TLV_META_TYPE_UINT    | 1002
TLV_TYPE_KEY_NAME           = TLV_META_TYPE_STRING  | 1003
TLV_TYPE_VALUE_NAME         = TLV_META_TYPE_STRING  | 1010
TLV_TYPE_VALUE_TYPE         = TLV_META_TYPE_UINT    | 1011
TLV_TYPE_VALUE_DATA         = TLV_META_TYPE_RAW     | 1012

DELETE_KEY_FLAG_RECURSIVE   = (1 << 0)

# Process
TLV_TYPE_BASE_ADDRESS       = TLV_META_TYPE_UINT    | 2000
TLV_TYPE_ALLOCATION_TYPE    = TLV_META_TYPE_UINT    | 2001
TLV_TYPE_PROTECTION         = TLV_META_TYPE_UINT    | 2002
TLV_TYPE_PROCESS_PERMS      = TLV_META_TYPE_UINT    | 2003
TLV_TYPE_PROCESS_MEMORY     = TLV_META_TYPE_RAW     | 2004
TLV_TYPE_ALLOC_BASE_ADDRESS = TLV_META_TYPE_UINT    | 2005
TLV_TYPE_MEMORY_STATE       = TLV_META_TYPE_UINT    | 2006
TLV_TYPE_MEMORY_TYPE        = TLV_META_TYPE_UINT    | 2007
TLV_TYPE_ALLOC_PROTECTION   = TLV_META_TYPE_UINT    | 2008
TLV_TYPE_PID                = TLV_META_TYPE_UINT    | 2300
TLV_TYPE_PROCESS_NAME       = TLV_META_TYPE_STRING  | 2301
TLV_TYPE_PROCESS_PATH       = TLV_META_TYPE_STRING  | 2302
TLV_TYPE_PROCESS_GROUP      = TLV_META_TYPE_GROUP   | 2303
TLV_TYPE_PROCESS_FLAGS      = TLV_META_TYPE_UINT    | 2304
TLV_TYPE_PROCESS_ARGUMENTS  = TLV_META_TYPE_STRING  | 2305

TLV_TYPE_IMAGE_FILE         = TLV_META_TYPE_STRING  | 2400
TLV_TYPE_IMAGE_FILE_PATH    = TLV_META_TYPE_STRING  | 2401
TLV_TYPE_PROCEDURE_NAME     = TLV_META_TYPE_STRING  | 2402
TLV_TYPE_PROCEDURE_ADDRESS  = TLV_META_TYPE_UINT    | 2403
TLV_TYPE_IMAGE_BASE         = TLV_META_TYPE_UINT    | 2404
TLV_TYPE_IMAGE_GROUP        = TLV_META_TYPE_GROUP   | 2405
TLV_TYPE_IMAGE_NAME         = TLV_META_TYPE_STRING  | 2406

TLV_TYPE_THREAD_ID          = TLV_META_TYPE_UINT    | 2500
TLV_TYPE_THREAD_PERMS       = TLV_META_TYPE_UINT    | 2502
TLV_TYPE_EXIT_CODE          = TLV_META_TYPE_UINT    | 2510
TLV_TYPE_ENTRY_POINT        = TLV_META_TYPE_UINT    | 2511
TLV_TYPE_ENTRY_PARAMETER    = TLV_META_TYPE_UINT    | 2512
TLV_TYPE_CREATION_FLAGS     = TLV_META_TYPE_UINT    | 2513

TLV_TYPE_REGISTER_NAME      = TLV_META_TYPE_STRING  | 2540
TLV_TYPE_REGISTER_SIZE      = TLV_META_TYPE_UINT    | 2541
TLV_TYPE_REGISTER_VALUE_32  = TLV_META_TYPE_UINT    | 2542
TLV_TYPE_REGISTER           = TLV_META_TYPE_GROUP   | 2550

##
#
# Ui
#
##
TLV_TYPE_IDLE_TIME          = TLV_META_TYPE_UINT    | 3000

##
#
# Event Log
#
##
TLV_TYPE_EVENT_SOURCENAME   = TLV_META_TYPE_STRING  | 4000
TLV_TYPE_EVENT_HANDLE       = TLV_META_TYPE_UINT    | 4001
TLV_TYPE_EVENT_NUMRECORDS   = TLV_META_TYPE_UINT    | 4002

TLV_TYPE_EVENT_READFLAGS    = TLV_META_TYPE_UINT    | 4003
TLV_TYPE_EVENT_RECORDOFFSET = TLV_META_TYPE_UINT    | 4004

TLV_TYPE_EVENT_RECORDNUMBER = TLV_META_TYPE_UINT    | 4006
TLV_TYPE_EVENT_TIMEGENERATED= TLV_META_TYPE_UINT    | 4007
TLV_TYPE_EVENT_TIMEWRITTEN  = TLV_META_TYPE_UINT    | 4008
TLV_TYPE_EVENT_ID           = TLV_META_TYPE_UINT    | 4009
TLV_TYPE_EVENT_TYPE         = TLV_META_TYPE_UINT    | 4010
TLV_TYPE_EVENT_CATEGORY     = TLV_META_TYPE_UINT    | 4011
TLV_TYPE_EVENT_STRING       = TLV_META_TYPE_STRING  | 4012
TLV_TYPE_EVENT_DATA         = TLV_META_TYPE_RAW     | 4013

end; end; end; end; end
