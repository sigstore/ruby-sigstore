# Ruby Sigstore

> :warning: Still under developement, not ready for production use yet!

This rubygems plugin enables both developers to sign gem files and users to verify the origin
of a gem. It wraps around the main gem command to allow a level of seamless intergration with
gem build and install operations.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ruby-sigstore'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install ruby-sigstore

## Usage

### Sign an existing gem file

`gem sign foo.gem`

### Verify an existing gem file

`gem verify foo.gem`

### Build and sign a gem

`gem build foo.gemspec --sign`

### Install and verify a gem

`gem install foo --verify`

### Install a gem without verification

`gem install foo --verify`

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sigstore/ruby-sigstore.

## Security

Should you discover any security issues, please refer to sigstores [security
process](https://github.com/sigstore/community/blob/main/SECURITY.md)
