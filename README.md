# MyJohnDeere API Library

The MyJohnDeere Ruby library provides convenient access to the MyJohnDeere API from applications written in the Ruby language. It includes a pre-defined set of classes for API resources that are available currently from the API. You will need to get access by going to the (JohnDeere Developer page)[https://developer.deere.com/#!welcome]. The interface utilizes OAUTH 1.0.

## Listable Objects

MyJohnDeere returns either pages of objects that will automatically be iterated through 10 at a time *or* you'll receive the entirety of the resource if you specify an etag token.

**If using the paginated approach**: Use `more_pages?` on the listable object to see if there are more pages to be acquired by using `next_page!`. This will modify the `.start` and `.count` values on the list object. These automatically increase with each `next_page`.

**If using the etag approach**: The entirety of the data set will be returned to you and on the list object you'll want to call `list.etag` and store this locally. You can then use this on future requests to see if anything has changed from the original request.

If you for some reason specify both, the etag will be the assumed behavior.

The raw data can be acquired by using `.data` on a listable object.

## Usage

### Configuration

The library needs to be configured with your MyJohnDeere account's shared secret & app id. These will be available on the developer page at JohnDeere.

``` ruby
require "myjohndeere"

MyJohnDeere.configure do |config|
  config.environment = :sandbox # :production is the other option
  config.shared_secret = "...."
  config.app_id = "johndeere-...."
  #config.log_level = :info
end

```

### Get an Access Token

**NOTE:** These expire after one year

#### Access Token from Request Token
If you are beginning from scratch then you'll be starting with a request token and the request token secret. To do this:


``` ruby

request_token = MyJohnDeere::AccessToken.get_request_token()
puts "Now visit the #{request_token.authorize_url}"
puts "Use the #{request_token.secret} and #{request_token.token} when creating the "
puts "access token along with the verifier code from the browser"

```

Then later:
``` ruby

access_token = MyJohnDeere::AccessToken.new(request_token_token: "....", 
    request_token_secret: "....",
    verifier_code: "....")
 # You'll now have the oauth access tokens
puts access_token.token
puts access_token.secret

```

#### Access Token from Existing OAuth Token

If you've already gone through the effort to get your OAuth access token, then you can do:

``` ruby
access_token = MyJohnDeere::AccessToken.new(
      oauth_access_token_token: "....",
      oauth_access_token_secret: "....",
    )
```
### Getting Objects

Assuming you've created a MyJohnDeere::AccessToken using something from above, then you can do:

``` ruby
organizations = MyJohnDeere::Organization.list(access_token)

organizations.each do |organization|
    puts organization.fields.data
end

organizations.has_more?

```

## Development

Run all tests:

    bundle exec rake

Run a single test suite:

    bundle exec ruby -Ilib/ test/myjohndeere_test.rb

Run a single test:

    bundle exec ruby -Ilib/ test/myjohndeere_test.rb -n /some_test/

## Disclaimer

This Gem is in no way associated with JohnDeere, and they are in no way associated with it's support, maintenance, or updates.