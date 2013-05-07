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
    # A callback (err, result) can be passed as well.
    svgToPng: (svgSource, width, callback) =>
        fs.exists svgSource, (exists) ->
            if exists
                try

                    # Try converting the SVG to a PNG file, and trigger
                    # the `callback` if one was passed.
                    im.convert [svgSource, "-resize", width, svgSource.replace(".svg", ".png")]
                    if settings.General.debug
                        logger.info "Imaging.svgToPng", svgSource, width
                    if callback?
                        callback null, "ok"

                catch ex

                    # In case of exception, log it and pass to the `callback`.
                    logger.error "Imaging.svgToPng", ex
                    if callback?
                        callback ex, null

            else

                # SVG does not exist, so log the warning and trigger
                # the `callback` if one was passed.
                msg = "Can't convert SVG to PNG: #{svgSource} does not exist."
                logger.warn "Imaging.svgToPng", msg
                if callback?
                    callback msg, null


# Singleton implementation
# --------------------------------------------------------------------------
Imaging.getInstance = ->
    @instance = new Imaging() if not @instance?
    return @instance

module.exports = exports = Imaging.getInstance()