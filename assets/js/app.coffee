

t=0


class BlankGenerator
  light: (x,y) ->
    "#fff"
  advance: ->

class Sinusoidal
  constructor: ->
    @t = 0
  light: (x,y) ->
    cx = Math.sin(@t/30)*5
    cy = Math.cos(@t/22)*9
    r = @sampleSin(cx, cy, 3, x, y)
    cx = Math.sin(@t/90.2)*5.1
    cy = Math.cos(@t/21.8)*8.5
    g = @sampleSin(cx, cy, 3.1, x, y)
    cx = Math.sin(@t/(Math.sin(@t/20)*20))*5.9
    cy = Math.cos(@t/22.1)*9.1
    b = @sampleSin(cx, cy, 5, x, y)
    "##{r.toString(16)}#{g.toString(16)}#{b.toString(16)}"
  sampleSin: (cx, cy, freq, sx, sy) ->
    d = Math.sqrt(Math.pow(sx-cx, 2)+Math.pow(sy-cy,2))
    r = Math.floor((Math.sin(d/(Math.PI*2)*freq)+1)*128)
    return 255 if r > 255
    r
  advance: ->
    @t += 0.4


class Lamps
  constructor: (canvas, @width, @height, @generator) ->
    @ctx = canvas.getContext('2d')
    @x = 20
    @y = 20
    @radius = 20
  render: ->
    for x in [0...@width]
      for y in [0...@height]
        @ctx.fillStyle = @generator.light(x-@width/2,y-@height/2)
        @ctx.fillRect(@x+x*@radius*1.2, @y+y*@radius*1.2, @radius, @radius)
        @ctx.beginPath()
        @ctx.arc(@x+x*@radius*1.2, @y+y*@radius*1.2, 0, 2*Math.PI)
        @ctx.fill()

generator = null
lamps = null

init = ->
  generator = new Sinusoidal()
  lamps = new Lamps($('canvas')[0], 9, 9, generator)

animate = ->
  requestAnimationFrame( animate )
  lamps.render()
  generator.advance()


init()
animate()
