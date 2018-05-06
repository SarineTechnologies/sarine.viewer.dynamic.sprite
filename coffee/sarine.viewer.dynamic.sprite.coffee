
class Sprite extends Viewer.Dynamic
	constructor: (options) ->
		super(options)
		{@jsonFileName,@firstImagePath,@spritesPath,@oneSprite,@imageType,@backOnEnd,@startImage,@imagesPath} = options
		@imageType = @imageType || '.jpg'
		@backOnEnd = @backOnEnd
		if typeof @backOnEnd == "undefined" then @backOnEnd = true
		@metadata = undefined
		@sprites = []
		@currentSprite = 0
		@playing = false
		@delta = 1
		@imageIndex = -1
		@imagesDownload = 0
		@imagegap = 0
		@playOrder = {}
		@validViewer = true
		@basePluginUrl = options.baseUrl + 'atomic/v1/assets/'
		@http2 = @isHTTP2()

	class SprtieImg
		constructor: (img, size) ->
			@column = img.width / size
			@rows = img.height / size
			@image = img
			@totalImage = @column * @rows


	convertElement: () ->
		@canvas = $("<canvas>")
		@ctx = @canvas[0].getContext('2d')
		@element.append(@canvas)
	
	first_init: () ->
		defer = @first_init_defer
		msg = {}
		defer.notify(@id,"load_json","start")
		_t = @
		$.getJSON @src + @jsonFileName , (data) ->
			_t.metadata = data
			defer.notify(_t.id + " : load Json"	)
			_t.metadata = data
			_t.canvas.attr({
					"width": data.ImageSize
					"height": data.ImageSize
				}).parent().css "background" , "##{data.background}"
			_t.delay = 1000 / data.FPS
			if(_t.playing)
				_t.play()
		.then () ->
			@validViewer = true
			defer.notify(_t.id + " : start load first image")
			_t.loadImage(_t.src + _t.firstImagePath).then (img) ->
				defer.notify(_t.id + " : finish load first image")
				if(!_t.http2)
					_t.ctx.drawImage(img, 0, 0, _t.metadata.ImageSize, _t.metadata.ImageSize)
					_t.imageIndex = 0
					defer.resolve(_t)
				else
					_t.loadImages(defer)
		.fail =>
			@validViewer = false
			_t.loadImage(_t.callbackPic).then (img) ->
				defer.notify(_t.id + " : finish load first image")
				_t.canvas.attr({"class": "no_stone" ,"width": img.width, "height": img.height})
				_t.ctx.drawImage(img, 0, 0, img.width, img.height)
				_t.imageIndex = 0
				defer.resolve(_t)
		defer
	full_init: () ->
		defer = @full_init_defer
		defer.notify(@id + " : start load first image")
		if !@validViewer
			defer.resolve(this)
			defer
		
		_t = @
		if _t.http2
			defer.resolve(this)
		else
			@downloadSprite(defer).then(() ->
				if _t.autoPlay
					_t.play true
				true
				)
		defer
	downloadSprite: (mainDefer) ->
		_t = @
		@loadImage(@src + @spritesPath + (if !@oneSprite then @sprites.length else "") + @imageType ).then (img)->
			sprite = new SprtieImg(img,_t.metadata.ImageSize)
			_t.imagesDownload += sprite.column * sprite.rows
			_t.sprites.push sprite
			if(_t.imagesDownload >= _t.metadata.TotalImageCount)
				mainDefer.resolve(_t)
			else
				_t.downloadSprite(mainDefer)
			true
	autoPlayFunc: () ->
	nextImage: () ->
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

			# fix light 1 sprite issue
			if !@backOnEnd && @sprites.length == 1 
				totalLessOne = @sprites[@currentSprite].totalImage - 1
				imageInSprite = @imageIndex - @imagegap + if @delta == -1 then totalLessOne else 0
			else
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
			if @imageType == '.png'
				@ctx.clearRect(0,0,@metadata.ImageSize,@metadata.ImageSize)
			@ctx.drawImage(@sprites[imgInfo.spriteNumber].image, imgInfo.col  ,imgInfo.row)
	loadImages: (mainDefer) ->
		_t = @
		assets = [
			{ element: 'script', src: _t.basePluginUrl + 'sarine.plugin.imgplayer.min.js' },
			{ element: 'link', src: _t.basePluginUrl + 'sarine.plugin.imgplayer.min.css' }]
		_t.loadAssets(assets, () ->
			_t.div = $("<div/>")
			_t.element.css "-webkit-box-align", "center"
			_t.element.css "-webkit-box-pack", "center"
			_t.element.css "display", "-webkit-box"
			_t.element.append(_t.div)
			
			_t.div.on("play", (event, plugin) ->
					if _t.element.has(_t.canvas).length
						_t.canvas.remove()
						mainDefer.resolve(_t)
					event.stopPropagation()
				)
				.on("pause", (event, plugin) ->
					event.stopPropagation()
				)
				.on("stop", (event, plugin) ->
					event.stopPropagation()
				)
				.imgplay({
					startImage: _t.startImage,
					totalImages: _t.metadata.TotalImageCount,
					imageName: _t.imagesPath.split('/').pop(),
					urlDir: _t.src + _t.imagesPath,
					rate: _t.metadata.FPS,
					height: _t.metadata.ImageSize,
					width: _t.metadata.ImageSize,
					autoPlay: true,
					autoReverse: true,
					userInteraction: false
				})
		)
@Sprite = Sprite