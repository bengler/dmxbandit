express = require 'express'
stylus = require 'stylus'
assets = require 'connect-assets'
fs = require 'fs'
glob = require 'glob'
path = require 'path'

app = express()
# Add Connect Assets
app.use assets()
# Other assets
app.use('/img', express.static(__dirname + '/../assets/img'))
# Sound assets
app.use('/sound', express.static(__dirname + '/../assets/sound'))
# Set View Engine
app.set 'view engine', 'jade'
# Get root_path return index view
app.get '/', (req, resp) ->
  resp.render 'app'
# Get root_path return index view
app.get '/editor', (req, resp) ->
  resp.render 'editor'
app.get '/public/levels', (req, resp) ->
  resp.set('Content-Type', 'application/json');
  meta = JSON.parse(fs.readFileSync("./levels/meta.json"))
  glob "./levels/*.txt", {}, (err, files) ->
    levels = {}
    for file in files
      levels[path.basename(file)] = fs.readFileSync(file, 'utf-8')
    resp.send(200, JSON.stringify({meta, levels}))
# Define Port
port = process.env.PORT or process.env.VMC_APP_PORT or 3000
# Start Server
app.listen port, -> console.log "Listening on #{port}\nPress CTRL-C to stop server."