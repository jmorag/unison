next steps:

- [x] add format tag to watch cache expressions?
- [x] fix up `Operations.loadBranchByCausalHash`; currently it's getting a single namespace, but we need to somewhere get the causal history.
	- [x] load a causal, allowing a missing value (C.Branch.Spine)
	- [x] load a causal and require its value (C.Branch.Causal)
	- [x] load a causal, returning nothing if causal is unknown
- [x] `SqliteCodebase.Conversions.unsafecausalbranch2to1`
- [x] `SqliteCodebase.getRootBranch`
- [x] `SqliteCodebase.getBranchForHash`
- [x] Writing a branch
  - [x] `SqliteCodebase.Conversions.causalbranch1to2`
  - [x] `SqliteCodebase.putRootBranch`
- [x] Syncing a remote codebase
  - [x] `SqliteCodebase.syncFromDirectory`
  - [x] `SqliteCodebase.syncToDirectory`
    - [x] do I need to initialize a sqlite codebase in the destination?
- [ ] Managing external edit events?
  - [x] `SqliteCodebase.rootBranchUpdates` Is there some Sqlite function for detecting external changes?
  - https://www.sqlite.org/pragma.html#pragma_data_version
  - https://user-images.githubusercontent.com/538571/111105100-8f0b4a80-8528-11eb-95f6-12bb906f315e.
  - [ ] to get updates notifications, we could watch the sqlite file itself for changes, and check
  png
- [x] consider using `causal` table to detect if a causal exists, instead of causal_parent?
- [x] no root found, for new codebase?
      .> ls

        ❗️

        I couldn't find the codebase root!
- [x] set-root-branch being called inappropriately on `pull`
- [ ] weird error message when codebase doesn't exist
    C:\Users\arya\unison>stack exec unison
    unison.EXE: SQLite3 returned ErrorCan'tOpen while attempting to perform open "C:\\Users\\arya\\.unison\\v2\\unison.sqlite3": unable to open database file

- [x] UnknownHashId (HashId 2179)
    arya@jrrr unison % stack exec unison -- -codebase /tmp/getbase3 init
    Initializing a new codebase in: /private/tmp/getbase3
    arya@jrrr unison % stack exec unison -- -codebase /tmp/getbase3

    .> pull https://github.com/aryairani/base-v2 ._base
      Importing downloaded files into local codebase...
    unison: DatabaseIntegrityError (UnknownHashId (HashId 2179))
    CallStack (from HasCallStack):
      error, called at src/Unison/Codebase/SqliteCodebase.hs:802:29 in unison-parser-typechecker-0.0.0-HGDWpz1IYHwGxjjnh5rX1K:Unison.Codebase.SqliteCodebase
    arya@jrrr unison % stack exec unison -- -codebase /tmp/getbase3

    .> pull https://github.com/aryairani/base-v2 ._base

      Nothing changed as a result of the merge.


      😶

      ._base was already up-to-date with https://github.com/aryairani/base-v2.

    .> ls

      1. releases/ (2438 definitions)
      2. series/   (1219 definitions)
      3. trunk/    (1652 definitions)

    .> history

      Note: The most recent namespace hash is immediately below this message.

      ⊙ #agu597jbfn


what even are these:
- [ ] Implement relational metadata
- [ ] do the tag thing to make sure that causal hashes comes from a unique token string compared to other stuff in the codebase. (maybe `accumulate` should take a tag as its first argument, forcing us to audit all the call sites)

### SqliteCodebase progress (V1 -> V2 adaptor)

| operation               | status | notes |
| ----------------------- | ------ | ----- |
| getTerm                 | ✔      |       |
| getTypeOfTerm           | ✔      |       |
| getTypeDeclaration      | ✔      |       |
| putTerm                 | ✔      |       |
| putTypeDeclaration      | ✔      |       |
| getRootBranch           | ✔      |       |
| putRootBranch           | ✔      |       |
| rootBranchUpdates       | ✔      |       |
| getBranchForHash        | ✔      |       |
| dependentsImpl          | ✔      |       |
| syncFromDirectory       | todo   |       |
| syncToDirectory         | todo   |       |
| watches                 | ✔      |       |
| getWatch                | ✔      |       |
| putWatch                | ✔      |       |
| getReflog               | ✔      |       |
| appendRefLog            | ✔      |       |
| termsOfTypeImpl         | ✔      |       |
| termsMentioningTypeImpl | ✔      |       |
| hashLength              | ✔      |       |
| termReferencesByPrefix  | ✔      |       |
| declReferencesByPrefix  | ✔      |       |
| referentsByPrefix       | ✔      |       |
| branchHashLength        | ✔      |       |
| branchHashesByPrefix    | ✔      |       |


## less organized stuff below

| thing | v1↔v2 | v2↔v2s | desc. |
|-----|-----|-----|---|
|`Reference` | ✔ ✔ | . . |builtin or user-defined term or type|
|Recursive `Reference` | ✔ ✔ |  ||
|`Reference.Id` | ✔ ✔ | . . |user-defined term or type|
|Recursive `Reference.Id` | ✔ ✔ |  ||
|`ReferenceH` |  | . . | weak `Reference`|
|`Reference.IdH` |  | . . | weak `Reference.Id` |
|`Referent` |  | . . |builtin or user-defined function or constructor|
|Recursive `Referent` | ✔ ✔ |  ||
|`Referent.Id` | ✔← | . . | user-defined term or type |
|`ReferentH` |  | . . | weak `Referent` |
|`Referent.IdH` |  | . . | weak `Referent.Id` |
|`Hash` | ✔ ✔ | n/a |  |
|`ShortBranchHash` | →✔ |  | the base32 prefix of a branch/causal hash |
|`ConstructorType` | ✔ ✔ |  | data vs ability |
|`WatchKind` | ✔ ✔ |  | test vs regular |
|`Term.Term` | ✔ ✔ |  |  |
|`Decl.Decl` | ✔ ✔ |  |  |
|`Type` | ✔ ✔ |  |  |
|recursive `Type` | ✔ ✔ |  |  |
|`Symbol` | ✔ ✔ |  |  |
|`ShortHash` |  |  |  |
|`ShortHash.cycle` | →✔ | n/a | read pos and discard length |
|`ShortHash.cid` |  | n/a | haven't gotten to referents yet |
|`ABT.Term` | ✔ ✔ | n/a |  |
|`Causal`/`Branch` |  |  |  |
|`Branch0` |  |  |  |

## `Operations.hs`

### Exists Check

| Exists Check     | name                  |
| ---------------- | --------------------- |
| `HashId` by `Hash` | `objectExistsForHash` |

### Id Lookups
| ID lookups                   | Create if not found | Fail if not found             |
| ---------------------------- | ------------------- | ----------------------------- |
| `Text -> TextId`             |                     | `lookupTextId`                |
| `TextId -> Text`             |                     | `loadTextById`                |
| `Hash -> HashId`             |                     | `hashToHashId`                |
| `Hash -> ObjectId`           |                     | `hashToObjectId`              |
| `ObjectId -> Hash`           |                     | `loadHashByObjectId`          |
| `HashId -> Hash`             |                     | `loadHashByHashId`            |
| `CausalHashId -> CausalHash` |                     | `loadCausalHashById`          |
| `CausalHashId -> BranchHash` |                     | `loadValueHashByCausalHashId` |

### V2 ↔ Sqlite tranversals

| V2 ↔ Sqlite conversion traversals                            | name                                | notes             |
| ------------------------------------------------------------ | ----------------------------------- | ----------------- |
| `Reference' Text Hash` ↔ `Reference' TextId ObjectId`        | `c2sReference`, `s2cReference`      | normal references |
| `Reference.Id' Hash` ↔ `Reference.Id' ObjectId`              | `c2sReferenceId`, `s2cReferenceId`  | normal user references |
| `Reference' Text Hash` ↔ `Reference' TextId HashId`          | `c2hReference`, `h2cReference`      | weak references   |
| `Referent'' TextId ObjectId` → `Referent'' Text Hash` | `s2cReferent` | normal referent |
| `Referent'' TextId HashId` → `Referent'' Text Hash` | `h2cReferent` | weak referent |
| `Referent.Id' ObjectId` → `Referent.Id' Hash` | `s2cReferentId` | normal user referent |
| `TermEdit` | `s2cTermEdit` |  |
| `TermEdit.Typing` | `c2sTyping`, `s2cTyping` |  |
| `TypeEdit` | `s2cTypeEdit` |  |
| `Branch0` | `s2cBranch` |  |
| Branch diff |  | todo |
| `Patch` | `s2cPatch`, `c2lPatch` | `l` = local ids |
| `Patch` diff | `diffPatch` |  |
| User `Term` | `c2sTerm`, `s2cTermWithType`, `s2cTerm`, `s2cTypeOfTerm` |  |
| watch expressions | `c2wTerm`, `w2cTerm` |  |
| User `Decl` | `c2sDecl`, |  |
| `Causal` |  | todo |

### Saving & loading?

| Saving & loading objects                | name                         | notes                                                       |
| --------------------------------------- | ---------------------------- | ----------------------------------------------------------- |
| `Patch` ↔ `PatchObjectId`               | `savePatch`, `loadPatchById` |                                                             |
| `H.Hash -> m (Maybe (Branch.Causal m))` | `loadBranchByCausalHash`     | wip                                                         |
| `CausalHashId -> m (Maybe Branch)`      | `loadBranchByCausalHashId`   | equivalent to old `Branch0`, *not sure if actually useful?* |
| `BranchObjectId -> m (Branch m)`        | `loadBranchByObjectId`       | equivalent to old `Branch0`                                 |

### Deserialization helpers

| Deserialization helpers                                      |                                                              | notes |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ----- |
| `decodeComponentLengthOnly`                                  | `ByteString -> m Word64`                                     |       |
| `decodeTermElementWithType`                                  | `C.Reference.Pos -> ByteString -> m (LocalIds, S.Term.Term, S.Term.Type)` |       |
| `decodeTermElementDiscardingTerm`, `decodeTermElementDiscardingType` | `-> m (LocalIds, S.Term.Term)`, `-> m (LocalIds, S.Term.Type)` |       |
| `decodeDeclElement`                                          | `Word64 -> ByteString -> m (LocalIds, S.Decl.Decl Symbol)`   |       |
| `deserializePatchObject`                                     | `PatchObjectId -> PatchFormat`                               |       |

### Reconstruct V1 data

| Reconstruct V1 data      |                                |
| ------------------------ | ------------------------------ |
| `getCycleLen`            | `Hash -> m Word64`             |
| `getDeclTypeByReference` | `Reference.Id -> DeclType`     |
| `componentByObjectId`    | `ObjectId -> m [Reference.Id]` |

### Codebase-y operations

|Codebase-y operations| type     | notes |
| ----------------------------- | ----------------------------- | ----- |
| `loadTermWithTypeByReference` | `Reference.Id -> MaybeT m (Term, Type)` |       |
| `loadTermByReference` | `Reference.Id -> MaybeT m Term` ||
| `loadTypeOfTermByTermReference` | `Reference.Id -> Maybe T m Type` ||
| `saveTermComponent` | `Hash -> [(Term, Type)] -> ObjectId` ||
| `loadDeclByReference` | `Reference.Id -> MaybeT m Decl` ||
| `saveDeclComponent` | `Hash -> [Decl] -> m ObjectId` ||
| `loadWatch` | `WatchKind -> Reference.Id -> MaybeT m Term` ||
| `saveWatch` | `WatchKind -> Reference.Id -> Term -> m ()` ||
| `termsHavingType` | `Reference -> m (Set Reference.Id)` ||
| `termsMentioningType` | " ||
| `termReferencesByPrefix` | `Text -> Maybe Word64 -> m [Reference.Id]` ||
| `declReferencesByPrefix` | `Text -> Maybe Word64 -> m [Reference.Id]` ||
| `saveRootBranch` | `Branch.Causal m -> m (Db.BranchObjectId, Db.CausalHashId)` |wip|
| `loadRootCausal` | `m (C.Branch.Causal m)` ||

## Questions:

Q: Should the dependents / dependency index include individual constructors?

Against: No, that index is mainly for refactors; dependencies within objects

For: e.g. `type Foo = Blah | Blah2 Nat`,

* If patches can replace constructors (not just types or terms), then having the index keyed by `Referent` lets you efficiently target the definitions that use those constructors.
* Also lets you find things that depend on `Blah2` (rather than depending on `Foo`).
