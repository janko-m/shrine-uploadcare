require "shrine"
require "uploadcare"
require "down"
require "uri"
require "digest"

class Shrine
  module Storage
    class Uploadcare
      Error = Class.new(StandardError)

      attr_reader :uploadcare

      def initialize(store_info: false, upload_options: {}, **options)
        @uploadcare = ::Uploadcare::Api.new(api_version: "0.5", **options)
        @store_info = store_info
        @upload_options = upload_options
      end

      def upload(io, id, shrine_metadata: {}, **upload_options)
        result = _upload(io, id, shrine_metadata: shrine_metadata, **upload_options)
        update_metadata!(shrine_metadata, result)
        update_id!(id, result)
      end

      def open(id)
        Down.open(url(id))
      end

      def exists?(id)
        response = api_client.get("/files/#{id}/")
        !!response.body["datetime_stored"]
      rescue ::Uploadcare::Error::RequestError::NotFound
        false
      end

      def delete(id)
        api_client.delete("/files/#{id}/storage/")
      end

      def url(id, **options)
        operations = options.to_a.map { |operation| operation.flatten.join("/") }
        file(id, operations).cdn_url(true)
      end

      def clear!
        response = api_client.get("/files/", stored: true, limit: 1000)
        loop do
          uuids = response.body["results"].map { |result| result.fetch("uuid") }
          multi_delete(uuids) unless uuids.empty?
          return if (next_url = response.body["next"]).nil?
          response = api_client.get(URI(next_url).request_uri)
        end
      end

      def presign(id = nil, **options)
        expire = Time.now.to_i + (options[:expires_in] || 60*60)
        secret_key = uploadcare.options[:private_key]

        signature = Digest::MD5.hexdigest(secret_key + expire.to_s)

        fields = {
          UPLOADCARE_PUB_KEY: uploadcare.options[:public_key],
          signature: signature,
          expire: expire,
        }

        url = upload_client.url_prefix + "base/"

        Struct.new(:url, :fields).new(url, fields)
      end

      protected

      def file(id, operations = [])
        ::Uploadcare::Api::File.new(uploadcare, id, operations: operations)
      end

      private

      def _upload(io, id, **options)
        if uploadcare_file?(io)
          store(io, id, **options)
        else
          create(io, id, **options)
        end
      end

      def store(io, id, **options)
        response = api_client.put "/files/#{io.id}/storage/"
        response.body
      end

      def create(io, id, **options)
        if remote_file?(io)
          create_from_url(io, id, **options)
        else
          create_from_file(io, id, **options)
        end
      end

      def create_from_url(io, id, shrine_metadata: {}, **upload_options)
        options = {source_url: io.url, store: 1, pub_key: uploadcare.options[:public_key]}
        options.update(@upload_options).update(upload_options)
        response = upload_client.post "/from_url/", options
        token = response.body.fetch("token")

        loop do
          response = upload_client.get "/from_url/status/", token: token
          raise Error, response.body["error"] if response.body["status"] == "error"
          break response.body if response.body["status"] == "success"
          sleep 0.5
        end
      rescue ::Uploadcare::Error::RequestError::Forbidden => error
        raise Error, "You must allow \"automatic file storing\" in project settings"
      end

      def create_from_file(io, id, shrine_metadata: {}, **upload_options)
        options = {UPLOADCARE_PUB_KEY: uploadcare.options[:public_key], UPLOADCARE_STORE: 1}
        options.update(@upload_options).update(upload_options)
        io = Faraday::UploadIO.new(io, shrine_metadata["mime_type"], shrine_metadata["filename"])
        io.instance_eval { def length; size; end } # hack for multipart-post
        response = upload_client.post "/base/", file: io, **options
        {"uuid" => response.body.fetch("file")}
      rescue ::Uploadcare::Error::RequestError::Forbidden => error
        raise Error, "You must allow \"automatic file storing\" in project settings"
      end

      def api_client
        uploadcare.instance_variable_get("@api_connection")
      end

      def upload_client
        uploadcare.instance_variable_get("@upload_connection")
      end

      def update_metadata!(metadata, result)
        retrieved_metadata = {
          "mime_type" => result["mime_type"],
          "width"     => result["image_info"] && result["image_info"]["width"],
          "height"    => result["image_info"] && result["image_info"]["height"],
          "size"      => result["size"],
        }
        retrieved_metadata.reject! { |key, value| value.nil? }
        retrieved_metadata["uploadcare"] = result if @store_info

        metadata.update(retrieved_metadata)
      end

      def update_id!(id, result)
        id.replace(result.fetch("uuid"))
      end

      def uploadcare_file?(io)
        io.is_a?(UploadedFile) && io.storage.is_a?(Storage::Uploadcare)
      end

      def remote_file?(io)
        io.is_a?(UploadedFile) && io.url.to_s =~ /^ftp:|^https?:/
      end
    end
  end
end
