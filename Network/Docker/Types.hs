{-# LANGUAGE DeriveFunctor     #-}
{-# LANGUAGE FlexibleContexts  #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TemplateHaskell   #-}

module Network.Docker.Types where

import           Control.Applicative
import           Control.Lens.TH
import           Data.Aeson
import           Data.Aeson.TH
import           Data.Bool
import qualified Data.ByteString.Lazy   as BS
import           Data.Default
import qualified Data.Map               as Map
import qualified Data.Text              as T
import           GHC.Generics
import           Network.Docker.Options
import           Network.Wreq.Types     (Postable)
import           OpenSSL.Session        (SSLContext)
import           Prelude                hiding (id)

type URL = String
type ApiVersion = String
type Endpoint = String

type Tag = String
type IP = String
type Port = Int
type PortType = String

data SSL = NoSSL | SSL SSLOptions deriving Show

data DockerClientOpts = DockerClientOpts {
      apiVersion :: ApiVersion -- ^ It appears that the latest supported version is 1.17. Ex: `"v1.12"`
    , baseUrl    :: URL -- ^ Ex: `"http://127.0.0.1:3128/"`
    , ssl        :: SSL
    } deriving (Show)


data SSLOptions = SSLOptions {
    optionsKey  :: FilePath
  , optionsCert :: FilePath
  } deriving Show


data ResourceId = ResourceId { _id :: String } deriving (Show, Eq)


data DockerImage = DockerImage
                { _imageId        :: ResourceId
                , _imageCreatedAt :: Int
                , _parentId       :: Maybe String
                , _repoTags       :: [Tag]
                , _size           :: Int
                , _virtualSize    :: Int
                } deriving (Show, Eq)


data DockerVersion = DockerVersion
                  { _Version       :: String
                  , _GitCommit     :: String
                  , _GoVersion     :: String
                  , _Arch          :: String
                  , _KernelVersion :: String
                  } deriving (Show, Eq)


-- The JSON looks likes this:
-- "Ports":[{"IP":"0.0.0.0","PrivatePort":55555,"PublicPort":55555,"Type":"tcp"}]

data PortMap = PortMap
            { _ip          :: IP
            , _privatePort :: Port
            , _publicPort  :: Port
            , _type        :: PortType
            } deriving (Show, Eq)

data DeleteOpts = DeleteOpts
            { removeVolumes :: Bool
            , force         :: Bool
            }

defaultDeleteOpts = DeleteOpts False False


data DockerContainer = DockerContainer
                    { _containerId        :: ResourceId
                    , _containerImageId   :: ResourceId
                    , _command            :: String
                    , _containerCreatedAt :: Int
                    , _names              :: [String]
                    , _status             :: String
                    , _ports              :: Maybe [PortMap]
                    } deriving (Show, Eq)


data CreateContainerOpts = CreateContainerOpts
                  { _hostname       :: String
                  , _user           :: String
                  , _memory         :: Int
                  , _memorySwap     :: Int
                  , _cpuShares      :: Int
                  , _attachStdin    :: Bool
                  , _attachStdout   :: Bool
                  , _attachStderr   :: Bool
                  , _portSpecs      :: Maybe Object
                  , _tty            :: Bool
                  , _openStdin      :: Bool
                  , _stdinOnce      :: Bool
                  , _env            :: Maybe Object
                  , _cmd            :: [String]
                  , _image          :: String
                  , _volumes        :: Maybe Object
                  , _volumesFrom    :: Maybe Object
                  , _workingDir     :: String
                  , _disableNetwork :: Bool
                  , _exposedPorts   :: Maybe Object
                  } deriving (Show)

defaultCreateOpts = CreateContainerOpts {
                             _hostname = ""
                            , _user = ""
                            , _memory = 0
                            , _memorySwap =  0
                            , _cpuShares = 0
                            , _attachStdin = False
                            , _attachStdout = False
                            , _attachStderr = False
                            , _portSpecs = Nothing
                            , _tty = False
                            , _openStdin =  False
                            , _stdinOnce = False
                            , _env = Nothing
                            , _cmd = []
                            , _image = "debian"
                            , _volumes = Nothing
                            , _volumesFrom =  Nothing
                            , _workingDir = ""
                            , _disableNetwork = False
                            , _exposedPorts = Nothing
                            }

instance ToJSON CreateContainerOpts where
        toJSON (CreateContainerOpts {..}) = object
            [ "Hostname" .= _hostname
            , "User" .= _user
            , "Memory" .= _memory
            , "MemorySwap" .= _memorySwap
            , "CpuShares" .= _cpuShares
            , "AttachStdin" .= _attachStdin
            , "AttachStdout" .= _attachStdout
            , "AttachStderr" .= _attachStderr
            , "PortSpecs" .= _portSpecs
            , "Tty" .= _tty
            , "OpenStdin" .= _openStdin
            , "StdinOnce" .= _stdinOnce
            , "Env" .= _env
            , "Cmd" .= _cmd
            , "Image" .= _image
            , "Volumes" .= _volumes
            , "VolumesFrom" .= _volumesFrom
            , "WorkingDir" .= _workingDir
            , "DisableNetwork" .= _disableNetwork
            , "ExposedPorts" .= _exposedPorts
            ]

-- data CreateContainerResponse = CreateContainerResponse
--                               { _createdContainerId :: String
--                               , _warnings           :: Maybe [T.Text]
--                               } deriving (Show)

data StartContainerOpts = StartContainerOpts
                        { _Binds           :: [T.Text]
                        , _Links           :: [T.Text]
                        , _LxcConf         :: [(T.Text, T.Text)]
                        , _PortBindings    :: [((Int,T.Text),Int)]
                        , _PublishAllPorts :: Bool
                        , _Privileged      :: Bool
                        , _Dns             :: [T.Text]
                        , _VolumesFrom     :: [T.Text]
                        , _RestartPolicy   :: RestartPolicy
                        } deriving (Show)

defaultStartOpts = StartContainerOpts
                { _Binds = []
                , _Links = []
                , _LxcConf = []
                , _PortBindings = []
                , _PublishAllPorts = False
                , _Privileged = False
                , _Dns = []
                , _VolumesFrom = []
                , _RestartPolicy = RestartNever
                }

instance ToJSON StartContainerOpts where
        toJSON (StartContainerOpts {..}) = object
            [ "Binds" .= _Binds
            , "Links" .= _Links
            , "LxcConf" .= _LxcConf
            , "PortBindings" .= object (map (\((h,p),c)->T.concat [T.pack (show h),"/",p] .= [object ["HostPort" .= show c]]) _PortBindings)
            , "PublishAllPorts" .= _PublishAllPorts
            , "Privileged" .= _Privileged
            , "Dns" .= _Dns
            , "VolumesFrom" .= _VolumesFrom
            , "RestartPolicy" .= _RestartPolicy
            ]

data RestartPolicy = RestartNever
                   | RestartAlways
                   | RestartOnFailure Int
                   deriving (Show)

instance ToJSON RestartPolicy where
  toJSON RestartNever = object ["Name" .= (""::String), "MaximumRetryCount" .= (0::Int) ]
  toJSON RestartAlways = object ["Name" .= ("always"::String), "MaximumRetryCount" .= (0::Int) ]
  toJSON (RestartOnFailure n) = object ["Name" .= ("on-failure"::String), "MaximumRetryCount" .= n ]

makeClassy ''ResourceId

-- makeLenses ''CreateContainerResponse
makeLenses ''DockerImage
makeLenses ''DockerContainer
makeLenses ''CreateContainerOpts

instance HasResourceId DockerImage where
        resourceId = imageId

instance FromJSON DockerImage where
        parseJSON (Object v) =
            DockerImage <$> ResourceId <$> (v .: "Id")
                <*> (v .: "Created")
                <*> (v .:? "ParentId")
                <*> (v .: "RepoTags")
                <*> (v .: "Size")
                <*> (v .: "VirtualSize")

instance FromJSON PortMap where
        parseJSON (Object v) =
            PortMap <$> (v .: "IP")
                <*> (v .: "PrivatePort")
                <*> (v .: "PublicPort")
                <*> (v .: "Type")

instance HasResourceId DockerContainer where
        resourceId = containerId

instance FromJSON DockerContainer where
        parseJSON (Object v) =
            DockerContainer <$> (ResourceId <$> (v .: "Id"))
                <*> (ResourceId <$> (v .: "Id"))
                <*> (v .: "Command")
                <*> (v .: "Created")
                <*> (v .: "Names")
                <*> (v .: "Status")
                <*> (v .:? "Ports")

-- instance FromJSON CreateContainerResponse where
--         parseJSON (Object v) =
--             CreateContainerResponse <$> (v .: "Id")
--                 <*> (v .:? "warnings")

$(deriveJSON dopts ''DockerVersion)

-- Based on v1.17 of Docker API.
-- https://docs.docker.com/engine/reference/api/docker_remote_api_v1.17/#create-a-container
data ContainerInformation = ContainerInformation {
      containerInformationNetworkSettings :: ContainerNetworkSettings
    -- TODO: There are a bunch more. XXX
    }

instance FromJSON ContainerInformation where
    parseJSON (Object o) = do
        networkSettings <- o .: "NetworkSettings"
        return $ ContainerInformation networkSettings
    
data ContainerNetworkSettings = ContainerNetworkSettings {
      containerNetworkSettingsBridge :: T.Text
    , containerNetworkSettingsGateway :: T.Text
    , containerNetworkSettingsIPAddress :: T.Text
    , containerNetworkSettingsIPPrefixLen :: Int
    , containerNetworkSettingsMacAddress :: T.Text
    -- , containerNetworkSettingsPortMapping :: Not sure about this type. API is ambiguous
    , containerNetworkSettingsPorts :: Maybe [Int] -- API is also ambigous here.
    }

instance FromJSON ContainerNetworkSettings where
    parseJSON (Object o) = do
        bridge <- o .: "Bridge"
        gateway <- o .: "Gateway"
        ipAddress <- o .: "IPAddress"
        ipPrefixLen <- o .: "IPPrefixLen"
        macAddress <- o .: "MacAddress"
        ports <- o .: "SettingsPorts"
        return $ ContainerNetworkSettings bridge gateway ipAddress ipPrefixLen macAddress ports

