require 'builder/xchar'

module XLiveServices
    module Utils
        def self.BuildHeader(endpoint, action, compactRPSTicket)
            %{
            <a:Action s:mustUnderstand="1">#{action}</a:Action>
            <a:To s:mustUnderstand="1">#{endpoint}</a:To>
            <o:Security s:mustUnderstand="1" xmlns:o="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
              <cct:RpsSecurityToken wsu:Id="00000000-0000-0000-0000-000000000000" xmlns:cct="http://samples.microsoft.com/wcf/security/Extensibility/" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">
                <cct:RpsTicket>#{Builder::XChar.encode(compactRPSTicket)}</cct:RpsTicket>
              </cct:RpsSecurityToken>
            </o:Security>
        }
        end

        def self.BuildAction(namespace, configurationName, name)
            namespace + configurationName + '/' + name
        end

        def self.CleanURLs(urls)
            clean = []
            urls.each do |url|
                uri = URI.parse(url)
                uri.query = nil
                uri.fragment = nil
                clean << uri.to_s
            end
            clean
        end

        class Serialization
            def self.Serialize(data, type)
                serialized = {}
                case type
                when 'enum'
                    serialized = data.to_s
                when 'uint[]'
                    serialized[:'@xmlns:b'] = 'http://schemas.microsoft.com/2003/10/Serialization/Arrays'
                    serialized[:content!] = { 'b:unsignedInt' => data }
                when 'string[]'
                    serialized[:'@xmlns:b'] = 'http://schemas.microsoft.com/2003/10/Serialization/Arrays'
                    serialized[:content!] = { 'b:string' => data }
                end
                serialized
            end

            def self.Deserialize(data, type)
                unserialized = nil
                case type
                when 'string[]'
                    unserialized = data['string']
                    unserialized = [] unless unserialized
                    unserialized = [unserialized] unless unserialized.is_a?(Array)
                end
                unserialized
            end
        end
    end
end
