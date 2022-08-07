#!/usr/bin/env raku

use Test;
use Cro::HTTP::Test;
use Cro::HTTP::Router;
use JSON::Class;
use Cro::HTTP::BodyParser::JSONClass;

class TestClass does JSON::Class {
    has $.a;
    has $.b;
}

class MyParser does Cro::HTTP::BodyParser::JSONClass[TestClass] {
}

my $content = '{"a": "first", "b": "second"}';

my $app = route {
    body-parser MyParser;

    get -> 'parser' {
        content 'application/json', $content;
    }

    post -> 'parser' {
        request-body -> $body {
            content 'text/plain', "test-parser: $body.^name(), a: $body.a(), b: $body.b()";
        }
    }
}

test-service $app, {
    test-given '/parser', {
        test get,
             status => 200, content-type => 'application/json',
             body => { :a<first>, :b<second> };

        test post(json => { :a<first>, :b<second> }),
             status => 200, content-type => 'text/plain',
             body-text => 'test-parser: TestClass, a: first, b: second';
    }
}

test-service $app, body-parsers => [MyParser], {
    test get('/parser'),
         status => 200, content-type => 'application/json',
         body => * eqv TestClass.new: :a<first>, :b<second>;
}

my Cro::HTTP::BodyParser::JSONClass $my-parser .= new;
test-service $app, body-parsers => [$my-parser], {
    test-given '/parser', {
        test get,
             status => 200, content-type => 'application/json',
             body => * eqv JSON::Class.new;

        $my-parser.set-json-class: TestClass;
        test get,
             status => 200, content-type => 'application/json',
             body => * eqv TestClass.new: :a<first>, :b<second>;
    }
}

done-testing;

# vim: ft=raku
