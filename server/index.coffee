Canvas = require('canvas')
artnet = require 'artnet-node'
fs = require 'fs'

readImage = (file, callback) ->
  data = fs.readFileSync __dirname + '/' + file
  img = new Canvas.Image()
  img.src = data;
  img



#  ctx.drawImage(img, 0, 0, img.width / 4, img.height / 4);



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
    cx = Math.sin(@t/50)*5.9
    cy = Math.cos(@t/22.1)*9.1
    b = @sampleSin(cx, cy, 5, x, y)
    [r, g, b]
  sampleSin: (cx, cy, freq, sx, sy) ->
    d = Math.sqrt(Math.pow(sx-cx, 2)+Math.pow(sy-cy,2))
    r = Math.floor((Math.sin(d/(Math.PI*2)*freq)+1)*128)*0.2
    return 255 if r > 255
    r
  advance: ->
    @t += 0.4

class CanvasSampler
  constructor: ->
    if window?
      @canvas = $("<canvas width='256' height='256'/>")[0]
    else
      @canvas = new Canvas(64,64)
    @ctx = @canvas.getContext('2d')
  sample: (x, y) ->
    index = (x+y*@imageData.width)*4
    [@imageData.data[index], @imageData.data[index+1], @imageData.data[index+2]]
  advance: ->
    @imageData = @ctx.getImageData(0,0,64,64)
    @ctx.fillStyle = '#000'
    @ctx.fillRect(0,0,64,64)

class Epillepsy extends CanvasSampler
  advance: ->
    @t = !@t
    if @t
      @ctx.fillStyle="#888"
    else
      @ctx.fillStyle="#111"
    @ctx.fillRect(0,0,64,64)
    super()



class LineScape extends CanvasSampler
  constructor: ->
    super()
    @t = 0
  yFor: (i, x) ->
    scaler = (i / 5)*Math.cos(@t/i/32)
    wider = (Math.cos((@t+i*20)/25)+1)*12
    (Math.sin(@t+(x*scaler))+1)*wider
  advance: ->
    for i in [0..10]
      @ctx.lineWidth = 1
      a = Math.floor(i/10*255)
      @ctx.strokeStyle = "rgba(#{a}, #{a}, #{a}, 0.1)"
      @ctx.beginPath()
      @ctx.moveTo(0,@yFor(i, 0))
      for x in [1..4]
        @ctx.lineTo(x*4, @yFor(i,x))
      @ctx.stroke()
    @t += 0.05
    super()

class Mario extends CanvasSampler
  constructor: ->
    super()
    @sheet = readImage('../assets/img/supermario_anim.png')
    @frame = 0
    @t = 0
  nextFrame: ->
    @frame += 1
    if @frame > 13
      @frame = 0
  advance: ->
    @ctx.drawImage(@sheet, -@frame * 12, 0, @sheet.width, @sheet.height)
    @t += 1
    if @t % 20 == 0
      @nextFrame()
    super()

# class Raaah extends CanvasSampler
#   cons


class ImageExplorer extends CanvasSampler
  constructor: (@image) ->
    super()
    @t = 0
  advance: ->
    @t += 0.1
    cx = (Math.sin(@t/100)+1)*@image.width/2
    #cy = (Math.sin(@t/130)+1)*@image.height/2
    @ctx.drawImage(@image, -@t, 0, @image.width, 12);

    super()

class Scroller extends CanvasSampler
  constructor: ->
    super()
    @text = "WOWOWOWO OIOIOIOIOIO O-O_O^O"
    @x = 0
    @ctx.font = '10px sans-serif'
    @ctx.webkitImageSmoothingEnabled = false;
  advance: ->
    @x = 0 if @x < -200
    @x -= 0.5
    @ctx.fillStyle = '#000'
    @ctx.fillRect(0,0,64,64)
    @ctx.fillStyle = '#fff'
    @ctx.fillText(@text, @x, 8)
    super()

class Mixer
  constructor: (@generators) ->
  sample: (x, y) ->
    o_r = 0
    o_g = 0
    o_b = 0
    for g in @generators
      [r, g, b] = g.sample(x,y)
      o_r += r
      o_g += g
      o_b += b
    if o_r > 255
      o_r = 255
    if o_g > 255
      o_g = 255
    if o_b > 255
      o_b = 255
    [o_r, o_g, o_b]
  advance: ->
    for g in @generators
      g.advance()

class Dimmer
  constructor: (@generator) ->
    @level = 0.1
  sample: (x, y) ->
    [r,g,b] = @generator.sample(x,y)
    [Math.floor(r*@level), Math.floor(g*@level), Math.floor(b*@level)]
  advance: ->
    @generator.advance()


generateDMX = (generator, width, height, start_channel) ->
  packet = []
  for i in [0...start_channel]
    packet.push(0)
  for x in [0...width]
    for y in [0...height]
      packet = packet.concat(generator.sample(x,y))
  packet

scroller = new Scroller()
sinus = new Sinusoidal()
mixer = new Mixer([scroller, sinus])


zelda_sheet = readImage('../assets/img/supermario_test.png')
console.log zelda_sheet
imagexporer = new ImageExplorer(zelda_sheet)
linescape = new LineScape()
mario = new Mario()
epill = new Epillepsy()
generator = new Dimmer(new Mixer([mario]))
generator.level = 0.1

client = artnet.Client.createClient('192.168.0.240', 6454);

scroller.advance()



send = ->
  generator.advance()
  client.send(generateDMX(generator, 12, 12, 0))

timer = setInterval(send, 20)

process.on "SIGINT", ->
  clearInterval(timer)
  console.log "Exiting"
  b = []
  for i in [0...512]
    b.push(0)
  client.send(b)
  kill = ->
    process.exit()
  setTimeout(kill, 250)
