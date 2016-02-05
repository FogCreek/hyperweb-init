# sets up express and file support
# feel free to ignore this and jump to server.js

fs = require "fs"
less = require "less"
path = require "path"
url = require "url"
randomEmoji = require 'random-emoji'

module.exports =
  init: ->
    Express = require "express"
    app = Express()

    app.use (req, res, next) ->
      return next() if 'GET' != req.method.toUpperCase() && 'HEAD' != req.method.toUpperCase()

      pathname = url.parse(req.url).pathname

      return next() unless pathname.match /\.css$/
      lessPath = path.join "public", pathname.replace('.css', '.less')

    # CSS preprocessors
      # todo: deprecate LESS specific rendering in favor of something more flexible
      fs.readFile lessPath, 'utf8', (err, lessSrc) ->
        if err
          # Ignore ENOENT to fall through as 404.
          if 'ENOENT' == err.code
            next()
          else
            next(err)
        else
          renderOptions =
            filename: lessPath
            paths: []

          less.render lessSrc, renderOptions, (err, output) ->
            if err
              next(err)
            else
              res.set('Content-Type', 'text/css')
              res.send output.css

    stylus = require('stylus')
    app.use(stylus.middleware('public'))

    # JS preprocessors
    coffeeMiddleware = require('coffee-middleware')
    app.use coffeeMiddleware
      bare: true
      src: "public"
    require('coffee-script/register')

    # Static folder
    app.use(Express.static('public'))

    bodyParser = require('body-parser')
    app.use bodyParser.urlencoded
      extended: false
    app.use bodyParser.json()
    app.use bodyParser.text()

    # template engines
    engines = require('consolidate')
    app.engine('jade', engines.jade)
    app.engine('html', engines.nunjucks)
    app.engine('hbs', engines.handlebars)

    nunjucks = require 'nunjucks'
    nunjucks.configure 'views', { autoescape: true }

    # CSON support
    require 'fs-cson/register'

    # HW projects run on port 3000
    app.set 'port', process.env.PORT or 3000

    # Display success message
    randomEmoji = randomEmoji.random {count: 2}
    emojis = ""
    for emoji in randomEmoji
      emojis += emoji.character

    app.server = app.listen app.get('port'), ->
      console.log("#{emojis} app started")

    return app