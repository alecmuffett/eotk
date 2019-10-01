#!/bin/sh
# eotk (c) 2017 Alec Muffett

# gentlemen, behold! unit tests!

export EXP_TAG="TAG $$ `date`"

TEMPLATE=/tmp/exp-template$$
EXPECT=/tmp/exp-expect$$
RESULT=/tmp/exp-result$$
LOG=/tmp/exp-log$$

Template() {
    (
        cat
        echo "%EXP_TAG%" # add to end so line numbers not off
    ) > $TEMPLATE
}

Expect() {
    (
        cat
        echo "$EXP_TAG"
    ) > $EXPECT
}

Test() {
    ./expand-template.pl --debug $TEMPLATE >$RESULT 2>$LOG

    if ! cmp $EXPECT $RESULT ; then
        echo :::: broken test: "$@" ::::
        cat $LOG
        echo ""
        echo :::: problem ::::
        ls -l $EXPECT $RESULT
        diff -c $EXPECT $RESULT
        exit 1
    fi
}

##################################################################

# see if this works

Template <<EOF
hello world
EOF

Expect <<EOF
hello world
EOF

Test hello world < /dev/null

##################################################################

# environment expansion

Template <<EOF
foo %FOO% foo
bar %BAR% bar
baz %BAZ% baz
percent %% percent
percent%% percent
percent %%percent
percent%%percent
EOF

Expect <<EOF
foo 1 foo
bar 2 bar
baz wibble baz
percent % percent
percent% percent
percent %percent
percent%percent
EOF

export FOO=1
export BAR=2
export BAZ=wibble
Test env expand < /dev/null

##################################################################

# basic template

Template <<EOF
foo %FOO% foo
%%BEGIN
bar1 %BAR1% bar1
bar3 %BAR3% bar3
bar2 %BAR2% bar2
%%END
baz %BAZ% baz
EOF

Expect <<EOF
foo 1 foo
bar1 101 bar1
bar3 103 bar3
bar2 102 bar2
bar1 201 bar1
bar3 203 bar3
bar2 202 bar2
bar1 301 bar1
bar3 303 bar3
bar2 302 bar2
baz 3 baz
EOF

export FOO=1 BAZ=3
unset BAR1 BAR2 BAR3
Test basic template <<EOF
BAR1  BAR2  BAR3
101   102   103
201   202   203
301   302   303
EOF

##################################################################

# two templates

Template <<EOF
----
%%BEGIN
: f1 %F1% f3 %F3% f2 %F2% :
%%END
----
%%BEGIN
: f2 %F2% f3 %F3% f1 %F1% :
%%END
----
EOF

Expect <<EOF
----
: f1 101 f3 103 f2 102 :
: f1 201 f3 203 f2 202 :
----
: f2 102 f3 103 f1 101 :
: f2 202 f3 203 f1 201 :
----
EOF

unset F1 F2 F3
Test two templates <<EOF
F1   F2   F3
101  102  103
201  202  203
EOF

##################################################################

# instatemplate

Template <<EOF
%%BEGIN
foo %FOO%
%%END
EOF

Expect <<EOF
foo 1
foo 2
foo 3
EOF

unset FOO
Test instatemplate <<EOF
FOO
1
2
3
EOF

##################################################################

# empty template

Template <<EOF
%%BEGIN
%%END
EOF

Expect <<EOF
EOF

unset FOO
Test empty template <<EOF
FOO
1
2
3
EOF

##################################################################

# empty template head

Template <<EOF
head
%%BEGIN
%%END
EOF

Expect <<EOF
head
EOF

unset FOO
Test empty template head <<EOF
FOO
1
2
3
EOF

##################################################################

# empty template tail

Template <<EOF
%%BEGIN
%%END
tail
EOF

Expect <<EOF
tail
EOF

unset FOO
Test empty template tail <<EOF
FOO
1
2
3
EOF

##################################################################

# Conditional

Template <<EOF
----
%%IF %FOO%
%BAR%
%%BEGIN
true %BAZ%
%%END
%%ELSE
%BAR%
%%BEGIN
false %BAZ%
%%END
%%ENDIF
----
EOF

####

Expect <<EOF
----
bar
false baz
----
EOF

export FOO=0 BAR=bar
Test conditional false <<EOF
BAZ
baz
EOF

####

Expect <<EOF
----
bar
true baz
----
EOF

export FOO=1 BAR=bar
Test conditional true <<EOF
BAZ
baz
EOF

##################################################################

# conditional inputs

Template <<EOF
%%BEGIN
%%IF %BONG%
bong is true
%%ELSE
bong is false
%%ENDIF
%%END
EOF

Expect <<EOF
bong is true
bong is true
bong is false
bong is true
bong is true
bong is false
EOF

Test <<EOF
BONG
2
1
0
2
1
0
EOF

##################################################################

# nested

Template <<EOF
A
%%IF %OUTER%
B
%%IF %INNER1%
C
%%ENDIF
D
%%IF %INNER2%
E
%%ENDIF
F
%%ENDIF
G
EOF

##

Expect <<EOF
A
G
EOF

export OUTER=0 INNER1=1 INNER2=1
Test nesting1 < /dev/null

##

Expect <<EOF
A
B
C
D
E
F
G
EOF

export OUTER=1 INNER1=1 INNER2=1
Test nesting2 < /dev/null

##

Expect <<EOF
A
B
C
D
F
G
EOF

export OUTER=1 INNER1=1 INNER2=0
Test nesting3 < /dev/null

##

Expect <<EOF
A
B
D
E
F
G
EOF

export OUTER=1 INNER1=0 INNER2=1
Test nesting4 < /dev/null

##################################################################

Template <<EOF
A
%%IF %OUTER%
B
%%IF %INNER1%
C
%%ELSE -- inner1
D
%%ENDIF
E
%%ELSE -- outer
F
%%IF %INNER2%
G
%%ELSE -- inner2
H
%%ENDIF
I
%%ENDIF
J
EOF

Expect <<EOF
A
B
D
E
J
EOF

export OUTER=1 INNER1=0 INNER2=1

Test nesting else 1 < /dev/null

##

Expect <<EOF
A
F
G
I
J
EOF

export OUTER=0 INNER1=1 INNER2=1

Test nesting else 2 < /dev/null

##################################################################

Template <<EOF
%%BEGIN
foo %value%
%%BEGIN
bar %value%
%%END
baz %value%
%%END
EOF

Expect <<EOF
foo 1
bar 1
bar 2
bar 3
baz 1
foo 2
bar 1
bar 2
bar 3
baz 2
foo 3
bar 1
bar 2
bar 3
baz 3
EOF

Test nested scopes <<EOF
value
1
2
3
EOF

##################################################################

Template <<EOF
A
%%RANGE I 1 3
B %I%
%%ENDRANGE
C
EOF

Expect <<EOF
A
B 1
B 2
B 3
C
EOF

Test range 1 < /dev/null

##################################################################

Template <<EOF
A
%%RANGE I 1 3
B %I%
%%RANGE J 4 5
C %I% %J%
%%ENDRANGE
D
%%ENDRANGE
E
EOF

Expect <<EOF
A
B 1
C 1 4
C 1 5
D
B 2
C 2 4
C 2 5
D
B 3
C 3 4
C 3 5
D
E
EOF

Test range 2 < /dev/null

##################################################################

Template <<EOF
A %I% %J%
%%RANGE K %I% %J%
B %I% %J% %K%
%%ENDRANGE
C %I% %J%
EOF

Expect <<EOF
A 3 5
B 3 5 3
B 3 5 4
B 3 5 5
C 3 5
EOF

export I=3 J=5
Test range 1 < /dev/null

##################################################################

Template <<EOF
%%IF 0
%%ELSE
%%ENDIF
EOF

Expect <<EOF
EOF

Test empty1 </dev/null

##################################################################

Template <<EOF
%%IF foo eq foo
true1
%%ENDIF
%%IF foo ne bar
true2
%%ENDIF
%%IF foo ne foo
false1
%%ENDIF
%%IF foo eq bar
false2
%%ENDIF

%%IF 1 == 1
true3
%%ENDIF
%%IF 1 != 2
true4
%%ENDIF

%%IF 1 >= 1
true5
%%ENDIF
%%IF 2 >= 1
true6
%%ENDIF

%%IF foobarbaz contains barb
true7
%%ENDIF
%%IF foobarbaz !contains eek
true8
%%ENDIF
%%IF foobarbaz !contains barb
false3
%%ENDIF
%%IF foobarbaz contains eek
false4
%%ENDIF
EOF

Expect <<EOF
true1
true2

true3
true4

true5
true6

true7
true8
EOF

Test more conditionals </dev/null

##################################################################

# see if this works

Template <<EOF
foo
%%CSV %var%
%0% a=%1%
b=%2% c=%3%
%%ENDCSV
bar
EOF

Expect <<EOF
foo
a,b,c a=a
b=b c=c
A,B,C a=A
b=B c=C
bar
EOF

export var="a,b,c A,B,C"
Test csv1 < /dev/null

##################################################################

# see if `splice` works

Template <<EOF
foo
%%SPLICE /etc/passwd /etc/group
bar
EOF

(
    echo foo
    cat /etc/passwd /etc/group
    echo bar
) | Expect

Test file splice < /dev/null

##################################################################

# check not-evaluation

Expect <<EOF
foo
bar
baz
EOF

Template <<EOF
foo
%%IF ! 0
bar
%%ENDIF
baz
EOF

Test exclamation-not < /dev/null

Template <<EOF
foo
%%IF not 0
bar
%%ENDIF
baz
EOF

Test word-not < /dev/null

Template <<EOF
foo
%%IF ! 1
eek
%%ELSE
bar
%%ENDIF
baz
EOF

Test invert-exclamation-not < /dev/null

Template <<EOF
foo
%%IF not 1
eek
%%ELSE
bar
%%ENDIF
baz
EOF

Test invert-word-not < /dev/null

##################################################################

# see if `include` works

included="/tmp/tmplincl$$"
cat >$included <<EOF
%%INCLUDE /etc/passwd /etc/group
EOF

Template <<EOF
foo
%%INCLUDE $included
bar
EOF

(
    echo foo
    cat /etc/passwd /etc/group
    echo bar
) | Expect

Test file include < /dev/null
