{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE TypeApplications #-}

module Main where

import Hakyll

import Hakyll.Images (loadImage, Image)

import Data.String (fromString)
import System.FilePath
    (takeFileName, dropExtension, replaceExtension)

config :: Configuration
config = defaultConfiguration 
            { destinationDirectory = "docs"
            , providerDirectory    = "provider"
            }

main :: IO ()
main = hakyllWith config do
    match "index.html" do
        route idRoute
        compile $
            let ctx = constField "title" "Home" <> defaultContext
            in getResourceBody
                >>= loadAndApplyTemplate "templates/default.html" ctx
                >>= relativizeUrls

    create ["posts.html"] do
        route idRoute
        compile do
            posts <- recentFirst =<< loadAll ("posts/*" .&&. hasNoVersion)

            let archiveCtx = listField "posts" defaultContext (pure posts)
                            <> constField "title" "Posts"
                            <> defaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/post-list.html" archiveCtx
                >>= loadAndApplyTemplate "templates/default.html" archiveCtx
                >>= relativizeUrls

    create ["pictures.html"] do
        route idRoute
        compile do
            pictures <- recentFirst =<< loadAll ("posts/*" .&&. hasVersion "pictures")

            let picturesCtx = listField "posts" defaultContext (pure pictures)
                            <> constField "title" "Pictures"
                            <> defaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/post-list.html" picturesCtx
                >>= loadAndApplyTemplate "templates/default.html" picturesCtx
                >>= relativizeUrls

    match "contact.md" do
        route $ setExtension "html"
        compile $
            pandocCompiler
                >>= loadAndApplyTemplate "templates/default.html" (constField "title" "Contact me" <> defaultContext)
                >>= relativizeUrls

    match "posts/*.md" do
        route $ setExtension "html"
        compile do
            name <- dropExtension . takeFileName <$> getResourceFilePath
            let postsCtx = boolField "other" (const True)
                        <> constField "other-post" "Pictures"
                        <> constField "other-url" ("/pictures/" <> name <> ".html")
                        <> defaultContext

            pandocCompiler
                >>= loadAndApplyTemplate "templates/default.html" postsCtx
                >>= relativizeUrls

    match "posts/*.md" $ version "pictures" do
        route $ customRoute (("pictures/" <>) . flip replaceExtension "html" . takeFileName .  toFilePath)
        compile do
            name <- dropExtension . takeFileName <$> getResourceFilePath
            pics <- fmap itemIdentifier
                    <$> loadAll @Image
                            (fromString $ "images/" ++ name ++ "/*")

            let picsCtx = listField "pics" (field "src" (pure . itemBody))
                            (traverse (makeItem . ('/':) . toFilePath) pics)
                        <> boolField "other" (const True)
                        <> constField "other-post" "Post"
                        <> constField "other-url" ("/posts/" <> name <> ".html")
                        <> defaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/pictures.html" picsCtx
                >>= loadAndApplyTemplate "templates/default.html" picsCtx
                >>= relativizeUrls

    match "images/**/*" do
        route idRoute
        compile loadImage

    match "styles.css" do
        route idRoute
        compile compressCssCompiler

    match "templates/*" $
        compile templateBodyCompiler
