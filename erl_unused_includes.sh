#!/bin/bash
#
# Use as substitute for the erlc command. Takes the same parameters as erlc,
# except for an extra initial parameter which is the path to the real erlc.
# E.g.: 'erl_unused_includes.sh erlc -o ebin foo.erl'. Should work with any
# erlc command line.
#
# If you are using Make and you have a configuration variable that specifies
# which erlc to use, e.g.:
#   ERLC=/path/to/erlc
# then you should be able to simply plug in this script instead, in order to
# run it on all your .erl files:
#   ERLC=/path/to/erl_unused_includes.sh /path/to/erlc
# Just run 'make clean && make' and your source files will get cleaned up.
#
# Copyright (C) 2014 Klarna AB
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

# extract the command so we can insert options directly after it
erlc="$1"
shift
# preserve arguments as an array (bash-specific) for correct quoting
args=("$@")

# scan the arguments to find the .erl source file name
# also check for -M flags, so we don't disturb dependency generation
file=""
while [ $# -gt 0 ]
do
    case $1 in
	-M) break;;
	-MF) break;;
	-MD) break;;
	*.erl) file=$1; break;;
        *) ;;
    esac
    shift
done

if [ -n "$file" ]; then
    # find all include declarations in the file and iterate over them
    incls=($(grep -o '^\-include\(_lib\)\?([^)]*)' $file))
    for i in ${incls[@]}; do
        case $i in
            # don't remove these - can't always detect if needed or not
            *eunit/include/eunit.hrl*) continue;;
            *proper/include/proper.hrl*) continue;;
            *eqc/include/eqc.hrl*) continue;;
            # don't remove pmod.hrl - compilation works without it on <R16
            *pmod_transform/include/pmod.hrl*) continue;;
            # removing qlc.hrl might only cause a warning: treat as error
            *stdlib/include/qlc.hrl*) extra="-Werror ${extra}";;
            # don't remove ms_transform.hrl
            *stdlib/include/ms_transform.hrl*) continue;;
            *) ;;
        esac
        # comment out the include line
        sed -i "s;^$i;%%$i;" $file
        # compile both with and without TEST to exercise ifdef:ed code
        if "$erlc" $extra "${args[@]}" &>/dev/null && \
           "$erlc" $extra -DTEST=true "${args[@]}" &>/dev/null
        then
            # delete the line if compilation worked
            echo "** DELETING $i FROM $file"
            sed -i "\;^%%$i;d" $file
        else
            # restore the line otherwise
            sed -i "s;^%%$i;$i;" $file
        fi
    done
fi

# a final normal compilation pass is always done
"$erlc" "${args[@]}"
