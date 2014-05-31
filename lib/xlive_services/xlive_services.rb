require 'httpi'
require 'multi_xml'
require 'live_identity'

module XLiveServices
    class XLiveServicesError < RuntimeError; end

    def self.GetLcwConfig(locale = 'en-US')
        raise XLiveServicesError.new('Invalid Locale!') if locale.nil? or locale.empty?
        response = HTTPI.get(HTTPI::Request.new("https://live.xbox.com/#{locale}/GetLcwConfig.ashx"))
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
        raise XLiveServicesError.new('Invalid AuthService Token!') if userAuthService.Token.nil? or userAuthService.Token.empty?
        request = HTTPI::Request.new(url)
        request.body = { :serviceType => 1, :titleId => 0 }
        request.headers['Authorization'] = "WLID1.0 #{userAuthService.Token}"
        request.headers['X-ClientType']  = 'panorama'
        response = HTTPI.post(request)
        raise "Error! HTTP Status Code: #{response.code} #{response.body}" if response.error?
        MultiXml.parse(response.body)
    end

    def self.UserLogout(config)
        request = HTTPI::Request.new(config[:URL][:Logout].first)
        response = HTTPI.get(request)
        raise XLiveServicesError.new("Error! HTTP Status Code: #{response.code} #{response.body}") if response.error?
        response.body
    end
end
