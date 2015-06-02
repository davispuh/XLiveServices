require 'tempfile'
require 'libmspack'
require 'multi_xml'

module XLiveServices
    module Media
        class DownloadError < RuntimeError; end
        class DownloadForbidden < DownloadError; end

        def self.Download(urls, target, overwrite = false, keep = false)
            uris = []
            urls.each do |url|
                uris << [URI.parse(url), url]
            end
            uris.each do |uri|
                path = File::expand_path(File.basename(uri.first.path), target)
                request = HTTPI::Request.new(uri.last)
                response = nil
                file = nil
                begin
                    if overwrite or not File.exist?(path) or File::size(path).zero?
                        response = nil
                        file = File.open(path, 'wb')
                        request.on_body do |data|
                            file.write(data)
                        end
                        yield(request, path)
                        response = HTTPI.get(request)
                        if response.error?
                            file.truncate(0)
                            if response.code == 403
                                raise DownloadForbidden.new(response.body)
                            else
                                raise DownloadError.new(response.code)
                            end
                        end
                        file.close
                        file = nil
                    else
                        yield(nil, path)
                    end
                    urls.delete(uri.last)
                rescue Exception => e
                    file.close if file
                    FileUtils.remove_file(path, true) unless keep
                    raise e
                end
            end
        end

        def self.IsManifest?(path)
            parts = path.split('.')
            return false if parts.length < 2
            parts[-2].end_with?('_manifest')
        end

        def self.IsSupportedManifest?(path)
            path.end_with?('.cab')
        end

        def self.GetManifestLinks(manifest_cab)
            links = []
            decompressor = LibMsPack::CabDecompressor.new
            decompressor.setParam(LibMsPack::MSCABD_PARAM_FIXMSZIP, 1)
            cab = decompressor.open(manifest_cab)
            begin
                file = cab.files
                begin
                    if file.getFilename.casecmp('Content\OfferManifest.xml').zero?
                        xmlFile = Tempfile.new('manifest_xml')
                        decompressor.extract(file, xmlFile.path)
                        begin
                            xmlFile.open
                            data = MultiXml.parse(xmlFile)
                            items = data['OfferManifest']['Items']['Item']
                            items = [items] unless items.is_a?(Array)
                            items.each do |item|
                                links << item['Link']['Url']
                            end
                        ensure
                            xmlFile.close
                            xmlFile.unlink
                        end
                        break
                    end
                end until (file = file.next).nil?
            ensure
                decompressor.close(cab)
                decompressor.destroy
            end
            links
        end

    end
end
