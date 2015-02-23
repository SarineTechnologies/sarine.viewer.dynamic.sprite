
/*!
sarine.viewer.dynamic.sprite - v0.0.4 -  Monday, February 23rd, 2015, 2:45:04 PM 
 The source code, name, and look and feel of the software are Copyright © 2015 Sarine Technologies Ltd. All Rights Reserved. You may not duplicate, copy, reuse, sell or otherwise exploit any portion of the code, content or visual design elements without express written permission from Sarine Technologies Ltd. The terms and conditions of the sarine.com website (http://sarine.com/terms-and-conditions/) apply to the access and use of this software.
 */

(function() {
  var Sprite,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Sprite = (function(_super) {
    var SprtieImg;

    __extends(Sprite, _super);

    function Sprite(options) {
      Sprite.__super__.constructor.call(this, options);
      this.jsonFileName = options.jsonFileName, this.firstImagePath = options.firstImagePath, this.spritesPath = options.spritesPath, this.oneSprite = options.oneSprite;
      this.metadata = void 0;
      this.sprites = [];
      this.currentSprite = 0;
      this.playing = false;
      this.delta = 1;
      this.imageIndex = -1;
      this.imagesDownload = 0;
      this.imagegap = 0;
      this.playOrder = {};
    }

    SprtieImg = (function() {
      function SprtieImg(img, size) {
        this.column = img.width / size;
        this.rows = img.height / size;
        this.image = img;
        this.totalImage = this.column * this.rows;
      }

      return SprtieImg;

    })();

    Sprite.prototype.convertElement = function() {
      this.canvas = $("<canvas>");
      this.ctx = this.canvas[0].getContext('2d');
      return this.element.append(this.canvas);
    };

    Sprite.prototype.first_init = function() {
      var defer, msg, _t;
      defer = this.first_init_defer;
      msg = {};
      defer.notify(this.id, "load_json", "start");
      _t = this;
      $.getJSON(this.src + this.jsonFileName, function(data) {
        _t.metadata = data;
        defer.notify(_t.id + " : load Json");
        _t.metadata = data;
        _t.canvas.attr({
          "width": data.ImageSize,
          "height": data.ImageSize
        }).parent().css("background", "#" + data.background);
        _t.delay = 1000 / data.FPS;
        if (_t.playing) {
          return _t.play();
        }
      }).then(function() {
        defer.notify(_t.id + " : start load first image");
        return _t.loadImage(_t.src + _t.firstImagePath).then(function(img) {
          defer.notify(_t.id + " : finish load first image");
          _t.ctx.drawImage(img, 0, 0, _t.metadata.ImageSize, _t.metadata.ImageSize);
          _t.imageIndex = 0;
          return defer.resolve(_t);
        });
      });
      return defer;
    };

    Sprite.prototype.full_init = function() {
      var defer, _t;
      defer = this.full_init_defer;
      defer.notify(this.id + " : start load first image");
      _t = this;
      this.downloadSprite(defer).then(function() {
        if (_t.autoPlay) {
          _t.play(true);
        }
        return true;
      });
      return defer;
    };

    Sprite.prototype.downloadSprite = function(mainDefer) {
      var _t;
      _t = this;
      return this.loadImage(this.src + this.spritesPath + (!this.oneSprite ? this.sprites.length : "") + ".jpg").then(function(img) {
        var sprite;
        sprite = new SprtieImg(img, _t.metadata.ImageSize);
        _t.imagesDownload += sprite.column * sprite.rows;
        _t.sprites.push(sprite);
        if (_t.imagesDownload >= _t.metadata.TotalImageCount) {
          mainDefer.resolve(_t);
        } else {
          _t.downloadSprite(mainDefer);
        }
        return true;
      });
    };

    Sprite.prototype.autoPlayFunc = function() {};

    Sprite.prototype.nextImage = function() {
      var col, imageInSprite, imgInfo, playingSprite, row;
      if (this.metadata && this.sprites.length > 0) {
        if (this.imageIndex + this.delta === this.metadata.TotalImageCount || this.imageIndex + this.delta === this.imagesDownload) {
          this.delta = -1;
        }
        if (this.imageIndex + this.delta === -1) {
          this.delta = 1;
        }
        this.imageIndex += this.delta;
        playingSprite = this.sprites[this.currentSprite];
        if ((this.imageIndex - this.imagegap) % playingSprite.totalImage === 0 && this.imageIndex > 0) {
          if (this.delta === 1) {
            playingSprite = this.sprites[++this.currentSprite];
          } else if (this.delta === -1) {
            playingSprite = this.sprites[--this.currentSprite];
          }
          this.imagegap = this.imageIndex;
        }
        imageInSprite = this.imageIndex - this.imagegap + (this.delta === -1 ? this.sprites[this.currentSprite].totalImage : 0);
        col = parseInt(-1 * parseInt(imageInSprite % playingSprite.column) * this.metadata.ImageSize);
        row = parseInt(-1 * parseInt(imageInSprite / playingSprite.rows) * this.metadata.ImageSize);
        if (!this.playOrder[this.imageIndex]) {
          this.playOrder[this.imageIndex] = {
            spriteNumber: this.currentSprite,
            col: col,
            row: row
          };
        }
        imgInfo = this.playOrder[this.imageIndex];
        return this.ctx.drawImage(this.sprites[imgInfo.spriteNumber].image, imgInfo.col, imgInfo.row);
      }
    };

    return Sprite;

  })(Viewer.Dynamic);

  this.Sprite = Sprite;

}).call(this);
