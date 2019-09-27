# Shrine::Storage::Uploadcare

Provides [Uploadcare] storage for [Shrine].

Uploadcare offers file storage with a CDN and on-demand image processing, along
with an advanced HTML widget for direct uploads.

## Installation

```ruby
gem "shrine-uploadcare"
```

## Usage

```rb
require "shrine"
require "shrine/storage/uploadcare"

uploadcare_options = {
  public_key:  "...",
  private_key: "...",
}

Shrine.storages = {
  cache: Shrine::Storage::Uploadcare.new(**uploadcare_options),
  store: Shrine::Storage::Uploadcare.new(**uploadcare_options),
}
```

### Direct uploads

The `Shrine::Storage::Uploadcare` class implements the `#presign` method, so it
should work with Shrine's [presign_endpoint] plugin and Uppy's [AwsS3] plugin.

If that doesn't work, you can always use Shrine's [upload_endpoint] plugin with
Uppy's [XHRUpload] plugin.

### URL operations

You can generate Uploadcare's [URL operations] by passing options to `#url`:

```rb
photo.image_url(resize: "200x")
photo.image_url(crop: ["200x300", :center])
```

### Metadata

Uploadcare metadata is automatically stored on upload:

```rb
user = User.create(avatar: image_file)
user.avatar.metadata
# {
#   "height" => 45,
#   "width" => 91,
#   "geo_location" => null,
#   "datetime_original" => null,
#   "format" => "PNG",
#   ...
# }
```

### Clearing storage

You can delete all files from the Uploadcare storage in the same way as you do
with other storages:

```rb
uploadcare = Shrine::Storage::Uploadcare.new(**options)
# ...
uploadcare.clear!
```

## Contributing

Firstly you need to create an `.env` file with Uploadcare credentials:

```sh
# .env
UPLOADCARE_PUBLIC_KEY="..."
UPLOADCARE_SECRET_KEY="..."
```

Afterwards you can run the tests:

```sh
$ rake test
```
## License

[MIT](http://opensource.org/licenses/MIT)

[Uploadcare]: https://uploadcare.com/
[Shrine]: https://github.com/shrinerb/shrine
[URL operations]: https://uploadcare.com/documentation/cdn/
[presign_endpoint]: https://github.com/shrinerb/shrine/blob/master/doc/plugins/presign_endpoint.md#readme
[upload_endpoint]: https://github.com/shrinerb/shrine/blob/master/doc/plugins/upload_endpoint.md#readme
[AwsS3]: https://uppy.io/docs/aws-s3/
[XHRUpload]: https://uppy.io/docs/xhr-upload/
