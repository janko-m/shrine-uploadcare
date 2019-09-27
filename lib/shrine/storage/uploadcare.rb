require "shrine"
require "uploadcare"
require "down/http"
require "uri"
require "digest"

class Shrine
  module Storage
    class Uploadcare
      Error = Class.new(StandardError)

      attr_reader :api

      def initialize(**options)
        @api = ::Uploadcare::Api.new(**options)
      end

      def upload(io, id, shrine_metadata: {}, **upload_options)
        file = _upload(io, id, shrine_metadata: shrine_metadata, **upload_options)
        file.load_data

        update_metadata!(shrine_metadata, file)
        update_id!(id, file)

        file
      end

      def open(id, **options)
        Down::Http.open(url(id), **options)
      rescue Down::NotFound
        raise Shrine::FileNotFound, "file #{id.inspect} not found on storage"
      end

      def exists?(id)
        file = api.file(id)
        file.load_data
        !!file.datetime_stored
      rescue ::Uploadcare::Error::RequestError::NotFound
        false
      end

      def delete(id)
        file = api.file(id)
        file.delete
      end

      def url(id, **options)
        file = api.file(id)
        file.operations = options.map { |operation| operation.flatten.join("/") }
        file.cdn_url(true)
      end

      def presign(id = nil, **options)
        expire = Time.now.to_i + (options[:expires_in] || 60*60)
        secret_key = api.options[:private_key]

        signature = Digest::MD5.hexdigest(secret_key + expire.to_s)

        fields = {
          UPLOADCARE_PUB_KEY: api.options[:public_key],
          signature: signature,
          expire: expire,
        }

        url = URI.join(api.options[:upload_url_base], "base/").to_s

        { method: :post, url: url, fields: fields }
      end

      def clear!
        api.file_list(limit: 1000).each_slice(100) do |file_batch|
          api.delete_files(file_batch)
        end
      end

      private

      def _upload(io, id, shrine_metadata: {}, **upload_options)
        options = { store: true }
        options.merge!(upload_options)

        if remote_file?(io)
          api.upload_from_url(io.url, options)
        else
          Shrine.with_file(io) do |file|
            api.upload(file, options)
          end
        end
      end

      def update_metadata!(metadata, file)
        metadata.merge!(file.image_info.to_h)
        metadata.merge!("mime_type" => file.mime_type, "size" => file.size)
      end

      def update_id!(id, file)
        id.replace(file.uuid)
      end

      def remote_file?(io)
        io.is_a?(UploadedFile) && io.url.to_s =~ /^ftp:|^https?:/
      end
    end
  end
end

module Uploadcare
  module UploadingApi
    class UploadParams
      # fix determining MIME type
      def extract_mime_type(file)
        mime_type = MIME::Types.of(file.path).first
        mime_type.content_type if mime_type
      end
    end
  end
end
