require "test_helper"
require "shrine/storage/linter"
require "securerandom"
require "http"
require "json"

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
    linter = Shrine::Storage::Linter.new(uploadcare, nonexisting: SecureRandom.uuid)
    linter.call(->{image})
  end

  describe "#upload" do
    it "uploads IOs" do
      file = @uploadcare.upload(FakeIO.new(image.read), "foo")

      assert @uploadcare.exists?(file.uuid)
    end

    it "uploads remote files" do
      uploaded_file = @uploader.upload(image)
      file = @uploadcare.upload(uploaded_file, "foo")

      assert @uploadcare.exists?(file.uuid)
    end

    it "updates metadata" do
      uploaded_file = @uploader.upload(image)

      assert_equal "image/jpeg", uploaded_file.metadata["mime_type"]
      assert_equal 100,          uploaded_file.metadata["width"]
      assert_equal 67,           uploaded_file.metadata["height"]
      assert_equal image.size,   uploaded_file.metadata["size"]
      assert_equal [72, 72],     uploaded_file.metadata["dpi"]
    end
  end

  describe "#open" do
    it "accepts additional options" do
      file = @uploadcare.upload(image, "foo")
      io   = @uploadcare.open(file.uuid, rewindable: false)

      refute io.rewindable?
    end

    it "raises Shrine::FileNotFound on missing file" do
      assert_raises Shrine::FileNotFound do
        @uploadcare.open(SecureRandom.uuid)
      end
    end
  end

  describe "#url" do
    it "generates URLs with and without operations" do
      id = SecureRandom.uuid

      assert_match %r{#{id}/$}, @uploadcare.url(id)

      assert_match %r{#{id}/-/quality/normal/$},                @uploadcare.url(id, quality: :normal)
      assert_match %r{#{id}/-/crop/200x300/center/$},           @uploadcare.url(id, crop: ['200x300', :center])
      assert_match %r{#{id}/-/resize/200x/-/progressive/yes/$}, @uploadcare.url(id, resize: '200x', progressive: :yes)
    end
  end

  describe "#presign" do
    it "generates a data for direct upload" do
      presign = @uploadcare.presign

      response = HTTP.post presign[:url], form: presign[:fields].merge(
        file: HTTP::FormData::File.new(image, content_type: "image/jpeg"),
        UPLOADCARE_STORE: 1,
      )

      result = JSON.parse(response.body.to_s)

      assert @uploadcare.exists?(result.fetch("file"))
    end
  end
end
