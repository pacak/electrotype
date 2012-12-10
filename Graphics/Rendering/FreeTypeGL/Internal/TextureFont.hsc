{-# LANGUAGE ForeignFunctionInterface, EmptyDataDecls #-}
module Graphics.Rendering.FreeTypeGL.Internal.TextureFont
  (TextureFont, new, Vector2(..), getSize
  ) where

import Data.Tensor (Vector2(..))
import Foreign (Ptr, FunPtr)
import Foreign.C.String (CWString, withCWStringLen, CString, withCString)
import Foreign.C.Types (CFloat(..), CSize(..))
import Foreign.ForeignPtr (ForeignPtr, newForeignPtr, withForeignPtr)
import Foreign.Marshal.Array (allocaArray, peekArray)
import Graphics.Rendering.FreeTypeGL.Internal.Atlas (Atlas)

data TextureFont

foreign import ccall "texture_font_new"
  c_texture_font_new :: Ptr Atlas -> CString -> CFloat -> IO (Ptr TextureFont)

foreign import ccall "&texture_font_delete"
  c_texture_font_delete :: FunPtr (Ptr TextureFont -> IO ())

foreign import ccall "texture_font_get_size"
  c_texture_font_get_size :: Ptr TextureFont -> CWString -> CSize -> Ptr Float -> IO ()

foreign import ccall "strdup"
  c_strdup :: CString -> IO CString

new :: ForeignPtr Atlas -> FilePath -> Float -> IO (ForeignPtr TextureFont)
new atlas filename size =
  withForeignPtr atlas $ \atlasPtr ->
  withCString filename $ \filenamePtr -> do
    newFilenamePtr <- c_strdup filenamePtr
    newForeignPtr c_texture_font_delete =<<
      c_texture_font_new atlasPtr newFilenamePtr (realToFrac size)

getSize :: ForeignPtr TextureFont -> String -> IO (Vector2 Float)
getSize textureFont str =
  withCWStringLen str $ \(strPtr, len) ->
  withForeignPtr textureFont $ \fontPtr ->
  allocaArray 2 $ \sizePtr -> do
    c_texture_font_get_size fontPtr strPtr (fromIntegral len) sizePtr
    [width, height] <- peekArray 2 sizePtr
    return $ Vector2 width height
