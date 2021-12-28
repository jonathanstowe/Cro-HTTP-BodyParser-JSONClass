# Cro::HTTP::BodyParser::JSONClass

Parse and deserialise application/json HTTP body to a specified JSON::Class

[![CI](https://github.com/jonathanstowe/Cro-HTTP-BodyParser-JSONClass/actions/workflows/main.yml/badge.svg)](https://github.com/jonathanstowe/Cro-HTTP-BodyParser-JSONClass/actions/workflows/main.yml)

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

# This intermediate class is only necessary in older rakudo, as of
# 2021.09 the parameterised role can be use directly
class SomeBodyParser does Cro::HTTP::BodyParser::JSONClass[HelloClass] { 
}

my $app = route {
    body-parser SomeBodyParser;
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

```raku
use Cro::HTTP::Client;
use JSON::Class;
use Cro::HTTP::BodyParser::JSONClass;

my $client1 = Cro::HTTP::Client.new: body-parsers => [Cro::HTTP::BodyParser::JSONClass[HelloClass]];
my $obj1 = await $client1.get-body: 'https://jsonclass.free.beeceptor.com/hello';
say $obj1.raku;
=output HelloClass.new(firstname => "fname", lastname => "lname")␤

# Setting the JSON class after creating an instance of Cro::HTTP::Client
my $body-parser = Cro::HTTP::BodyParser::JSONClass.new;
my $client2 = Cro::HTTP::Client.new: body-parsers => [$body-parser];
$body-parser.set-json-class: HelloClass;
my $obj2 = await $client2.get-body: 'https://jsonclass.free.beeceptor.com/hello';
say $obj2.raku;
=output HelloClass.new(firstname => "fname", lastname => "lname")␤
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
        body-parser SomeBodyParser;
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

The BodyParser has a `set-json-class` method which can be used to set the `JSON::Class` class to another class whenever needed.

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
