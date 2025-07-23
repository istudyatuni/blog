#import "/lib.typ": template, wip, folders

#let meta = (
    folder: folders.blog,
    title: "Why I don't like Go",
    subtitle: "as the language",
    draft: true,
    // title: "Yet another article about how bad Go is",
)

#show: template.with(..meta)

// #show raw.where(lang: none): set raw(lang: "go")
// #show ref.where(target: heading): it => {}
// #table(columns: 10, ..dictionary(html).keys())

#let magic = [#emoji.sparkles magic #emoji.sparkles]

This is just a list of my pain points which I collected over the last #(datetime.today().year() - 2022) years (sounds like an achievement). Maybe some, maybe all of them are a matter of taste

All points, except first 2, are listed without explicit order

// 4
- ```go if err != nil```, classic point in criticism of Go. Loosely typed error, combined with the lack of compiler-enforced checks gives you little control over what's happening. But it's better than exceptions, can't disagree. But "better" doesn't mean "good", do not forget it. But this #link("https://go.dev/blog/error-syntax")[won't change] in the "foreseeable future"
- Many things that are warnings in other languages, are hard errors:
    // 6
    - You can't reuse variable name if you do not need old value anymore
    // 3
    - You can't just add unused import, because code won't compile. Why it's bad? It bothers me when I want to comment some code to run test again just to find out that some import is unused. Also you can't compile unused variables

        // 3
        But on the other hand, this "warning" about unused variables can silently skip it if it's not really used:
        ```go
        x, err := foo()
        if err != nil { /* handle */ }
        x, err = foo()
        // err is ignored
        x, err = foo()
        if err != nil { /* handle */ }
        ```

    // 15
    - Writing ```go fmt.Println("%v", a)``` leads to _`has potentional Printf formatting directive %v`_. Yes, it's rare, but anyway
// 18
- You can't have 2 modules and import types from one to another and vice versa, because cyclic dependencies!
// 17
- That's a problem not only with Go, but. You can't tell whether the slice/map that you pass to a function will be modified by this function without looking inside
// 10
- Why do you want to write ```go arr.append(value)```, when you can just ```go append(arr, value)```?
// 11
- ```go :=``` overrides all variables on the left, leading to not so rare situation like this:
    ```go
    a := 5
    if /* something */ {
        // you can't do this if you want to update "a"
        a, err := foo()
        // you need do this instead:
        newA, err := foo()
        // ...
        a = newA
    }
    ```
// 12
- Language server also has a problems (I use it in Sublime Text via LSP-gopls):
    - Sometimes it doesn't load changes after ```sh go mod tidy``` and you need to open files with definitions/functions from module with not-yet-loaded definitions, so LSP will see it
    - When you remove/comment out unused import, other unused imports stops red highlighting, and you need to save file and wait a bit to see it again
// 2
- When you write array elements or function arguments on separate lines, you should place trailing comma in the end, and you can tell that this is for "better developer experience", so that you can easily add a new line. But. When you place _calls_ on separate lines, why you can't place dots on the left like:

    ```go
    ExprBuilder()
        .Left(Expr())
        .Right(Expr())
    ```

    but should instead place it on the right side:

    ```go
    ExprBuilder().
        Left(Expr()).
        Right(Expr())
    ```

    You can't comment last line. You can't "easily" add a new line. Just why
// 14
- When something can't be compiled (e.g. you don't use a variable) compiler will also show you errors in all places where module with this error is imported, so you should scan with yours eyes non-highlighted output where all lines are placed very tight to find an original error. Nice!
// 5
- Due to compiler #magic some operations return varying number of arguments, depending on the number of arguments on the left side of assignment. By "magic" I mean that this is not allowed for user functions. For example, type assertion:

    ```go
    n1 := (a).(string)
    n2, ok := (a).(string)
    ```

    This feel frustrating when you _think_ that some operation work in some way, but then turns out you was wrong. See below for more examples

// 8
- Continuing previous point: why ```go a``` in ```go for a := range slice {}``` is an index but in ```go for _, a := range slice {}``` is a value? Strange decision, I barely use former variant
// 7
- ```go for``` for everything

    _In some examples I wrote types instead of values to simplify code_

    #let same = [_same as above_]

    - ```go for {}``` - infinite loop
    - ```go for i < 10 {}``` - while loop
    - ```go for ; i < 10; {}``` - #same
    - ```go for i := 0; i < 10; i++ {}``` - basic C-style loop
    - ```go for i := range 10 {}``` - #same
    - ```go for index := range []any {}``` - over indices
    - ```go for index := range "string" {}``` - #same
    - ```go for index, item := range []any {}``` - over indices and values
    - ```go for index, rune := range "string" {}``` - over indices and chars /*(aka runes)*/
    - ```go for key, value := range map[any]any {}``` - over map's key/values
    - ```go for value := range chan T {}``` - over channel's values
    - ```go for range chan T {}``` - empty a channel (wtf?)
    - Copied from #link("https://go.dev/ref/spec#For_range")[the spec] because I just don't know what is this:
        ```go
        // fibo generates the Fibonacci sequence
        fibo := func(yield func(x int) bool) {
            f0, f1 := 0, 1
            for yield(f0) {
                f0, f1 = f1, f0 + f1
            }
        }

        // print the Fibonacci numbers below 1000:
        for x := range fibo {
            if x >= 1000 {
                break
            }
            fmt.Printf("%d ", x)
        }
        // output: 0 1 1 2 3 5 8 13 21 34 55 89 144 233 377 610 987
        ```
// 1
- Formatter is limited. Yes, there are external formatters, but...
    - #link("https://go.dev/doc/effective_go#formatting")[Not handles] long lines

        #quote[Go has no line length limit. Don't worry about overflowing a punched card. If a line feels too long, wrap it and indent with an extra tab.]

    - Can't add trailing commas (that's a compilation error, as you remember)
    - I personally not a fan of "aligning separated items in a grid" (don't know how is this called), but no so strongly, it looks good in some cases. Example:

        ```go
        type A struct {
            a      string         `json:"a"`      // some description
            foobar map[string]any `json:"foobar"` // some comment
        }
        ```

        I guess it's formatted this way because there can be more than 2 "elements" on a single row of struct literal (type definition or struct construction), and it will be hard to read otherwise
    // - `gofumpt` (external formatter)
- Specifying template for time parsing is weird. It basically looks like a date, but just with specific values. From standard library:
    ```go
    const RFC3339 = "2006-01-02T15:04:05Z07:00"
    ```
    See below for example usage
// 9
- You can't just increase major version of library, because you also need to update all the imports, and all your users should do the same. Everywhere, where this library is imported. Meh
- That's not the case in the last half of year (if I remember time spans correctly), but one of the popular linters, `golangci-lint` (I don't know others, to be honest), was very bad at supporting backward compatibility for its configuration

== Something that I was wrong about <i-was-wrong>

I wrote this down at some point, but tested it now and turns out it's not true

- Two ```go time.Time``` objects which hold equal time but has different time zones, are #strike[not] equal

    ```go
    t1, _ := time.Parse(time.RFC3339, "2006-01-01T10:00:00Z")
    t2, _ := time.Parse(time.RFC3339, "2006-01-01T11:00:00+01:00")
    fmt.Println(t1.Compare(t2)) // output: 0 - means equal
    ```

    #link("https://go.dev/play/p/ElbZ40S_RIH")[Playground], #link("https://pkg.go.dev/time#Time.Compare")[docs]

== Something that I didn't faced myself <more-problems>

because I didn't use it (yet), but there are more problems exists

- Paths are bad. Read #link("https://fasterthanli.me/articles/i-want-off-mr-golangs-wild-ride")[I want off Mr. Golang's Wild Ride] for more
- ```go rune``` type is defined as ```go type rune = int32```. I'm not an UTF-8 expert, but as I understand, this is wrong. Read #link("https://janert.me/blog/2024/go-is-weird-strings/")[Go is Weird: Strings] for more
