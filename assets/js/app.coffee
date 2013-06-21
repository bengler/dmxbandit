

t=0


class BlankGenerator
  light: (x,y) ->
    "#fff"
  advance: ->

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


class Scroller extends CanvasSampler
  constructor: ->
    super()
    @text = "WOWOWOWO OIOIOIOIOIO O-O_O^O"
    @x = 0
    @ctx.font = '10px sans-serif'
    @ctx.webkitImageSmoothingEnabled = false;
  advance: ->
    @x = 0 if @x < -200
    @x -= 0.2
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

generateDMX = (generator, width, height, start_channel) ->
  packet = []
  for i in [0...start_channel]
    packet.push(0)
  for x in [0...width]
    for y in [0...height]
      packet.concat(generator.sample(x,y))
  packet

class Lamps
  constructor: (canvas, @width, @height, @generator) ->
    @ctx = canvas.getContext('2d')
    @x = 20
    @y = 20
    @radius = 20
  render: ->
    for x in [0...@width]
      for y in [0...@height]
        [r, g, b] = @generator.sample(x, y)
        @ctx.fillStyle = "##{r.toString(16)}#{g.toString(16)}#{b.toString(16)}"
        @ctx.fillRect(@x+x*@radius*1.2, @y+y*@radius*1.2, @radius, @radius)
        @ctx.beginPath()
        @ctx.arc(@x+x*@radius*1.2, @y+y*@radius*1.2, 0, 2*Math.PI)
        @ctx.fill()

generator = null
lamps = null

init = ->
  scroller = new Scroller()
  sinus = new Sinusoidal()
  generator = new Mixer([scroller, sinus])
  lamps = new Lamps($('canvas')[0], 9, 9, generator)

animate = ->
  requestAnimationFrame( animate )
  generator.advance()
  lamps.render()


init()
animate()
