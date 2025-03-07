{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}

module Unison.Codebase.Editor.Command (
  Command(..),
  AmbientAbilities,
  LexedSource,
  Source,
  SourceName,
  TypecheckingResult,
  LoadSourceResult(..),
  UseCache,
  EvalResult,
  commandName,
  lookupEvalResult
  ) where

import Unison.Prelude

import Control.Lens (_5,view)
-- TODO: Don't import backend, but move dependencies to own modules
import           Unison.Server.Backend          ( DefinitionResults
                                                , ShallowListEntry
                                                , BackendError
                                                )
import           Data.Configurator.Types        ( Configured )
import qualified Data.Map                      as Map

import           Unison.Codebase.Editor.Output
import           Unison.Codebase.Editor.RemoteRepo

import           Unison.Codebase.Branch         ( Branch )
import qualified Unison.Codebase.Branch        as Branch
import           Unison.Codebase.GitError
import qualified Unison.Codebase.Reflog        as Reflog
import           Unison.Codebase.SyncMode       ( SyncMode )
import           Unison.Names3                  ( Names, Names0 )
import           Unison.Parser                  ( Ann )
import           Unison.Referent                ( Referent )
import           Unison.Reference               ( Reference )
import           Unison.Result                  ( Note
                                                , Result)
import           Unison.DataDeclaration         ( Decl )
import qualified Unison.Codebase.Runtime       as Runtime
import qualified Unison.PrettyPrintEnv         as PPE
import qualified Unison.Reference              as Reference
import           Unison.Term                    ( Term )
import qualified Unison.UnisonFile             as UF
import qualified Unison.Lexer                  as L
import qualified Unison.Parser                 as Parser
import           Unison.ShortHash               ( ShortHash )
import           Unison.Type                    ( Type )
import           Unison.Codebase.ShortBranchHash
                                                ( ShortBranchHash )
import Unison.Codebase.Editor.AuthorInfo (AuthorInfo)
import Unison.Codebase.Path (Path)
import qualified Unison.Codebase.Path as Path
import qualified Unison.HashQualified as HQ
import Unison.Name (Name)
import Unison.Server.QueryResult (QueryResult)
import qualified Unison.Server.SearchResult as SR
import qualified Unison.Server.SearchResult' as SR'

type AmbientAbilities v = [Type v Ann]
type SourceName = Text
type Source = Text
type LexedSource = (Text, [L.Token L.Lexeme])

data LoadSourceResult = InvalidSourceNameError
                      | LoadError
                      | LoadSuccess Text

type TypecheckingResult v =
  Result (Seq (Note v Ann))
         (Either Names0 (UF.TypecheckedUnisonFile v Ann))

data Command m i v a where
  -- Escape hatch.
  Eval :: m a -> Command m i v a

  HQNameQuery
    :: Maybe Path
    -> Branch m
    -> [HQ.HashQualified Name]
    -> Command m i v QueryResult

  LoadSearchResults
    :: [SR.SearchResult] -> Command m i v [SR'.SearchResult' v Ann]

  GetDefinitionsBySuffixes
    :: Maybe Path
    -> Branch m
    -> [HQ.HashQualified Name]
    -> Command m i v (Either BackendError (DefinitionResults v))

  FindShallow
    :: Path.Absolute
    -> Command m i v (Either BackendError [ShallowListEntry v Ann])

  ConfigLookup :: Configured a => Text -> Command m i v (Maybe a)

  Input :: Command m i v i

  -- Presents some output to the user
  Notify :: Output v -> Command m i v ()
  NotifyNumbered :: NumberedOutput v -> Command m i v NumberedArgs

  -- literally just write some terms and types .unison/{terms,types}
  AddDefsToCodebase :: UF.TypecheckedUnisonFile v Ann -> Command m i v ()

  -- the hash length needed to disambiguate any definition in the codebase
  CodebaseHashLength :: Command m i v Int

  TypeReferencesByShortHash :: ShortHash -> Command m i v (Set Reference)
  TermReferencesByShortHash :: ShortHash -> Command m i v (Set Reference)
  TermReferentsByShortHash :: ShortHash -> Command m i v (Set Referent)

  -- the hash length needed to disambiguate any branch in the codebase
  BranchHashLength :: Command m i v Int

  BranchHashesByPrefix :: ShortBranchHash -> Command m i v (Set Branch.Hash)

  ParseType :: Names -> LexedSource
            -> Command m i v (Either (Parser.Err v) (Type v Ann))

  LoadSource :: SourceName -> Command m i v LoadSourceResult

  Typecheck :: AmbientAbilities v
            -> Names
            -> SourceName
            -> LexedSource
            -> Command m i v (TypecheckingResult v)

  TypecheckFile :: UF.UnisonFile v Ann
                -> [Type v Ann]
                -> Command m i v (TypecheckingResult v)

  -- Evaluate all watched expressions in a UnisonFile and return
  -- their results, keyed by the name of the watch variable. The tuple returned
  -- has the form:
  --   (hash, (ann, sourceTerm, evaluatedTerm, isCacheHit))
  --
  -- where
  --   `hash` is the hash of the original watch expression definition
  --   `ann` gives the location of the watch expression
  --   `sourceTerm` is a closed term (no free vars) for the watch expression
  --   `evaluatedTerm` is the result of evaluating that `sourceTerm`
  --   `isCacheHit` is True if the result was computed by just looking up
  --   in a cache
  --
  -- It's expected that the user of this action might add the
  -- `(hash, evaluatedTerm)` mapping to a cache to make future evaluations
  -- of the same watches instantaneous.

  Evaluate :: PPE.PrettyPrintEnv
           -> UF.TypecheckedUnisonFile v Ann
           -> Command m i v (Either Runtime.Error (EvalResult v))

  -- Evaluate a single closed definition
  Evaluate1 :: PPE.PrettyPrintEnv -> UseCache -> Term v Ann -> Command m i v (Either Runtime.Error (Term v Ann))

  -- Add a cached watch to the codebase
  PutWatch :: UF.WatchKind -> Reference.Id -> Term v Ann -> Command m i v ()

  -- Loads any cached watches of the given kind
  LoadWatches :: UF.WatchKind -> Set Reference -> Command m i v [(Reference, Term v Ann)]

  -- Loads a root branch from some codebase, returning `Nothing` if not found.
  -- Any definitions in the head of the requested root that aren't in the local
  -- codebase are copied there.
  LoadLocalRootBranch :: Command m i v (Branch m)

  -- Like `LoadLocalRootBranch`.
  LoadLocalBranch :: Branch.Hash -> Command m i v (Branch m)

  -- Merge two branches, using the codebase for the LCA calculation where possible.
  Merge :: Branch.MergeMode -> Branch m -> Branch m -> Command m i v (Branch m)

  ViewRemoteBranch ::
    RemoteNamespace -> Command m i v (Either GitError (m (), Branch m))

  -- we want to import as little as possible, so we pass the SBH/path as part
  -- of the `RemoteNamespace`.  The Branch that's returned should be fully
  -- imported and not retain any resources from the remote codebase
  ImportRemoteBranch ::
    RemoteNamespace -> SyncMode -> Command m i v (Either GitError (Branch m))

  -- Syncs the Branch to some codebase and updates the head to the head of this causal.
  -- Any definitions in the head of the supplied branch that aren't in the target
  -- codebase are copied there.
  SyncLocalRootBranch :: Branch m -> Command m i v ()

  SyncRemoteRootBranch ::
    RemoteRepo -> Branch m -> SyncMode -> Command m i v (Either GitError ())

  AppendToReflog :: Text -> Branch m -> Branch m -> Command m i v ()

  -- load the reflog in file (chronological) order
  LoadReflog :: Command m i v [Reflog.Entry]

  LoadTerm :: Reference.Id -> Command m i v (Maybe (Term v Ann))

  -- todo: change this to take Reference and return DeclOrBuiltin
  LoadType :: Reference.Id -> Command m i v (Maybe (Decl v Ann))

  LoadTypeOfTerm :: Reference -> Command m i v (Maybe (Type v Ann))

  PutTerm :: Reference.Id -> Term v Ann -> Type v Ann -> Command m i v ()

  PutDecl :: Reference.Id -> Decl v Ann -> Command m i v ()

  -- todo: eliminate these hopefully
  -- (why, again? because we can know from the Reference?)
  IsTerm :: Reference -> Command m i v Bool
  IsType :: Reference -> Command m i v Bool

  -- Get the immediate (not transitive) dependents of the given reference
  -- This might include historical definitions not in any current path; these
  -- should be filtered by the caller of this command if that's not desired.
  GetDependents :: Reference -> Command m i v (Set Reference)

  GetTermsOfType :: Type v Ann -> Command m i v (Set Referent)
  GetTermsMentioningType :: Type v Ann -> Command m i v (Set Referent)

  -- Execute a UnisonFile for its IO effects
  -- todo: Execute should do some evaluation?
  Execute :: PPE.PrettyPrintEnv -> UF.TypecheckedUnisonFile v Ann -> Command m i v (Runtime.WatchResults v Ann)

  CreateAuthorInfo :: Text -> Command m i v (AuthorInfo v Ann)

  RuntimeMain :: Command m i v (Type v Ann)
  RuntimeTest :: Command m i v (Type v Ann)

type UseCache = Bool

type EvalResult v =
  ( [(v, Term v ())]
  , Map v (Ann, UF.WatchKind, Reference, Term v (), Term v (), Runtime.IsCacheHit)
  )

lookupEvalResult :: Ord v => v -> EvalResult v -> Maybe (Term v ())
lookupEvalResult v (_, m) = view _5 <$> Map.lookup v m

commandName :: Command m i v a -> String
commandName = \case
  Eval{}                      -> "Eval"
  ConfigLookup{}              -> "ConfigLookup"
  Input                       -> "Input"
  Notify{}                    -> "Notify"
  NotifyNumbered{}            -> "NotifyNumbered"
  AddDefsToCodebase{}         -> "AddDefsToCodebase"
  CodebaseHashLength          -> "CodebaseHashLength"
  TypeReferencesByShortHash{} -> "TypeReferencesByShortHash"
  TermReferencesByShortHash{} -> "TermReferencesByShortHash"
  TermReferentsByShortHash{}  -> "TermReferentsByShortHash"
  BranchHashLength            -> "BranchHashLength"
  BranchHashesByPrefix{}      -> "BranchHashesByPrefix"
  ParseType{}                 -> "ParseType"
  LoadSource{}                -> "LoadSource"
  Typecheck{}                 -> "Typecheck"
  TypecheckFile{}             -> "TypecheckFile"
  Evaluate{}                  -> "Evaluate"
  Evaluate1{}                 -> "Evaluate1"
  PutWatch{}                  -> "PutWatch"
  LoadWatches{}               -> "LoadWatches"
  LoadLocalRootBranch         -> "LoadLocalRootBranch"
  LoadLocalBranch{}           -> "LoadLocalBranch"
  Merge{}                     -> "Merge"
  ViewRemoteBranch{}          -> "ViewRemoteBranch"
  ImportRemoteBranch{}        -> "ImportRemoteBranch"
  SyncLocalRootBranch{}       -> "SyncLocalRootBranch"
  SyncRemoteRootBranch{}      -> "SyncRemoteRootBranch"
  AppendToReflog{}            -> "AppendToReflog"
  LoadReflog                  -> "LoadReflog"
  LoadTerm{}                  -> "LoadTerm"
  LoadType{}                  -> "LoadType"
  LoadTypeOfTerm{}            -> "LoadTypeOfTerm"
  PutTerm{}                   -> "PutTerm"
  PutDecl{}                   -> "PutDecl"
  IsTerm{}                    -> "IsTerm"
  IsType{}                    -> "IsType"
  GetDependents{}             -> "GetDependents"
  GetTermsOfType{}            -> "GetTermsOfType"
  GetTermsMentioningType{}    -> "GetTermsMentioningType"
  Execute{}                   -> "Execute"
  CreateAuthorInfo{}          -> "CreateAuthorInfo"
  RuntimeMain                 -> "RuntimeMain"
  RuntimeTest                 -> "RuntimeTest"
  HQNameQuery{}               -> "HQNameQuery"
  LoadSearchResults{}         -> "LoadSearchResults"
  GetDefinitionsBySuffixes{}  -> "GetDefinitionsBySuffixes"
  FindShallow{}               -> "FindShallow"
