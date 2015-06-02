require 'savon'
require 'base64'

module XLiveServices
    class MarketplacePublic
        extend Savon::Model
        client endpoint: '', namespace: 'http://tempuri.org/'
        global :env_namespace, :s
        global :namespace_identifier, :t
        global :convert_request_keys_to, :none
        global :element_form_default, :qualified
        global :convert_response_tags_to, :camelcase
        global :soap_version, 2
        global :namespaces, { 'xmlns:a' => 'http://www.w3.org/2005/08/addressing' }
        global :ssl_version, :SSLv23

        ConfigurationName = 'IMarketplacePublic'

        module SortField
            Title = :Title
            AvailabilityDate = :AvailabilityDate
            LastPlayedDate = :LastPlayedDate
        end

        def initialize(endpoint, wgxService)
            @WgxService = wgxService
            client.globals[:endpoint] = endpoint
        end

        def self.BuildOfferGUID(offerID, titleID=nil)
            titleID = offerID >> 32 if titleID.nil?
            offerID &= 0xffffffff
            "%08x-0000-4000-8000-0000%08x" % [offerID, titleID]
        end

        def BuildOfferGUID(offerID, titleID=nil)
            self.class.BuildOfferGUID(offerID, titleID)
        end

        def GetHeader(name)
            Utils::BuildHeader(client.globals[:endpoint], Utils::BuildAction(client.globals[:namespace], ConfigurationName, name.to_s), @WgxService.Token)
        end

        def GetPurchaseHistory(locale, pageNum = 1, orderBy = SortField::Title)
            client.globals[:soap_header] = GetHeader(__callee__)
            client.call __callee__, message: { locale: locale, pageNum: pageNum, orderBy: Utils::Serialization::Serialize(orderBy, 'enum') }
        end

        def ReadUserSettings(titleID, settings)
            client.globals[:soap_header] = GetHeader(__callee__)
            client.call __callee__, message: { titleID: titleID, settings: Utils::Serialization::Serialize(settings, 'uint[]') }
        end

        def GetOfferDetailsPublic(locale, offerGUID)
            client.globals[:soap_header] = GetHeader(__callee__)
            client.call __callee__, message: { locale: locale, offerId: offerGUID }
        end

        def GetLicensePublic(offerGUID)
            client.globals[:soap_header] = GetHeader(__callee__)
            client.call __callee__, message: { offerId: offerGUID }
        end

        def GetSponsorToken(titleId)
            client.globals[:soap_header] = GetHeader(__callee__)
            client.call __callee__, message: { titleId: titleId }
        end

        def GetActivationKey(offerGUID)
            client.globals[:soap_header] = GetHeader(__callee__)
            client.call __callee__, message: { offerId: offerGUID }
        end

        def GetMediaUrls(urls, offerGUID)
            client.globals[:soap_header] = GetHeader(__callee__)
            client.call __callee__, message: { urls: Utils::Serialization::Serialize(urls, 'string[]'), offerID: offerGUID }
        end

    end
end
