use Cro::BodyParser;
use Cro::HTTP::Message;
use JSON::Class;

=begin pod

=head1 NAME

Cro::HTTP::BodyParser::JSONClass - Parse and deserialise application/json HTTP body to a specified JSON::Class

=head1 SYNOPSIS

=begin code

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

=end code

=head1 DESCRIPTION

This provides a specialised L<Cro::BodyParser|https://cro.services/docs/reference/cro-http-router#Adding_custom_request_body_parsers> that will parse a JSON ('application/json') request body to the specified
L<JSON::Class|https://github.com/jonathanstowe/JSON-Class> type.  This is useful if you have C<JSON::Class> classes that you want to create from HTTP data, and will lead to less code and perhaps better
abstraction.

The BodyParser is implemented as a Parameterised Role with the target class as the parameter.  Because this will basically over-ride the Cro's builtin JSON parsing it probably doesn't want to be installed at the
top level in the Cro::HTTP instance, but rather in a specific C<route> block with the C<body-parser> helper, also because it is specialised to a single class it may want to be isolated to its own C<route>
block so other routes keep the default behaviour or have parsers parameterised to different classes, so you may want to do something like:

=begin code

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
=end code

The test as to whether this body parser should be used (defined in the method C<is-applicable> ) is generalised to the C<application/json> content type, (hence the caveat above regarding reducing the scope.)
If you want to make a more specific test (or even if the Content-Type supplied *isn't* C<application/json>,) then you can compose this to a new class the over-rides the C<is-applicable>:


=begin code
class SomeBodyParser does Cro::HTTP::BodyParser::JSONClass[HelloClass] {
   method is-applicable(Cro::HTTP::Message $message --> Bool) {
      $message.header('X-API-Message-Type').defined && $message.header('X-API-Message-Type') eq 'Hello';
   }
}
=end code

And then use C<SomeBodyParser> in place of C<Cro::HTTP::BodyParser::JSONClass>.

=end pod


role Cro::HTTP::BodyParser::JSONClass[JSON::Class ::JC] does Cro::BodyParser {
    method is-applicable(Cro::HTTP::Message $message --> Bool) {
        with $message.content-type {
            .type eq 'application' && .subtype eq 'json' || .suffix eq 'json'
        }
        else {
            False
        }
    }

    method parse(Cro::HTTP::Message $message --> Promise) {
        Promise(supply {
            my $payload = Blob.new;
            whenever $message.body-byte-stream -> $blob {
                $payload ~= $blob;
                LAST emit JC.from-json($payload.decode('utf-8'));
            }
        })
    }
}

