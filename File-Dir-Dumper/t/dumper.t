#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 28;

use POSIX qw(mktime strftime);
use File::Path;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "t", "lib");

use File::Find::Object::TreeCreate;

use File::Dir::Dumper::Scanner;


{
    my $tree =
    {
        'name' => "traverse-1/",
        'subs' =>
        [
            {
                'name' => "a.doc",
                'contents' => "This file was spotted in the wild.",
            },
            {
                'name' => "b/",
            },
            {
                'name' => "foo/",
                'subs' =>
                [
                    {
                        'name' => "yet/",
                    },
                ],
            },
        ],
    };

    my $t = File::Find::Object::TreeCreate->new();
    $t->create_tree("./t/sample-data/", $tree);

    my $test_dir = "t/sample-data/traverse-1";

    my $a_doc_time = mktime(1, 2, 3, 4, 5, 106);
    utime($a_doc_time, $a_doc_time, $t->get_path("$test_dir/a.doc"));

    my $scanner = File::Dir::Dumper::Scanner->new(
        {
            dir => $t->get_path($test_dir),
        }
    );

    my $token;

    $token = $scanner->fetch();

    # TEST
    is ($token->{type}, "header", "Token is of type header");

    # TEST
    is ($token->{dir_to_dump}, $t->get_path($test_dir), 
        "dir_to_dump is OK."
    );

    $token = $scanner->fetch();

    # TEST
    is ($token->{type}, "dir", "type is dir");

    # TEST
    is ($token->{depth}, 0, "depth is 0");

    $token = $scanner->fetch();

    # TEST
    is ($token->{type}, "file", "Type is file");

    # TEST
    is ($token->{filename}, "a.doc", "Filename is OK.");

    # TEST
    is ($token->{mtime},
        strftime("%Y-%m-%dT%H:%M:%S", localtime($a_doc_time)),
        "mtime is OK.",
    );

    # TEST
    is ($token->{size},
        length("This file was spotted in the wild."),
        "size is OK.",
    );

    # TEST
    is ($token->{depth}, 1, "Token depth is 1");

    $token = $scanner->fetch();

    # TEST
    is ($token->{type}, "dir", "Token is dir");

    # TEST
    is ($token->{depth}, 1, "Token depth is 1");

    # TEST
    is ($token->{filename}, "b", "dir name is 'b'");

    $token = $scanner->fetch();

    # TEST
    is ($token->{type}, "updir", "Token is updir");

    # TEST
    is ($token->{depth}, 1, "updir token (from 'b') has depth 1");

    $token = $scanner->fetch();

    # TEST
    is ($token->{type}, "dir", "Token is dir");

    # TEST
    is ($token->{filename}, "foo", "dir name is 'foo'");

    # TEST
    is ($token->{depth}, 1, "Token depth is 1");
    
    $token = $scanner->fetch();

    # TEST
    is ($token->{type}, "dir", "Token is dir");

    # TEST
    is ($token->{filename}, "yet", "dir name is 'yet'");

    # TEST
    is ($token->{depth}, 2, "Token depth is 2");

    $token = $scanner->fetch();

    # TEST
    is ($token->{type}, "updir", "Token is updir");

    # TEST
    is ($token->{depth}, 2, "Token depth is 2");
    
    $token = $scanner->fetch();

    # TEST
    is ($token->{type}, "updir", "Token is updir");

    # TEST
    is ($token->{depth}, 1, "Token depth is 1");

    $token = $scanner->fetch();

    # TEST
    is ($token->{type}, "updir", "Token is updir");

    # TEST
    is ($token->{depth}, 0, "Token depth is 0");
    
    $token = $scanner->fetch();

    # TEST
    is ($token->{type}, "footer", "Token is footer");

    $token = $scanner->fetch();

    # TEST
    ok (!defined($token), "Token is undefined - reached end.");

    rmtree($t->get_path($test_dir))
}
