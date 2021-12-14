# Ruby Sigstore

> :warning: Still under developement, not ready for production use yet!

> :information_source: This is a temporary fork of [sigstore/ruby-sigstore](https://github.com/sigstore/ruby-sigstore). This version abandons the [existing gem signing flow](https://ruby-doc.org/stdlib-3.0.3/libdoc/rubygems/rdoc/Gem/Security.html) in favor of a keyless gem signature that we store in the [Rekor](https://docs.sigstore.dev/rekor/overview) transparency log.

This rubygems plugin enables both developers to sign gem files and users to verify the origin
of a gem. It wraps around the main gem command to allow a level of seamless integration with
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

`gem signatures --sign foo.gem`

### Identity Tokens

In automated environments, gem also supports directly using OIDC Identity Tokens from specific issuers.
These can be supplied on the command line with the `--identity-token` flag.

```shell
$ gem signatures --sign --identity-token=$(gcloud auth print-identity-token)
```

### Verify an existing gem file

`gem signatures --verify foo.gem`

### Build and sign a gem

`gem build foo.gemspec --sign`

### Install and verify a gem

`gem install foo --verify-signatures`

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To build this gem, run `gem build ruby-sigstore`. To install it, run `gem install -l GEM`, e.g. `gem install -l ruby-sigstore-0.1.0.gem`.

To test or debug the plugin after making changes, try this:
```shell
gem uninstall ruby-sigstore && gem build ruby-sigstore && gem install -l ruby-sigstore-0.1.0.gem
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sigstore/ruby-sigstore.

## Security

Should you discover any security issues, please refer to sigstores [security
process](https://github.com/sigstore/community/blob/main/SECURITY.md)
