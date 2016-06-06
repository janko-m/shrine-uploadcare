require "test_helper"
require "shrine/storage/linter"

describe Shrine::Storage::Uploadcare do
  def uploadcare(**options)
    options[:public_key]  ||= ENV.fetch("UPLOADCARE_PUBLIC_KEY")
    options[:private_key] ||= ENV.fetch("UPLOADCARE_SECRET_KEY")

    Shrine::Storage::Uploadcare.new(**options)
  end

  before do
    @uploadcare = uploadcare
    shrine = Class.new(Shrine)
    shrine.storages[:uploadcare] = @uploadcare
    @uploader = shrine.new(:uploadcare)
  end

  after do
    @uploadcare.clear!
  end

  it "passes the linter" do
    Shrine::Storage::Linter.new(uploadcare).call(->{image})
  end

  describe "#upload" do
    it "uploads IOs" do
      @uploadcare.upload(FakeIO.new(image.read), id = "foo")
    end

    it "applies upload options" do
      @uploadcare = uploadcare(upload_options: {UPLOADCARE_STORE: 0})
      @uploadcare.upload(image, id = "foo")
      response = @uploadcare.send(:api_client).get("/files/#{id}/")
      assert_equal nil, response.body.fetch("datetime_stored")
    end

    it "uploads remote files" do
      remote_file = @uploader.upload(image)
      @uploadcare.instance_eval { def uploadcare_file?(io) false end }
      @uploadcare.upload(remote_file, id = "foo")
      response = @uploadcare.send(:api_client).get("/files/#{id}/")
      refute_equal nil, response.body.fetch("datetime_stored")
    end

    it "uploads uploadcare files" do
      uploadcare_file = @uploader.upload(image)
      @uploadcare.upload(uploadcare_file, id = "foo")
      response = @uploadcare.send(:api_client).get("/files/#{id}/")
      refute_equal nil, response.body.fetch("datetime_stored")
    end

    it "updates metadata" do
      @uploader.instance_eval { def extract_metadata(*) {"mime_type" => "image/jpeg"} end }
      uploadcare_file = @uploader.upload(image)
      uploaded_file = @uploader.upload(uploadcare_file)
      assert_equal "image/jpeg", uploaded_file.metadata["mime_type"]
      assert_equal 100,          uploaded_file.metadata["width"]
      assert_equal 67,           uploaded_file.metadata["height"]
      assert_equal image.size,   uploaded_file.metadata["size"]
    end

    it "can store info" do
      @uploadcare.instance_variable_set("@store_info", true)
      uploadcare_file = @uploader.upload(image)
      uploaded_file = @uploader.upload(uploadcare_file)
      refute_empty uploaded_file.metadata["uploadcare"]
      refute_empty uploaded_file.metadata["uploadcare"]["image_info"]
    end
  end

  describe "#url" do
    it "generates URLs with and without operations" do
      id = "0d2f95b1-2fcb-4a54-aa8f-b467bb4d26e5"

      assert_match %r{#{id}/$}, @uploadcare.url(id)

      assert_match %r{#{id}/-/quality/normal/$}, @uploadcare.url(id, quality: :normal)
      assert_match %r{#{id}/-/crop/200x300/center/$}, @uploadcare.url(id, crop: ['200x300', :center])
      assert_match %r{#{id}/-/resize/200x/-/progressive/yes/$}, @uploadcare.url(id, resize: '200x', progressive: :yes)
    end
  end

  describe "#presign" do
    it "generates a data for direct upload" do
      presign = @uploadcare.presign
      url, params = presign.url, presign.fields
      params[:file] = Faraday::UploadIO.new(image, "image/jpeg")
      params[:UPLOADCARE_STORE] = 1
      faraday = Faraday.new do |b|
        b.request :multipart
        b.request :url_encoded
        b.adapter :net_http
        b.response :parse_json
      end
      result = faraday.post(url, params).body
      assert @uploadcare.exists?(result.fetch("file"))
    end
  end
end
