## Asserter
Be assertive in the form `assert EXPR, MESSAGE?`

```raku
use Asserter;

# Without a custom message, expression itself and its value are reported
my $val = Empty;
assert $val;
#= Assertion failed: `$val` is not true; it evaluates to `Empty`

# You can say what you like
assert $val.&prime-factors.pick.is-prime, "mathematics gone wrong";
#= Assertion failed: mathematics gone wrong

# If condition is truthful, short-circuits, i.e., MESSAGE is not evaluated
assert True, destroy-the-universe();
#= Universe is still fine at this point

# The error is CATCHable as:
{
    CATCH {
        when X::Assertion {
            ...
        }
    }
    assert ...;
}

# If more than 2 things are supplied, it errs in compile time
assert $val, "message", "and some more";
#`[
===SORRY!=== Error while compiling some/file.raku
That's too assertive; expected 1 or 2 things, got 3
at some/file.raku:5
------> assert $val, "message", "and some more"⏏;
]
```

### .WHAT, .WHY, .HOW
Sometimes you want to make sure something is something in the program flow; `assert` does
that for you, like in C, Java, Python and others. It compiles to something like `die MESSAGE
unless EXPR`, which a programmer could be lazy enough not to write in full. So this module
refines the main slang to do that with the word `assert`.

#### Installation
Using [pakku](https://github.com/hythm7/Pakku):
```sh
pakku add Asserter
```
