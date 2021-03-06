module Utils.Users where

import Import
import Utils.Database

import qualified Hasql as H
import qualified Network.Wai as W (Request,requestHeaders)
import qualified Data.Text.Encoding as E (decodeUtf8)

getUser :: W.Request -> Maybe Text
getUser r = let headers = W.requestHeaders r
            in E.decodeUtf8 `fmap` lookup "X-WEBAUTH-USER" headers

isAdmin :: W.Request -> IO Bool
isAdmin req = do
    let username = getUser req
    conn <- getDbConn
    dbres <- H.session conn $ H.tx Nothing $
            H.maybeEx $ [H.stmt|
                    SELECT admin
                    FROM people
                    WHERE people.csh_username = ?
                |] username
    case dbres of
        Right (Just (Identity True)) -> return True
        _ -> return False

restrictToAdmins :: W.Request -> Handler ()
restrictToAdmins req = do
    admin <- liftIO $ isAdmin req
    case admin of
        True -> return ()
        False -> permissionDenied "Only an admin can see that page"
