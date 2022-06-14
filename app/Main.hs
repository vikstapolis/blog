{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE BlockArguments #-}

module Main where

import Hakyll.Main (hakyllWith)

import Hakyll.Core.Rules (match, route, compile, create)
import Hakyll.Core.Routes (idRoute, setExtension)
import Hakyll.Core.Compiler (makeItem, getResourceBody, loadAll)

import Hakyll.Web.Template (loadAndApplyTemplate, templateBodyCompiler)
import Hakyll.Web.Template.Context (defaultContext, listField, constField)
import Hakyll.Web.Template.List (recentFirst)

import Hakyll.Web.Html.RelativizeUrls (relativizeUrls)

import Hakyll.Web.CompressCss (compressCssCompiler)
import Hakyll.Web.Pandoc (pandocCompiler)

import Hakyll.Core.Configuration
    (Configuration(destinationDirectory), defaultConfiguration)

import Hakyll.Images (loadImage)

config :: Configuration
config = defaultConfiguration { destinationDirectory = "docs"}

main :: IO ()
main = hakyllWith config do
    match "index.html" do 
        route idRoute
        compile $
            let ctx = constField "title" "Home" <> defaultContext
            in getResourceBody
                >>= loadAndApplyTemplate "templates/default.html" ctx
                >>= relativizeUrls

    create ["archive.html"] do
        route idRoute
        compile do
            posts <- recentFirst =<< loadAll "posts/*"

            let archiveCtx = listField "posts" defaultContext (pure posts)
                            <> constField "title" "Archives"
                            <> defaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
                >>= loadAndApplyTemplate "templates/default.html" archiveCtx
                >>= relativizeUrls

    match "contact.md" do
        route $ setExtension "html"
        compile $
            pandocCompiler
                >>= loadAndApplyTemplate "templates/default.html" (constField "title" "Contact me" <> defaultContext)

    match "posts/*.md" do
        route $ setExtension "html"
        compile $
            pandocCompiler
                >>= loadAndApplyTemplate "templates/default.html" defaultContext 
                >>= relativizeUrls

    match "images/*.png" do
        route idRoute
        compile loadImage

    match "styles.css" do
        route idRoute
        compile compressCssCompiler

    match "templates/*" $
        compile templateBodyCompiler
