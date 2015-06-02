require 'pathname'

ENV['SSL_CERT_FILE'] = Pathname.new("#{File.dirname(__FILE__)}/../data/certs.pem").realpath.to_s

require 'xlive_services/version'
require 'xlive_services/utils'
require 'xlive_services/xlive_services'
require 'xlive_services/marketplace_public'
require 'xlive_services/xlive'
require 'xlive_services/media'
require 'xlive_services/hresult'
