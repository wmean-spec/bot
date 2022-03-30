module Bot.VK.API where

import Bot.Base.API (API (replyMessage, sendAPIMethod), APIException (APIException), HasAPI (getAPI), HasManager (getManager), IsAPI, newRequestWithMethod)
import Bot.Base.Log (HasLog, LogLevel (Info), logMessage)
import qualified Bot.Base.Types as BaseT
import Bot.VK.Parse (parseResponse)
import qualified Bot.VK.Types as T
import Control.Monad.Catch (throwM)
import Control.Monad.Reader (ask, when)
import Data.Maybe (isNothing)
import Network.HTTP.Base (urlEncodeVars)
import Network.HTTP.Client (Manager, parseRequest)
import Text.Printf (printf)

api :: String -> String -> Manager -> VKAPI
api token version = VKAPI token version

data VKAPI = VKAPI
  { apiToken :: String,
    apiVersion :: String,
    apiManager :: Manager
  }

getMyID :: (IsAPI env api m, API api, HasLog (env api)) => m Integer
getMyID = do
  res <- sendAPIMethod "groups.getById" []
  let response = parseResponse res
  when (isNothing response) (throwM APIException)
  let Just groups = response
  return $ T.gID . head $ groups

instance HasManager VKAPI where
  getManager = apiManager

instance API VKAPI where
  newRequestWithMethod method params = do
    env <- ask
    let VKAPI {apiToken = token, apiVersion = version} = getAPI env
    let addParams = params ++ [("access_token", token), ("v", version)]
        url = printf "https://api.vk.com/method/%s?%s" method (urlEncodeVars addParams)
    parseRequest url

  replyMessage update msg = do
    let peerID = BaseT.uSender update
    logMessage Info $ "VK: Reply for " ++ show peerID
    sendAPIMethod "messages.send" [("user_id", show peerID), ("message", msg), ("random_id", "0")]
