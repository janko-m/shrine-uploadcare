# Shrine & Uploadcare Demo

This is a Roda & Sequel demo app which integrates Uploadcare file uploads with
Shrine.

## Requirements

You need to have the following:

* SQLite
* Uploadcare account

## Setup

* Add .env with Uploadcare credentials:

  ```sh
  # .env
  UPLOADCARE_PUBLIC_KEY="..."
  UPLOADCARE_SECRET_KEY="..."
  ```

* Run `bundle install`

* Run `rake db:migrate`

* Run `bundle exec rackup`
