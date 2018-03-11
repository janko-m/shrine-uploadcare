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

Uploadcare supports uploading files directly to the service, freeing your
application from accepting file uploads. The easiest way to do that is by using
Uploadcare's [HTML widget], you can see how it can be used in the
shrine-uploadcare [demo app].

[Secure file uploads] are also supported, you can generate signatures with
`#presign` on the storage, or using the [direct_upload plugin] with `presign:
true`.

### URL operations

You can generate Uploadcare's [URL operations] by passing options to `#url`:

```rb
photo.image_url(resize: "200x")
photo.image_url(crop: ["200x300", :center])
```

### Upload options

You can add upload options using the upload_options plugin or using
`:upload_options` on the storage:

```rb
Shrine::Storage::Uploadcare.new(upload_options: {...}, **uploadcare_options)
```

### Storing information

You can have all Uploadcare file information saved in the uploaded file's
metadata:

```rb
Shrine::Storage::Uploadcare.new(store_info: true, **uploadcare_options)
```
```rb
user = User.create(avatar: image_file)
user.avatar.metadata["uploadcare"] #=>
# {
#   "type" => "file",
#   "result" => {
#     "original_file_url" => "http://www.ucarecdn.com/d1d2dc43-4904-4783-bb4d-fbcf64264e63/image.png",
#     "image_info" => {
#       "height" => 45,
#       "width" => 91,
#       "geo_location" => null,
#       "datetime_original" => null,
#       "format" => "PNG"
#     },
#     "mime_type" => "image/png",
#     "is_ready" => true,
#     "url" => "https://api.uploadcare.com/files/d1d2dc43-4904-4783-bb4d-fbcf64264e63/",
#     "uuid" => "d1d2dc43-4904-4783-bb4d-fbcf64264e63",
#     "original_filename" => "image.png",
#     "datetime_uploaded" => "2014-09-09T16:48:57.284Z",
#     "size" => 12952,
#     "is_image" => null,
#     "datetime_stored" => "2014-09-09T16:48:57.291Z",
#     "datetime_removed" => null,
#     "source" => "/03ccf9ab-f266-43fb-973d-a6529c55c2ae/"
#   }
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
[HTML widget]: https://uploadcare.com/documentation/widget/
[demo app]: /demo
[Secure file uploads]: https://uploadcare.com/documentation/upload/#secure-uploads
[direct_upload plugin]: http://shrinerb.com/rdoc/classes/Shrine/Plugins/DirectUpload.html
[URL operations]: https://uploadcare.com/documentation/cdn/
