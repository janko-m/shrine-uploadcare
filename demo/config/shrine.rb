require "./config/credentials"

require "shrine"
require "shrine/storage/uploadcare"

require "./jobs/promote_job"
require "./jobs/delete_job"

uploadcare_options = {
  public_key:  ENV.fetch("UPLOADCARE_PUBLIC_KEY"),
  private_key: ENV.fetch("UPLOADCARE_SECRET_KEY"),
}

Shrine.storages = {
  cache: Shrine::Storage::Uploadcare.new(**uploadcare_options),
  store: Shrine::Storage::Uploadcare.new(**uploadcare_options),
}

Shrine.plugin :sequel
Shrine.plugin :backgrounding
Shrine.plugin :logging

Shrine::Attacher.promote { |data| PromoteJob.perform_async(data) }
Shrine::Attacher.delete { |data| DeleteJob.perform_async(data) }
