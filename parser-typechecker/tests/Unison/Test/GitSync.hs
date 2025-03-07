{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE QuasiQuotes #-}

module Unison.Test.GitSync where

import Data.Maybe (fromJust)
import Data.String.Here.Interpolated (i)
import qualified Data.Text as Text
import EasyTest
import Shellmet ()
import System.Directory (removeDirectoryRecursive)
import System.FilePath ((</>))
import qualified System.IO.Temp as Temp
import qualified Unison.Codebase as Codebase
import Unison.Codebase (Codebase)
import Unison.Parser (Ann)
import Unison.Prelude
import Unison.Symbol (Symbol)
import Unison.Test.Ucm (CodebaseFormat, Transcript)
import qualified Unison.Test.Ucm as Ucm
import Unison.UnisonFile (pattern TestWatch)

-- keep it off for CI, since the random temp dirs it generates show up in the
-- output, which causes the test output to change, and the "no change" check
-- to fail
writeTranscriptOutput :: Bool
writeTranscriptOutput = False

test :: Test ()
test = scope "gitsync22" . tests $
  fastForwardPush :
  nonFastForwardPush :
  flip map [(Ucm.CodebaseFormat1 , "fc"), (Ucm.CodebaseFormat2, "sc")]
  \(fmt, name) -> scope name $ tests [
  pushPullTest  "typeAlias" fmt
    (\repo -> [i|
      ```ucm
      .> alias.type ##Nat builtin.Nat
      .> history
      .> history builtin
      .> push ${repo}
      ```
    |])
    (\repo -> [i|
      ```ucm
      .> pull ${repo}
      ```
      ```unison
      x : Nat
      x = 3
      ```
    |])
  ,
  pushPullTest  "topLevelTerm" fmt
    (\repo -> [i|
      ```unison:hide
      y = 3
      ```
      ```ucm
      .> add
      .> history
      .> push ${repo}
      ```
    |])
    (\repo -> [i|
      ```ucm
      .> pull ${repo}
      .> find
      ```
      ```unison
      > y
      ```
    |])
  ,
  pushPullTest  "metadataForTerm" fmt
    (\repo -> [i|
          ```unison:hide
          doc = "y is the number 3"
          y = 3
          ```
          ```ucm
          .> debug.file
          .> add
          .> link doc y
          .> links y
          .> history
          .> push ${repo}
          ```
    |])
    (\repo -> [i|
        ```ucm
        .> pull ${repo}
        .> links y
        ```
    |])
  ,
  pushPullTest  "metadataForType" fmt
    (\repo -> [i|
          ```unison:hide
          doc = "Nat means natural number"
          ```
          ```ucm
          .> add
          .> alias.type ##Nat Nat
          .> link doc Nat
          .> push ${repo}
          ```
    |])
    (\repo -> [i|
        ```ucm
        .> pull ${repo}
        .> links Nat
        ```
    |])
  ,
  pushPullTest  "subNamespace" fmt
    (\repo -> [i|
          ```ucm
          .> alias.type ##Nat builtin.Nat
          ```
          ```unison
          unique type a.b.C = C Nat
          a.b.d = 4
          ```
          ```ucm
          .> add
          .> push ${repo}
          ```
    |])
    (\repo -> [i|
        ```ucm
        .> pull ${repo}
        .> find
        ```
        ```unison
        > a.b.C.C a.b.d
        ```
    |])
  ,
  pushPullTest  "accessPatch" fmt
    (\repo -> [i|
          ```ucm
          .> alias.type ##Nat builtin.Nat
          ```
          ```unison:hide
          unique type A = A Nat
          foo = A.A 3
          ```
          ```ucm
          .> debug.file
          .> add
          ```
          ```unison:hide
          unique type A = A Nat Nat
          foo = A.A 3 3
          ```
          ```ucm
          .> debug.file
          .> update
          ```
          ```ucm
          .> view.patch patch
          .> push ${repo}
          ```
    |])
    (\repo -> [i|
        ```ucm
        .> pull ${repo}
        .> view.patch patch
        ```
    |])
  ,
  pushPullTest  "history" fmt
    (\repo -> [i|
          ```unison
          foo = 3
          ```
          ```ucm
          .> add
          ```
          ```unison
          foo = 4
          ```
          ```ucm
          .> update
          .> history
          .> push ${repo}
          ```
    |])
    (\repo -> [i|
        ```ucm
        .> pull ${repo}
        .> history
        .> reset-root #dsh
        .> history
        ```
    |])
  ,

  pushPullTest "one-term" fmt
-- simplest-author
    (\repo -> [i|
      ```unison
      c = 3
      ```
      ```ucm
      .> debug.file
      .> add
      .> push ${repo}
      ```
    |])
-- simplest-user
    (\repo -> [i|
      ```ucm
      .> pull ${repo}
      .> alias.term ##Nat.+ +
      ```
      ```unison
      > #msp7bv40rv + 1
      ```
    |])
  ,
  pushPullTest "one-term2" fmt
-- simplest-author
    (\repo -> [i|
      ```unison
      c = 3
      ```
      ```ucm
      .> debug.file
      .myLib> add
      .myLib> push ${repo}
      ```
      |])
-- simplest-user
    (\repo -> [i|
      ```ucm
      .yourLib> pull ${repo}
      ```
      ```unison
      > c
      ```
      |])
  ,
  pushPullTest "one-type" fmt
-- simplest-author
    (\repo -> [i|
      ```unison
      type Foo = Foo
      ```
      ```ucm
      .myLib> debug.file
      .myLib> add
      .myLib> push ${repo}
      ```
      |])
-- simplest-user
    (\repo -> [i|
      ```ucm
      .yourLib> pull ${repo}
      ```
      ```unison
      > Foo.Foo
      ```
      |])
  ,
  pushPullTest "patching" fmt
    (\repo -> [i|
      ```ucm
      .myLib> alias.term ##Nat.+ +
      ```
      ```unison
      improveNat x = x + 3
      ```
      ```ucm
      .myLib> add
      .myLib> ls
      .myLib> move.namespace .myLib .workaround1552.myLib.v1
      .workaround1552.myLib> ls
      .workaround1552.myLib> fork v1 v2
      .workaround1552.myLib.v2>
      ```
      ```unison
      improveNat x = x + 100
      ```
      ```ucm
      .workaround1552.myLib.v2> update
      .workaround1552.myLib> push ${repo}
      ```
    |])
    (\repo -> [i|
      ```ucm
      .myApp> pull ${repo}:.v1 external.yourLib
      .myApp> alias.term ##Nat.* *
      ````
      ```unison
      greatApp = improveNat 5 * improveNat 6
      > greatApp
      ```
      ```ucm
      .myApp> add
      .myApp> pull ${repo}:.v2 external.yourLib
      ```
      ```unison
      > greatApp
      ```
      ```ucm
      .myApp> patch external.yourLib.patch
      ```
      ```unison
      > greatApp
      ```
    |])
  ,
  pushPullTest "lightweightPatch" fmt
    (\repo -> [i|
      ```ucm
      .> builtins.merge
      ```
      ```unison
      type A = A Nat
      type B = B Int
      x = 3
      y = 4
      ```
      ```ucm
      .defns> add
      .patches> replace.type .defns.A .defns.B
      .patches> replace.term .defns.x .defns.y
      .patches> push ${repo}
      ```
    |])
    (\repo -> [i|
      ```ucm
      .> builtins.merge
      .> pull ${repo} patches
      .> view.patch patches.patch
      ```
    |])
  ,
  watchPushPullTest "test-watches" fmt
    (\repo -> [i|
        ```ucm
        .> builtins.merge
        ```
        ```unison
        test> pass = [Ok "Passed"]
        ```
        ```ucm
        .> add
        .> push ${repo}
        ```
      |])
    (\repo -> [i|
        ```ucm
        .> pull ${repo}
        ```
      |])
    (\cb -> do
      void . fmap (fromJust . sequence) $
        traverse (Codebase.getWatch cb TestWatch) =<<
          Codebase.watches cb TestWatch)
  ,
  pushPullTest "fix2068(a)" fmt
    -- this triggers
    {-
gitsync22.sc.fix2068(a) EXCEPTION!!!: Called SqliteCodebase.setNamespaceRoot on unknown causal hash CausalHash (fromBase32Hex "codddvgt1ep57qpdkhe2j4pe1ehlpi5iitcrludtb8ves1aaqjl453onvfphqg83vukl7bbrj49itceqfob2b3alf47u4vves5s7pog")
CallStack (from HasCallStack):
  error, called at src/Unison/Codebase/SqliteCodebase.hs:1072:17 in unison-parser-typechecker-0.0.0-6U6boimwb8GAC5qrhLfs8h:Unison.Codebase.SqliteCodebase
     -}
    (\repo -> [i|
      ```ucm
      .> alias.type ##Nat builtin.Nat2
      .> alias.type ##Int builtin.Int2
      .> push ${repo}:.foo.bar
      ```
    |])
    (\repo -> [i|
      ```ucm
      .> pull ${repo} pulled
      .> view pulled.foo.bar.builtin.Nat2
      .> view pulled.foo.bar.builtin.Int2
      ```
    |])
  ,
  pushPullTest "fix2068(b)" fmt
    -- this triggers
    {-
     - gitsync22.sc.fix2068(b) EXCEPTION!!!: I couldn't find the hash ndn6fa85ggqtbgffqhd4d3bca2d08pgp3im36oa8k6p257aid90ovjq75htmh7lmg7akaqneva80ml1o21iscjmp9n1uc3lmqgg9rgg that I just synced to the cached copy of /private/var/folders/6m/p3szds2j67d8vwmxr51yrf5c0000gn/T/git-simple-1047398c149d3d5c/repo.git in "/Users/pchiusano/.cache/unisonlanguage/gitfiles/$x2F$private$x2F$var$x2F$folders$x2F$6m$x2F$p3szds2j67d8vwmxr51yrf5c0000gn$x2F$T$x2F$git-simple-1047398c149d3d5c$x2F$repo$dot$git".
CallStack (from HasCallStack):
  error, called at src/Unison/Codebase/SqliteCodebase.hs:1046:13 in unison-parser-typechecker-0.0.0-6U6boimwb8GAC5qrhLfs8h:Unison.Codebase.SqliteCodebase
     -}
    (\repo -> [i|
      ```ucm
      .> alias.type ##Nat builtin.Nat2
      .> alias.type ##Int builtin.Int2
      .> push ${repo}
      .> push ${repo}:.foo.bar
      ```
    |])
    (\repo -> [i|
      ```ucm
      .> pull ${repo} pulled
      .> view pulled.foo.bar.builtin.Nat2
      .> view pulled.foo.bar.builtin.Int2
      ```
    |])

          -- m [Reference.Id]

-- traverse :: (Traversable t, Applicative f) => (a -> f b) -> t a -> f (t b)
-- watches            :: UF.WatchKind -> m [Reference.Id]
-- getWatch           :: UF.WatchKind -> Reference.Id -> m (Maybe (Term v a))

  -- pushPullTest "regular" fmt
  --   (\repo -> [i|
  --   ```ucm:hide
  --   .builtin> alias.type ##Nat Nat
  --   .builtin> alias.term ##Nat.+ Nat.+
  --   ```
  --   ```unison
  --   unique type outside.A = A Nat
  --   unique type outside.B = B Nat Nat
  --   outside.c = 3
  --   outside.d = 4

  --   unique type inside.X = X outside.A
  --   inside.y = c + c
  --   ```
  --   ```ucm
  --   .myLib> debug.file
  --   .myLib> add
  --   .myLib> push ${repo}
  --   ```
  --   |])

  --       (\repo -> [i|
  --   ```ucm:hide
  --   .builtin> alias.type ##Nat Nat
  --   .builtin> alias.term ##Nat.+ Nat.+
  --   ```
  --   ```ucm
  --   .yourLib> pull ${repo}:.inside
  --   ```
  --   ```unison
  --   > y + #msp7bv40rv + 1
  --   ```
  --   |])
  ]

-- type inside.X#skinr6rvg7
-- type outside.A#l2fmn9sdbk
-- type outside.B#nsgsq4ot5u
-- inside.y#omqnfettvj
-- outside.c#msp7bv40rv
-- outside.d#52addbrohu
-- .myLib> #6l0nd3i15e
-- .myLib.inside> #5regvciils
-- .myLib.inside.X> #kvcjrmgki6
-- .myLib.outside> #uq1mkkhlf1
-- .myLib.outside.A> #0e3g041m56
-- .myLib.outside.B> #j57m94daqi

pushPullTest :: String -> CodebaseFormat -> (FilePath -> Transcript) -> (FilePath -> Transcript) -> Test ()
pushPullTest name fmt authorScript userScript = scope name do
  io do
    repo <- initGitRepo
    author <- Ucm.initCodebase fmt
    authorOutput <- Ucm.runTranscript author (authorScript repo)
    user <- Ucm.initCodebase fmt
    userOutput <- Ucm.runTranscript user (userScript repo)

    when writeTranscriptOutput $ writeFile
      ("unison-src"</>"transcripts"</>("GitSync22." ++ name ++ ".output.md"))
      (authorOutput <> "\n-------\n" <> userOutput)

    -- if we haven't crashed, clean up!
    removeDirectoryRecursive repo
    Ucm.deleteCodebase author
    Ucm.deleteCodebase user
  ok

watchPushPullTest :: String -> CodebaseFormat -> (FilePath -> Transcript) -> (FilePath -> Transcript) -> (Codebase IO Symbol Ann -> IO ()) -> Test ()
watchPushPullTest name fmt authorScript userScript codebaseCheck = scope name do
  io do
    repo <- initGitRepo
    author <- Ucm.initCodebase fmt
    authorOutput <- Ucm.runTranscript author (authorScript repo)
    user <- Ucm.initCodebase fmt
    userOutput <- Ucm.runTranscript user (userScript repo)
    Ucm.lowLevel user codebaseCheck

    when writeTranscriptOutput $ writeFile
      ("unison-src"</>"transcripts"</>("GitSync22." ++ name ++ ".output.md"))
      (authorOutput <> "\n-------\n" <> userOutput)

    -- if we haven't crashed, clean up!
    removeDirectoryRecursive repo
    Ucm.deleteCodebase author
    Ucm.deleteCodebase user
  ok

fastForwardPush :: Test ()
fastForwardPush = scope "fastforward-push" do
  io do
    repo <- initGitRepo
    author <- Ucm.initCodebase Ucm.CodebaseFormat2
    void $ Ucm.runTranscript author [i|
      ```ucm
      .lib> alias.type ##Nat Nat
      .lib> push ${repo}
      .lib> alias.type ##Int Int
      .lib> push ${repo}
      ```
    |]
  ok

nonFastForwardPush :: Test ()
nonFastForwardPush = scope "non-fastforward-push" do
  io do
    repo <- initGitRepo
    author <- Ucm.initCodebase Ucm.CodebaseFormat2
    void $ Ucm.runTranscript author [i|
      ```ucm:error
      .lib> alias.type ##Nat Nat
      .lib> push ${repo}
      .lib2> alias.type ##Int Int
      .lib2> push ${repo}
      ```
    |]
  ok

initGitRepo :: IO FilePath
initGitRepo = do
  tmp <- Temp.getCanonicalTemporaryDirectory >>= flip Temp.createTempDirectory ("git-simple")
  let repo = tmp </> "repo.git"
  "git" ["init", "--bare", Text.pack repo]
  pure repo
