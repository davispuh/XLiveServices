require 'httpi'
require 'multi_xml'
require 'live_identity'

module XLiveServices
    class XLiveServicesError < RuntimeError
        attr_accessor :Code
        attr_accessor :Body
    end
    class XLiveServicesUnauthorized < XLiveServicesError; end

    def self.GetLcwConfig(locale = 'en-US')
        raise XLiveServicesError.new('Invalid Locale!') if locale.nil? or locale.empty?
        request = HTTPI::Request.new("https://live.xbox.com/#{locale}/GetLcwConfig.ashx")
        request.auth.ssl.ca_cert_file = CERT_FILE
        request.auth.ssl.ssl_version = :TLSv1_2
        request.auth.ssl.verify_mode = :none if LiveIdentity.isAvailable?
        response = HTTPI.get(request)
        raise "Error! HTTP Status Code: #{response.code}" if response.error?
        XLiveServices.ParseConfig(MultiXml.parse(response.body))
    end

    def self.ParseConfig(config)
        parsed = { :Auth => {}, :URL => {} }
        config['Environment']['Authentication']['AuthSetting'].each do |setting|
            parsed[:Auth][setting['name'].to_sym] = { ServiceName: setting['serviceName'], Policy: setting['policy'].to_sym }
        end
        config['Environment']['UrlSettings']['UrlSetting'].each do |setting|
            parsed[:URL][setting['name'].to_sym] = [ setting['url'], setting['authKey'].empty? ? nil : setting['authKey'].to_sym ]
        end
        parsed
    end

    def self.DoAuth(identity, serviceName, policy)
        return nil unless identity
        identity.GetService(serviceName, policy)
    end

    def self.GetUserAuthService(identity, config)
        configData = config[:Auth][config[:URL][:GetUserAuth].last]
        DoAuth(identity, configData[:ServiceName], configData[:Policy])
    end

    def self.GetWgxService(identity, config)
        configData = config[:Auth][config[:URL][:WgxService].last]
        DoAuth(identity, configData[:ServiceName], configData[:Policy])
    end

    def self.GetUserAuthorization(url, userAuthService)
        raise XLiveServicesError.new('Invalid AuthService Token!') if userAuthService.nil? or userAuthService.Token.nil? or userAuthService.Token.empty?
        request = HTTPI::Request.new(url)
        request.body = { :serviceType => 1, :titleId => 0 }
        request.headers['Content-Type'] = 'application/x-www-form-urlencoded'
        request.headers['Authorization'] = "WLID1.0 #{userAuthService.Token}"
        request.headers['X-ClientType']  = 'panorama'
        request.auth.ssl.ca_cert_file = CERT_FILE
        request.auth.ssl.verify_mode = :none if LiveIdentity.isAvailable?
        response = HTTPI.post(request)
        if response.error?
            message = "Error! HTTP Status Code: #{response.code}"
            error_class = XLiveServicesError
            error_class = XLiveServicesUnauthorized if response.code == 401
            error_exception = error_class.new(message)
            error_exception.Code = response.code
            error_exception.Body = response.body
            raise error_exception
        end
        MultiXml.parse(response.body)
    end

    def self.UserLogout(config)
        request = HTTPI::Request.new(config[:URL][:Logout].first)
        response = HTTPI.get(request)
        raise XLiveServicesError.new("Error! HTTP Status Code: #{response.code} #{response.body}") if response.error?
        response.body
    end
end
