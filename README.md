# Cro::HTTP::BodyParser::JSONClass

Parse and deserialise application/json HTTP body to a specified JSON::Class

## Synopsis

```raku
use Cro::HTTP::Router;
use Cro::HTTP::Server;
use JSON::Class;
use Cro::HTTP::BodyParser::JSONClass;


class HelloClass does JSON::Class {
    has Str $.firstname;
    has Str $.lastname;

    method hello(--> Str ) {
        "Hello, $.firstname() $.lastname()";
    }

}
my $app = route {
    body-parser Cro::HTTP::BodyParser::JSONClass[HelloClass];
    post -> 'hello' {
        request-body -> $hello {
            content 'text/plain', $hello.hello;
        }
    }
};

my Cro::Service $service = Cro::HTTP::Server.new(:host<127.0.0.1>, :port<7798>, application => $app);

$service.start;

react  { whenever signal(SIGINT) { $service.stop; exit; } }
```

## Description

This provides a specialised [Cro::BodyParser](https://cro.services/docs/reference/cro-http-router#Adding_custom_request_body_parsers) that will parse a JSON ('application/json') request body to the specified
[JSON::Class](https://github.com/jonathanstowe/JSON-Class) type.  This is useful if you have `JSON::Class` classes that you want to create from HTTP data, and will lead to less code and perhaps better
abstraction.

The BodyParser is implemented as a Parameterised Role with the target class as the parameter.  Because this will basically over-ride the Cro's builtin JSON parsing it probably doesn't want to be installed at the
top level in the Cro::HTTP instance, but rather in a specific `route` block with the `body-parser` helper, also because it is specialised to a single class it may want to be isolated to its own `route`
block so other routes keep the default behaviour or have parsers parameterised to different classes, so you may want to do something like:

```raku
my $app = route {
    delegate 'hello' => route {
        body-parser Cro::HTTP::BodyParser::JSONClass[HelloClass];
        post ->  {
            request-body -> $hello {
                content 'text/plain', $hello.hello;
            }
        }
    }
};
```

The test as to whether this body parser should be used (defined in the method `is-applicable` ) is generalised to the `application/json` content type, (hence the caveat above regarding reducing the scope.)
If you want to make a more specific test (or even if the Content-Type supplied *isn't* `application/json`,) then you can compose this to a new class the over-rides the `is-applicable`:

```raku
class SomeBodyParser does Cro::HTTP::BodyParser::JSONClass[HelloClass] {
   method is-applicable(Cro::HTTP::Message $message --> Bool) {
      $message.header('X-API-Message-Type').defined && $message.header('X-API-Message-Type') eq 'Hello';
   }
}
```

And then use `SomeBodyParser` in place of `Cro::HTTP::BodyParser::JSONClass`.

## Installation

Assuming you have a working installation of rakudo you should be able to install this with *zef* :

   zef install Cro::HTTP::BodyParser::JSONClass

Or from a local clone of the repository:

   zef install .

## Support

Please direct any patches, suggestions or feedback to [Github](https://github.com/jonathanstowe/Cro-HTTP-BodyParser-JSONClass/issues).

# Licence and copyright

This is free software, please see the [LICENCE](LICENCE) file in the distribution.

© Jonathan Stowe 2021
