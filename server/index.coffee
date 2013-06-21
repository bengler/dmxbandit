express = require 'express'
stylus = require 'stylus'
assets = require 'connect-assets'
fs = require 'fs'
glob = require 'glob'
path = require 'path'
artnet = require 'artnet-node'

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


class Sinusoidal
  constructor: ->
    @t = 0
  sample: (x,y) ->
    cx = Math.sin(@t/30)*5
    cy = Math.cos(@t/22)*9
    r = @sampleSin(cx, cy, 3, x, y)
    cx = Math.sin(@t/90.2)*5.1
    cy = Math.cos(@t/21.8)*8.5
    g = @sampleSin(cx, cy, 3.1, x, y)
    cx = Math.sin(@t/(Math.sin(@t/20)*20))*5.9
    cy = Math.cos(@t/22.1)*9.1
    b = @sampleSin(cx, cy, 5, x, y)
    [r, g, b]
  sampleSin: (cx, cy, freq, sx, sy) ->
    d = Math.sqrt(Math.pow(sx-cx, 2)+Math.pow(sy-cy,2))
    r = Math.floor((Math.sin(d/(Math.PI*2)*freq)+1)*128)
    return 255 if r > 255
    r
  advance: ->
    @t += 0.4

generateDMX = (generator, width, height, start_channel) ->
  packet = []
  for i in [0...start_channel]
    packet.push(0)
  for x in [0...width]
    for y in [0...height]
      packet = packet.concat(generator.sample(x,y))
  packet

generator = new Sinusoidal()

client = artnet.Client.createClient('10.0.0.8', 6454);

send = ->
  client.send(generateDMX(generator, 1, 12, 109))
  generator.advance()

setInterval(send, 20)


#app.get '/blast', (req, resp) ->


# resp.send "Done"
# process.exit()

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