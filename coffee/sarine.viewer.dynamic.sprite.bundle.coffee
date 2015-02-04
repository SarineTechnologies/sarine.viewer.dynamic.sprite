class Viewer
	rm = ResourceManager.getInstance();
	constructor: (options) ->
		@first_init_defer = $.Deferred()
		@full_init_defer = $.Deferred()
		{@src, @element,@autoPlay} = options
		@id = @element[0].id;
		@element = @convertElement()
		Object.getOwnPropertyNames(Viewer.prototype).forEach((k)-> 
			if @[k].name == "Error" 
  				console.error @id, k, "Must be implement" , @
		,
			@)
		@element.data "class", @
		@element.on "play", (e)-> $(e.target).data("class").play.apply($(e.target).data("class"),[true])
		@element.on "stop", (e)-> $(e.target).data("class").stop.apply($(e.target).data("class"),[true])
		@element.on "cancel", (e)-> $(e.target).data("class").cancel().apply($(e.target).data("class"),[true])
	error = () ->
		console.error(@id,"must be implement" )
	first_init: Error
	full_init: Error
	play: Error
	stop: Error
	convertElement : Error
	cancel : ()-> rm.cancel(@)
	loadImage : (src)-> rm.loadImage.apply(@,[src])
	setTimeout : (fun,delay)-> rm.setTimeout.apply(@,[@delay])
    

		  
console.log ""
@Viewer = Viewer





class Viewer.Dynamic extends Viewer
	@playing = false
	nextImage : Error


	constructor: (options) ->
		super(options)
		@delay = 50
		Object.getOwnPropertyNames(Viewer.Dynamic.prototype).forEach((k)-> 
			if @[k].name == "Error" 
				console.error @id, k, "Must be implement" , @
		,
			@)
	play: (force,delay) ->
		if force
			@playing = true;
		@nextImage.apply(@)
		if(@playing)
			_t = @
			@setTimeout(@delay).then(_t.play)
	stop: ()->
		@playing = false



class Sprite extends Viewer.Dynamic
	constructor: (options) ->
		super(options)
		{@jsonFileName,@firstImagePath,@spritesPath,@oneSprite} = options
		@metadata = undefined
		@sprites = []
		@currentSprite = 0
		@playing = false
		@delta = 1
		@imageIndex = -1
		@imagesDownload = 0
		@imagegap = 0
		@playOrder = {}


	class SprtieImg
		constructor: (img,size) ->
			@column = img.width / size
			@rows = img.height / size
			@image = img
			@totalImage = @column * @rows


	convertElement : () ->
		@canvas = $("<canvas>")
		@ctx = @canvas[0].getContext('2d')
		@element.append(@canvas)
	
	first_init : ()->
		defer = @first_init_defer 
		msg = {}
		defer.notifyWith(@id,"load_json","start") 
		_t = @
		$.getJSON @src + @jsonFileName , (data)->
			_t.metadata = data
			defer.notify(_t.id + " : load Json"	);
			_t.metadata = data
			_t.canvas.attr({
					"width": data.ImageSize
					"height": data.ImageSize
				}).parent().css "background" , "##{data.background}"
			_t.delay = 1000 / data.FPS
			if(_t.playing)
				_t.play()
		.then ()->
			defer.notify(_t.id + " : start load first image");
			_t.loadImage(_t.src + _t.firstImagePath).then (img)-> 
				defer.notify(_t.id + " : finish load first image");
				_t.ctx.drawImage(img, 0, 0, _t.metadata.ImageSize, _t.metadata.ImageSize)
				_t.imageIndex = 0
				defer.resolve()			
		defer
	full_init : ()->
		defer = @full_init_defer
		defer.notify(@id + " : start load first image")
		_t = @
		@downloadSprite(defer).then(()-> 
			if _t.autoPlay 
				_t.play true
			true
			)
		defer
	downloadSprite : (mainDefer)->
		_t = @
		@loadImage(@src + @spritesPath + (if !@oneSprite then @sprites.length else "") +  ".jpg" ).then (img)->
			sprite = new SprtieImg(img,_t.metadata.ImageSize)
			_t.imagesDownload += sprite.column * sprite.rows
			_t.sprites.push sprite
			if(_t.imagesDownload >= _t.metadata.TotalImageCount)
				mainDefer.resolve()
			else
				_t.downloadSprite(mainDefer)
			true
	autoPlayFunc : ()->
	nextImage : ()->
		if(@metadata && @sprites.length > 0)
			if (@imageIndex + @delta == @metadata.TotalImageCount || @imageIndex + @delta == @imagesDownload)
				@delta = -1
			if (@imageIndex + @delta == -1)
				@delta = 1
			@imageIndex += @delta
			playingSprite = @sprites[@currentSprite]
			if (@imageIndex - @imagegap)  %  playingSprite.totalImage == 0 && @imageIndex > 0
				if @delta == 1
					playingSprite = @sprites[++@currentSprite]
				else if @delta == -1
					playingSprite = @sprites[--@currentSprite]
				@imagegap = @imageIndex

			imageInSprite = @imageIndex - @imagegap + if @delta == -1 then @sprites[@currentSprite].totalImage else 0
			col =  parseInt(-1 * parseInt(imageInSprite % playingSprite.column) * @metadata.ImageSize)
			row = parseInt(-1 * parseInt(imageInSprite / playingSprite.rows) * @metadata.ImageSize)
			if !@playOrder[@imageIndex]
				@playOrder[@imageIndex] = {
					spriteNumber : @currentSprite
					col : col
					row : row
				}
			imgInfo = @playOrder[@imageIndex]
			# console.log($.inArray(playingSprite,sprites),row,col)
			@ctx.drawImage(@sprites[imgInfo.spriteNumber].image, imgInfo.col  ,imgInfo.row)
@Sprite = Sprite
