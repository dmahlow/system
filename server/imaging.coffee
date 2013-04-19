# SERVER IMAGING
# --------------------------------------------------------------------------
# Handles and manipulates images on the server.

class Imaging

    # Define the filesystem and ImageMagick objects.
    fs = require "fs"
    im = require "imagemagick"
    logger = require "./logger.coffee"
    settings = require "./settings.coffee"

    # Converts the specified SVG to PNG, by creating a new file with same name
    # but different extension. Image will also be resized and scale to the specified width.
    svgToPng: (svgSource, width) =>
        fs.exists svgSource, (exists) ->
            if exists
                im.convert [svgSource, "-resize", width, svgSource.replace(".svg", ".png")]
                if settings.General.debug
                    logger.info "Imaging.svgToPng", svgSource, width
            else
                logger.warn "Can't convert SVG to PNG.", "Source #{svgSource} does not exist."


# Singleton implementation
# --------------------------------------------------------------------------
Imaging.getInstance = ->
    @instance = new Imaging() if not @instance?
    return @instance

module.exports = exports = Imaging.getInstance()