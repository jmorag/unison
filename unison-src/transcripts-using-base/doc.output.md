# Computable documents in Unison

Unison documentation is written in Unison and has some neat features:

* The documentation type provides a rich vocabulary of elements that go beyond markdown, including asides, callouts, tooltips, and more.
* Docs may contain Unison code which is parsed and typechecked to ensure validity. No more out of date examples that don't compile or assume a bunch of implicit context!
* Embeded examples are live and can show the results of evaluation. This uses the same evaluation cache as Unison's scratch files, allowing Unison docs to function like well-commented spreadsheets or notebooks.
* Links to other definitions are typechecked to ensure they point to valid defintions. The links are resolved to hashes and won't be broken by name changes or moving definitions around.
* Docs can be included in other docs and you can assemble documentation programmatically, using Unison code.
* There's a powerful textual syntax for all of the above, which we'll introduce next.

## Introduction

Documentation blocks start with `{{` and end with a matching `}}`. You can introduce doc blocks anywhere you'd use an expression, and you can also have anonymous documentation blocks immediately before a top-level term or type.

```unison
name = {{Alice}}
d1 = {{ Hello there {{name}}! }}

{{ An important constant, equal to @eval{ImportantConstant} }}
ImportantConstant = 41 + 1

{{
The 7 days of the week, defined as:

  @source{type DayOfWeek}
}}
unique type time.DayOfWeek = Sun | Mon | Tue | Wed | Thu | Fri | Sat
```

```ucm

  I found and typechecked these definitions in scratch.u. If you
  do an `add` or `update`, here's how your codebase would
  change:
  
    ⍟ These new definitions are ok to `add`:
    
      unique type time.DayOfWeek
      ImportantConstant     : Nat
      ImportantConstant.doc : Doc2
      d1                    : Doc2
      name                  : Doc2
      time.DayOfWeek.doc    : Doc2

```
Notice that an anonymous documentation block `{{ ... }}` before a definition `ImportantConstant` is just syntax sugar for `ImportantConstant.doc = {{ ... }}`.

You can preview what docs will look like when rendered to the console using the `display` or `docs` commands:

```ucm
.> display d1

  Hello there Alice!

.> docs ImportantConstant

  An important constant, equal to `42`

.> docs DayOfWeek

  The 7 days of the week, defined as:
  
      unique type DayOfWeek
        = Sun
        | Mon
        | Tue
        | Wed
        | Thu
        | Fri
        | Sat

```
The `docs ImportantConstant` command will look for `ImportantConstant.doc` in the file or codebase. You can do this instead of explicitly linking docs to definitions.

## Syntax guide

First, we'll load the `syntax.u` file which has examples of all the syntax:

```ucm
.> load ./unison-src/transcripts-using-base/doc.md.files/syntax.u

  I found and typechecked these definitions in
  ./unison-src/transcripts-using-base/doc.md.files/syntax.u. If
  you do an `add` or `update`, here's how your codebase would
  change:
  
    ⍟ These new definitions are ok to `add`:
    
      basicFormatting     : Doc2
      doc.guide           : Doc2
      evaluation          : Doc2
      includingSource     : Doc2
      lists               : Doc2
      nonUnisonCodeBlocks : Doc2
      otherElements       : Doc2
      sqr                 : Nat -> Nat

```
Now we can review different portions of the guide.
we'll show both the pretty-printed source using `view`
and the rendered output using `display`:

```ucm
.> view basicFormatting

  basicFormatting : Doc2
  basicFormatting =
    {{
    # Basic formatting
    
      Paragraphs are separated by one or more blanklines.
      Sections have a title and 0 or more paragraphs or other
      section elements.
      
      Text can be __bold__, *italicized*, ~~strikethrough~~, or
      ''monospaced''.
      
      You can link to Unison terms, types, and external URLs:
      
      * [An external url](https://unisonweb.org)
      * {Some} is a term link; {type Optional} is a type link
      * [A named type link]({type Optional}) and
        [a named term link]({Some}). Term links are handy for
        linking to other documents!
      
      You can use ''{{ .. }}'' to escape out to regular Unison
      syntax, for instance {{ docWord "__not bold__" }}. This is
      useful for creating documents programmatically or just
      including other documents.
      
      *Next up:* {lists}
    }}

.> display basicFormatting

  # Basic formatting
  
    Paragraphs are separated by one or more blanklines. Sections
    have a title and 0 or more paragraphs or other section
    elements.
  
    Text can be bold, *italicized*, ~~strikethrough~~, or
    `monospaced`.
  
    You can link to Unison terms, types, and external URLs:
  
    * An external url
    * Some is a term link; Optional is a type link
    * A named type link and a named term link. Term links are
      handy for linking to other documents!
  
    You can use `{{ .. }}` to escape out to regular Unison
    syntax, for instance __not bold__. This is useful for
    creating documents programmatically or just including other
    documents.
  
    *Next up:* lists

.> view lists

  lists : Doc2
  lists =
    {{
    # Lists
    
      ## Bulleted lists
      
         Bulleted lists can use ''+'', ''-'', or ''*'' for the
         bullets (though the choice will be normalized away by
         the pretty-printer). They can be nested, to any depth:
         
         * A
         * B
         * C
           * C1
           * C2
      
      ## Numbered lists
      
         1. A
         2. B
         3. C
         
         The first number of the list determines the starting
         number in the rendered output. The other numbers are
         ignored:
         
         10. A
         11. B
         12. C
         
         Numbered lists can be nested as well, and combined with
         bulleted lists:
         
         1. Wake up.
            * What am I doing here?
            * In this nested list.
         2. Take shower.
         3. Get dressed.
    }}

.> display lists

  # Lists
  
    # Bulleted lists
    
      Bulleted lists can use `+`, `-`, or `*` for the bullets
      (though the choice will be normalized away by the
      pretty-printer). They can be nested, to any depth:
    
      * A
      * B
      * C
        * C1
        * C2
  
    # Numbered lists
    
      1. A
      2. B
      3. C
    
      The first number of the list determines the starting
      number in the rendered output. The other numbers are
      ignored:
    
      10. A
      11. B
      12. C
    
      Numbered lists can be nested as well, and combined with
      bulleted lists:
    
      1. Wake up.
         * What am I doing here?
         * In this nested list.
      2. Take shower.
      3. Get dressed.

.> view evaluation

  evaluation : Doc2
  evaluation =
    use Nat +
    {{
    # Evaluation
    
      Expressions can be evaluated inline, for instance
      @eval{1 + 1}.
      
      Blocks of code can be evaluated as well, for instance:
      
      ```
      id x = x
      id (sqr 10)
      ```
      
      To include a typechecked snippet of code without
      evaluating it, you can do:
      
      @typecheck ```
      cube : Nat -> Nat
      cube x =
        use Nat *
        x * x * x
      ```
    }}

.> display evaluation

  # Evaluation
  
    Expressions can be evaluated inline, for instance `2`.
  
    Blocks of code can be evaluated as well, for instance:
  
        id x = x
        id (sqr 10)
        ⧨
        100
  
    To include a typechecked snippet of code without evaluating
    it, you can do:
  
        cube x =
          use Nat *
          x * x * x

.> view includingSource

  includingSource : Doc2
  includingSource =
    use Nat +
    {{
    # Including Unison source code
    
      Unison definitions can be included in docs. For instance:
      
          @source{type Optional, sqr}
      
      Some rendering targets also support folded source:
      
          @foldedSource{type Optional, sqr}
      
      You can also include just a signature, inline, with
      @inlineSignature{sqr}, or you can include one or more
      signatures as a block:
      
          @signatures{sqr, +}
      
      Or alternately:
      
          @signature{List.map}
      
      ## Inline snippets
      
         You can include typechecked code snippets inline, for
         instance:
         
         * {{ docExample 2 '(f x -> f x + sqr 1) }} - the ''2''
           says to ignore the first two arguments when
           rendering. In richer renderers, the ''sqr'' link will
           be clickable.
         * If your snippet expression is just a single function
           application, you can put it in double backticks, like
           so: ``sqr x``. This is equivalent to
           {{ docExample 1 '(x -> sqr x) }}.
    }}

.> display includingSource

  # Including Unison source code
  
    Unison definitions can be included in docs. For instance:
  
        type Optional a = None | Some a
        
        sqr x =
          use Nat *
          x * x
  
    Some rendering targets also support folded source:
  
        type Optional a = None | Some a
        
        sqr x =
          use Nat *
          x * x
  
    You can also include just a signature, inline, with
    `sqr : Nat -> Nat`, or you can include one or more
    signatures as a block:
  
        sqr : Nat -> Nat
    
        Nat.+ : Nat -> Nat -> Nat
  
    Or alternately:
  
        List.map : (a ->{e} b) -> [a] ->{e} [b]
  
    # Inline snippets
    
      You can include typechecked code snippets inline, for
      instance:
    
      * `f x Nat.+ sqr 1` - the `2` says to ignore the first two
        arguments when rendering. In richer renderers, the `sqr`
        link will be clickable.
      * If your snippet expression is just a single function
        application, you can put it in double backticks, like
        so: `sqr x`. This is equivalent to `sqr x`.

.> view nonUnisonCodeBlocks

  nonUnisonCodeBlocks : Doc2
  nonUnisonCodeBlocks =
    {{
    # Non-Unison code blocks
    
      Use three or more single quotes to start a block with no
      syntax highlighting:
      
      '''
         _____     _             
        |  |  |___|_|___ ___ ___ 
        |  |  |   | |_ -| . |   |
        |_____|_|_|_|___|___|_|_|
        
      '''
      
      You can use three or more backticks plus a language name
      for blocks with syntax highlighting:
      
      ``` Haskell
      -- A fenced code block which isn't parsed by Unison
      reverse = foldl (flip (:)) []
      ```
      
      ``` Scala
      // A fenced code block which isn't parsed by Unison
      def reverse[A](xs: List[A]) = 
        xs.foldLeft(Nil : List[A])((acc,a) => a +: acc)
      ```
    }}

.> display nonUnisonCodeBlocks

  # Non-Unison code blocks
  
    Use three or more single quotes to start a block with no
    syntax highlighting:
  
    ``` raw
       _____     _             
      |  |  |___|_|___ ___ ___ 
      |  |  |   | |_ -| . |   |
      |_____|_|_|_|___|___|_|_|
      
    ```
  
    You can use three or more backticks plus a language name for
    blocks with syntax highlighting:
  
    ``` Haskell
    -- A fenced code block which isn't parsed by Unison
    reverse = foldl (flip (:)) []
    ```
  
    ``` Scala
    // A fenced code block which isn't parsed by Unison
    def reverse[A](xs: List[A]) = 
      xs.foldLeft(Nil : List[A])((acc,a) => a +: acc)
    ```

.> view otherElements

  otherElements : Doc2
  otherElements =
    {{
    There are also asides, callouts, tables, tooltips, and more.
    These don't currently have special syntax; just use the
    ''{{ }}'' syntax to call these functions directly.
    
        @signatures{docAside, docCallout, docBlockquote, docTooltip, docTable}
    
    This is an aside. {{
    docAside
      {{ Some extra detail that doesn't belong in main text. }}
    }}
    
    {{
    docCallout
      None {{ This is an important callout, with no icon. }} }}
    
    {{
    docCallout
      (Some {{ 🌻 }})
      {{
      This is an important callout, with an icon. The text wraps
      onto multiple lines.
      }} }}
    
    {{
    docBlockquote
      {{
      "And what is the use of a book," thought Alice, "without
      pictures or conversation?"
      
      *Lewis Carroll, Alice's Adventures in Wonderland*
      }} }}
    
    {{ docTooltip {{ Hover over me }} {{ Extra detail }} }}
    
    {{
    docTable
      [ [ {{
      a
      }},
        {{
      b
      }},
        {{
      A longer paragraph that will split onto multiple lines,
      such that this row occupies multiple lines in the rendered
      table.
      }} ],
        [{{ Some text }}, {{ More text }}, {{ Zounds! }}] ] }}
    }}

.> display otherElements

  There are also asides, callouts, tables, tooltips, and more.
  These don't currently have special syntax; just use the
  `{{ }}` syntax to call these functions directly.
  
      docAside : Doc2 -> Doc2
  
      docCallout : Optional Doc2 -> Doc2 -> Doc2
  
      docBlockquote : Doc2 -> Doc2
  
      docTooltip : Doc2 -> Doc2 -> Doc2
  
      docTable : [[Doc2]] -> Doc2
  
  This is an aside. (
  Some extra detail that doesn't belong in main text. )
  
    | This is an important callout, with no icon.
  
    | 🌻
    | 
    | This is an important callout, with an icon. The text wraps
    | onto multiple lines.
  
  > "And what is the use of a book," thought Alice, "without
  > pictures or conversation?"
  > 
  > *Lewis Carroll, Alice's Adventures in Wonderland*
  
  Hover over me
  
  a           b           A longer paragraph that will split
                          onto multiple lines, such that this
                          row occupies multiple lines in the
                          rendered table.
  Some text   More text   Zounds!

```
Lastly, it's common to build longer documents including subdocuments via `{{ subdoc }}`. We can stitch together the full syntax guide in this way:

```ucm
.> view doc.guide

  doc.guide : Doc2
  doc.guide =
    {{ # Unison computable documentation
    
      {{ basicFormatting }}
      
      {{ lists }}
      
      {{ evaluation }}
      
      {{ includingSource }}
      
      {{ nonUnisonCodeBlocks }}
      
      {{ otherElements }} }}

.> display doc.guide

  # Unison computable documentation
  
    # Basic formatting
    
      Paragraphs are separated by one or more blanklines.
      Sections have a title and 0 or more paragraphs or other
      section elements.
    
      Text can be bold, *italicized*, ~~strikethrough~~, or
      `monospaced`.
    
      You can link to Unison terms, types, and external URLs:
    
      * An external url
      * Some is a term link; Optional is a type link
      * A named type link and a named term link. Term links are
        handy for linking to other documents!
    
      You can use `{{ .. }}` to escape out to regular Unison
      syntax, for instance __not bold__. This is useful for
      creating documents programmatically or just including
      other documents.
    
      *Next up:* lists
  
    # Lists
    
      # Bulleted lists
      
        Bulleted lists can use `+`, `-`, or `*` for the bullets
        (though the choice will be normalized away by the
        pretty-printer). They can be nested, to any depth:
      
        * A
        * B
        * C
          * C1
          * C2
    
      # Numbered lists
      
        1. A
        2. B
        3. C
      
        The first number of the list determines the starting
        number in the rendered output. The other numbers are
        ignored:
      
        10. A
        11. B
        12. C
      
        Numbered lists can be nested as well, and combined with
        bulleted lists:
      
        1. Wake up.
           * What am I doing here?
           * In this nested list.
        2. Take shower.
        3. Get dressed.
  
    # Evaluation
    
      Expressions can be evaluated inline, for instance `2`.
    
      Blocks of code can be evaluated as well, for instance:
    
          id x = x
          id (sqr 10)
          ⧨
          100
    
      To include a typechecked snippet of code without
      evaluating it, you can do:
    
          cube x =
            use Nat *
            x * x * x
  
    # Including Unison source code
    
      Unison definitions can be included in docs. For instance:
    
          type Optional a = None | Some a
          
          sqr x =
            use Nat *
            x * x
    
      Some rendering targets also support folded source:
    
          type Optional a = None | Some a
          
          sqr x =
            use Nat *
            x * x
    
      You can also include just a signature, inline, with
      `sqr : Nat -> Nat`, or you can include one or more
      signatures as a block:
    
          sqr : Nat -> Nat
      
          Nat.+ : Nat -> Nat -> Nat
    
      Or alternately:
    
          List.map : (a ->{e} b) -> [a] ->{e} [b]
    
      # Inline snippets
      
        You can include typechecked code snippets inline, for
        instance:
      
        * `f x Nat.+ sqr 1` - the `2` says to ignore the first
          two arguments when rendering. In richer renderers, the
          `sqr` link will be clickable.
        * If your snippet expression is just a single function
          application, you can put it in double backticks, like
          so: `sqr x`. This is equivalent to `sqr x`.
  
    # Non-Unison code blocks
    
      Use three or more single quotes to start a block with no
      syntax highlighting:
    
      ``` raw
         _____     _             
        |  |  |___|_|___ ___ ___ 
        |  |  |   | |_ -| . |   |
        |_____|_|_|_|___|___|_|_|
        
      ```
    
      You can use three or more backticks plus a language name
      for blocks with syntax highlighting:
    
      ``` Haskell
      -- A fenced code block which isn't parsed by Unison
      reverse = foldl (flip (:)) []
      ```
    
      ``` Scala
      // A fenced code block which isn't parsed by Unison
      def reverse[A](xs: List[A]) = 
        xs.foldLeft(Nil : List[A])((acc,a) => a +: acc)
      ```
  
    There are also asides, callouts, tables, tooltips, and more.
    These don't currently have special syntax; just use the
    `{{ }}` syntax to call these functions directly.
    
        docAside : Doc2 -> Doc2
    
        docCallout : Optional Doc2 -> Doc2 -> Doc2
    
        docBlockquote : Doc2 -> Doc2
    
        docTooltip : Doc2 -> Doc2 -> Doc2
    
        docTable : [[Doc2]] -> Doc2
    
    This is an aside. (
    Some extra detail that doesn't belong in main text. )
    
      | This is an important callout, with no icon.
    
      | 🌻
      | 
      | This is an important callout, with an icon. The text
      | wraps onto multiple lines.
    
    > "And what is the use of a book," thought Alice, "without
    > pictures or conversation?"
    > 
    > *Lewis Carroll, Alice's Adventures in Wonderland*
    
    Hover over me
    
    a           b           A longer paragraph that will split
                            onto multiple lines, such that this
                            row occupies multiple lines in the
                            rendered table.
    Some text   More text   Zounds!

```
🌻 THE END
