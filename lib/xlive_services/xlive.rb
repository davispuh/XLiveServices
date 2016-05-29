module XLiveServices
    class XLive
        LiveIdGUID = '{D34F9E47-A73B-44E5-AE67-5D0D8B8CFA76}'
        LiveIdVersion = 1
        attr_reader :Locale
        attr_reader :Config
        attr_reader :Live
        attr_reader :Identity
        attr_reader :Username
        def initialize(username = nil, password = nil, locale = nil)
            @Locale = 'en-US'
            @Locale = locale if locale
            @Config = XLiveServices.GetLcwConfig(@Locale)
            @Live   = nil
            @Identity = nil

            if LiveIdentity.isAvailable?
                @Live = LiveIdentity.new(LiveIdGUID, LiveIdVersion, :NO_UI, { :IDCRL_OPTION_ENVIRONMENT => 'Production' })
            end

            if username.nil? and @Live
                identities = @Live.GetIdentities(LiveIdentity::PPCRL_CREDTYPE_PASSWORD)
                @Username = identities.GetNextIdentityName
                if !@Username
                    identities = @Live.GetIdentities(LiveIdentity::PPCRL_CREDTYPE_MEMBERNAMEONLY)
                    @Username = identities.GetNextIdentityName
                end
                raise XLiveServicesError.new('No Username!') unless @Username
            else
                @Username = username
            end

            if @Live
                @Identity = @Live.GetIdentity(@Username, :IDENTITY_SHARE_ALL)
                if !@Identity.HasPersistedCredential?(LiveIdentity::PPCRL_CREDTYPE_MEMBERNAMEONLY)
                   @Identity.SetCredential(LiveIdentity::PPCRL_CREDTYPE_MEMBERNAMEONLY, @Username)
                end
            end

            if @Identity
                if password
                    @Identity.SetCredential(LiveIdentity::PPCRL_CREDTYPE_PASSWORD, password)
                elsif !@Identity.HasPersistedCredential?(LiveIdentity::PPCRL_CREDTYPE_PASSWORD)
                    raise XLiveServicesError.new("No Password for #{@Username}!")
                end
            end
        end

        def PersistCredentials
            return false unless @Identity
            @Identity.PersistCredential(LiveIdentity::PPCRL_CREDTYPE_MEMBERNAMEONLY)
            @Identity.PersistCredential(LiveIdentity::PPCRL_CREDTYPE_PASSWORD)
        end

        def RemovePersistedCredentials
            return false unless @Identity
            @Identity.RemovePersistedCredential(LiveIdentity::PPCRL_CREDTYPE_PASSWORD)
            @Identity.RemovePersistedCredential(LiveIdentity::PPCRL_CREDTYPE_MEMBERNAMEONLY)
        end

        def IsAuthenticated?
            if @Identity
                @Identity.IsAuthenticated?
            else
               nil
            end
        end

        def Authenticate
            return true if IsAuthenticated?()
            return false unless @Identity
            @Identity.Authenticate(nil, :LOGONIDENTITY_ALLOW_PERSISTENT_COOKIES)
        end

        def SetUserAuthService(service)
            @GetUserAuthService = service
        end

        def GetUserAuthService()
            @GetUserAuthService ||= XLiveServices.GetUserAuthService(@Identity, @Config)
        end

        def GetUserAuthorizationInfo(authURL = nil)
            authURL = @Config[:URL][:GetUserAuth].first if authURL.nil?
            userAuthorization = XLiveServices.GetUserAuthorization(authURL, GetUserAuthService())
            userAuthorization['GetUserAuthorizationInfo']
        end

        def SetWgxService(service)
            @WgxService = service
        end

        def GetWgxService
            @WgxService ||= XLiveServices.GetWgxService(@Identity, @Config)
        end

        def GetMarketplace(host = nil, path = nil)
            # Main service url https://services.gamesforwindows.com/SecurePublic/MarketPlacePublic.svc
            # Alternative service url https://services.gamesforwindows.com/SecurePublic/MarketplaceRestSecure.svc
            uri = URI(@Config[:URL][:WgxService].first)
            uri.host = host if host # eg. services.xboxlive.com
            uri.path = path if path
            XLiveServices::MarketplacePublic.new(uri.to_s, GetWgxService())
        end
    end
end
