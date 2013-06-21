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
    @animations =
      walking: [0, 5, 3]
      flying: [9, 10, 11, 12, 13]
      thump: [7, 8, -1]
      standing: [1]
    @setAnimation('walking')
  setAnimation: (animation) ->
    @frame = 0
    @animation = animation
  switch: ->
    console.log 'switching'
    switch @animation
      when 'walking'
        @setAnimation('flying')
      when 'flying'
        @setAnimation('thump')
      when 'thump'
        @setAnimation('standing')
      when 'standing'
        @setAnimation('walking')
  nextFrame: ->
    if Math.random() < 0.1
      @switch()
    else
      if @animations[@animation][@frame+1] != -1
        @frame += 1
        if @frame >= @animations[@animation].length
          @frame = 0
      else
        @switch()
    console.log @animation, @animations[@animation][@frame]
  advance: ->
    @ctx.drawImage(@sheet, -@animations[@animation][@frame] * 12, 0, @sheet.width, @sheet.height)
    @t += 1
    if @t % 20 == 0
      @nextFrame()
    super()


class Raaah extends CanvasSampler
  constructor: ->
    super()
    @t = 0
    @lines = []
    for i in [0..20]
      @addLine
  addLine: ->
    @lines.push
      x: 12+Math.random()*12
      y: Math.random()*12
      dx: -Math.pow(Math.random(),4)
      l: Math.random()*10
  advance: ->
    for l in @lines
      l.x += l.dx
      @ctx.strokeStyle = "rgba(255, 255, 255, 0.5)"
      @ctx.beginPath()
      @ctx.moveTo(l.x, l.y)
      @ctx.lineTo(l.x+l.l, l.y)
      @ctx.stroke()
    if Math.random() < 0.01
      @lines.unshift()
    if Math.random() < 0.4
      @addLine()
    super()

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


class Ball
  constructor: (posX, posY) ->
    @x = posX
    @y = posY
    @size = Math.floor(Math.random() * 4)
    @t = Math.floor(Math.random() * 20) + 30

  advance: ->
    @t += 1

  remove: ->
    if @t > 20
      return true
    else
      return false

class JustBalls extends CanvasSampler
  constructor: ->
    super()
    @ctx.webkitImageSmoothingEnabled = true;
    @ctx.antialias = 'grey'
    @t = 0
    @width = 12
    @balls = []

  advance: ->

    @ctx.fillStyle = '#000'
    @ctx.fillRect(0,0,64,64)

    if Math.random() < 0.3
      @balls.push (new Ball(Math.random() * @width, Math.random() * @width))
      console.info @balls
      console.info "SNARK"

    @ctx.fillStyle = '#fff'

    for ball in @balls
      ball.advance()
      console.info ball.x
      @ctx.fillRect(ball.x, ball.y, ball.x + ball.size, ball.y + ball.size)

    @newBalls = []
    for ball in @balls
      @newBalls < ball if !ball.remove()
    @balls = @newBalls

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


class Sequencer
  constructor: (@generators) ->
    @current = Math.floor(Math.random()*@generators.length)
    @next = Math.floor(Math.random()*@generators.length)
    @t = 0
    @elapsed = 0
    @transitionAfter = Math.random()*1000
  sample: (x, y) ->
    [r1, g1, b1] = @generators[@current].sample(x,y)
    [r2, g2, b2] = @generators[@next].sample(x,y)
    [
      Math.floor((r1*(1-@t)+r2*(@t))/2),
      Math.floor((g1*(1-@t)+g2*(@t))/2),
      Math.floor((b1*(1-@t)+b2*(@t))/2)
    ]
  advance: ->
    console.log @current, @next, @elapsed, @transitionAfter
    @elapsed += 1
    if @elapsed > @transitionAfter
      console.log "transitioning #{@t}", @current, @next
      @t += 0.005
      if @t >= 1.0
        @current = @next
        @t = 0
        @transitionAfter = Math.random()*400
        @elapsed = 0
        while @next == @current
          @next = Math.floor(Math.random()*@generators.length)
    @generators[@current].advance()
    @generators[@next].advance()

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
raaah = new Raaah()
generator = new Dimmer(new Sequencer([linescape, mario, raaah, sinus]))
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
