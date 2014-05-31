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
            @Live = LiveIdentity.new(LiveIdGUID, LiveIdVersion, :NO_UI, { :IDCRL_OPTION_ENVIRONMENT => 'Production' })

            if username.nil?
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

            @Identity = @Live.GetIdentity(@Username, :IDENTITY_SHARE_ALL)
            if !@Identity.HasPersistedCredential?(LiveIdentity::PPCRL_CREDTYPE_MEMBERNAMEONLY)
                @Identity.SetCredential(LiveIdentity::PPCRL_CREDTYPE_MEMBERNAMEONLY, @Username)
            end

            if password
                @Identity.SetCredential(LiveIdentity::PPCRL_CREDTYPE_PASSWORD, password)
            elsif !@Identity.HasPersistedCredential?(LiveIdentity::PPCRL_CREDTYPE_PASSWORD)
                raise XLiveServicesError.new("No Password for #{@Username}!")
            end
        end

        def PersistCredentials
            @Identity.PersistCredential(LiveIdentity::PPCRL_CREDTYPE_MEMBERNAMEONLY)
            @Identity.PersistCredential(LiveIdentity::PPCRL_CREDTYPE_PASSWORD)
        end

        def RemovePersistedCredentials
            @Identity.RemovePersistedCredential(LiveIdentity::PPCRL_CREDTYPE_PASSWORD)
            @Identity.RemovePersistedCredential(LiveIdentity::PPCRL_CREDTYPE_MEMBERNAMEONLY)
        end

        def IsAuthenticated?
            @Identity.IsAuthenticated?
        end

        def Authenticate
            return if IsAuthenticated?()
            @Identity.Authenticate(nil, :LOGONIDENTITY_ALLOW_PERSISTENT_COOKIES)
        end

        def GetUserAuthService
            @GetUserAuthService ||= XLiveServices.GetUserAuthService(@Identity, @Config)
        end

        def GetUserAuthorizationInfo
            userAuthorization = XLiveServices.GetUserAuthorization(@Config[:URL][:GetUserAuth].first, GetUserAuthService())
            userAuthorization['GetUserAuthorizationInfo']
        end

        def GetWgxService
            @WgxService ||= XLiveServices.GetWgxService(@Identity, @Config)
        end

        def GetMarketplace
            # Alternative service url https://services.gamesforwindows.com/SecurePublic/MarketplaceRestSecure.svc
            XLiveServices::MarketplacePublic.new(@Config[:URL][:WgxService].first, GetWgxService())
        end
    end
end
