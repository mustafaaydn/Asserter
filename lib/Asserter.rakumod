use QAST:from<NQP>;

my constant UNIQUE_OBJ = class {}.new;

our class X::Assertion is Exception {
    has Str $.stmt;     #= The literal statement that is being asserted
    has Mu  $.value;    #= It's runtime value when evaluated
    has $.description;  #= Optional description to tell if the assertion fails
    method !set($s, Mu \v, $d) { $!stmt = $s; $!value := v; $!description = $d; self }
    method new($stmt, Mu \value, $description) { self.bless!set($stmt, value, $description) }
    method message {
        $!description === UNIQUE_OBJ
            ?? "Assertion failed: `$!stmt.trim()` is not true; it evaluates to `$!value.raku()`"
            !! "Assertion failed: $!description"
    }
}

my role Asserter::Grammar {
    rule statement_control:sym<assert> {
        <sym> <statement>
    }
}

my role Asserter::Actions {
    method statement_control:sym<assert>(Mu $match) {
        my $stmt  := $match.hash<statement>;
        my $exprs := $stmt.hash<EXPR>;
        my ($stmt-to-bind, $description);
        # Comma operator involved: a custom description is passed
        # i.e., `assert EXPR, DESCRIPTION`
        if (my $inf = $exprs.hash<infix>).defined && $inf.Str eq "," {
            # ...unless there are exactly 2 things comma'ed; otherwise error
            my $exprs-list = $exprs.list;
            unless $exprs-list == 2 {
                my ($line, *@)   := HLL::Compiler.linefileof($match.target, $match.pos, :cache(1), :directives(1));
                my ($pre, $post) := $*W.locprepost($match);
                X::Comp::AdHoc.new(payload  => "That's too assertive; expected 1 or 2 things, got $exprs-list.elems()",
                                   pos      => $match.pos,
                                   filename => $*W.current_file,
                                   line     => $line,
                                   pre      => $pre,
                                   post     => $post).throw;
            }
            given $exprs-list {
                $stmt-to-bind := .[0].ast;
                $description  := .[1].ast;
            }
        }
        else {
            # No comma, i.e., `assert EXPR`
            $stmt-to-bind := $stmt.ast;
            $description  := QAST::WVal.new(:value(UNIQUE_OBJ));
        }
        #`[
        Compile to
            my $_val := EXPR.EVAL;
            unless $_val {
                die X::Assertion.new(EXPR, $_val, DESCRIPTION.EVAL);
            }
        ]
        $match.make(
            QAST::Stmts.new(
                QAST::Op.new(
                    :op("bind"),
                    QAST::Var.new(:name("\$_val"), :scope("local"), :decl("var")),
                    $stmt-to-bind
                ),
                QAST::Op.new(
                    :op("unless"),
                    QAST::Var.new(:name("\$_val"), :scope("local")),
                    QAST::Op.new(
                        :op("call"),
                        :name("\&die"),
                        QAST::Op.new(
                            :op("callmethod"),
                            :name("new"),
                            QAST::WVal.new(:value(X::Assertion)),
                            QAST::SVal.new(:value($stmt)),
                            QAST::Var.new(:name("\$_val"), :scope("local")),
                            $description,
                        )
                    )
                )
            )
        )
    }
}

$*LANG.refine_slang("MAIN", Asserter::Grammar, Asserter::Actions);
