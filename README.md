erl_unused_includes.sh
======================

Copyright (C) 2014 Klarna AB.

This is a shell script that can be used as a wrapper for the Erlang erlc
compiler, that eliminates unnecessary include declarations from the source
files by compiling the file multiple times and only keeping those include
declarations that are actually necessary for the compilation to work.

The script takes the same parameters as erlc, except for an extra initial
parameter which is the path to the real erlc. E.g.: `erl_unused_includes.sh
erlc -o ebin foo.erl`. Should work with any erlc command line.

If you are using Make and you have a configuration variable that specifies
which erlc to use, e.g.:

    ERLC=/path/to/erlc

then you should be able to simply plug in this script instead, in order to
run it on all your .erl files:

    ERLC=/path/to/erl_unused_includes.sh /path/to/erlc

Just run `make clean && make` and your source files will get cleaned up.

Available under the MIT License (see LICENSE).
