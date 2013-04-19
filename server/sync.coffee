# SERVER SYNC
# --------------------------------------------------------------------------
# Handles syncing data with external resources.

class Sync

    # Define the settings and sockets.
    logger = require "./logger.coffee"
    settings = require "./settings.coffee"
    sockets = require "./sockets.coffee"

    # Define the file system, url and http objects.
    fs = require "fs"
    http = require "http"
    url = require "url"

    # Holds a copy of all files being downloaded.
    currentDownloads: {}

    # Download an external file and save it to the local disk.
    # Do not proceed if `remoteUrl` is not valid, or if the file is already being
    # downloaded at the moment.
    download: (remoteUrl, localFile, callback, contentType) =>
        if not remoteUrl?
            logger.warn "Download aborted, remoteUrl is not defined.", localFile
            return

        now = new Date()
        existing = @currentDownloads[localFile]

        if existing? and now.getTime() - existing.date.getTime() < settings.Web.downloadTimeout
            logger.warn "Download aborted, already downloading!", localFile, existing
            return

        # Add it to the `currentDownloads` object to avoid having multiple downloads
        # of the same file at the same time.
        @currentDownloads[localFile] = {url: remoteUrl, date: now}

        # If no content type was passed, set the default to JSON.
        contentType = "application/json" if not contentType?

        # Check if `Settings.Web.downloaderHeaders` is not null, and if so append
        # it to the content type header.
        if settings.Web.downloaderHeaders? and settings.Web.downloaderHeaders isnt ""
            headers = settings.Web.downloaderHeaders
            headers["Content-Type"] = contentType
        else
            headers = {"Content-Type": contentType}

        # Reset error message and set options.
        errorMessage = null
        urlInfo = url.parse remoteUrl
        options = {host: urlInfo.hostname, port: urlInfo.port, path: urlInfo.path, headers: headers}

        # Make sure port is 443 for https, if left undefined.
        if remoteUrl.indexOf("https") is 0 and not urlInfo.port?
            options.port = 443

        # Check for credentials on the URL.
        if urlInfo.auth? and urlInfo.auth isnt ""
            options.auth = urlInfo.auth

        # Append auth information, if specified on the [settings](settings.html) but
        # only if no credentials were passed directly on the URL.
        if not options.auth? and settings.Web.downloaderUser? and settings.Web.downloaderUser isnt ""
            options.auth = "#{settings.Web.downloaderUser}:#{settings.Web.downloaderPassword}"

        # Helper function to proccess and notify the user about download errors.
        downloadError = (error) =>
            logger.warn "Download error!", remoteUrl, error

            # Send the error to the client using Socket.IO.
            sockets.sendServerError "Download error: " + remoteUrl + " " + error.code

            # Callback passing the error object.
            errorMessage = error.message
            callback(errorMessage, localFile) if callback?

            # Remove download reference from `currentDownloads`.
            @currentDownloads[localFile] = null
            delete @currentDownloads[localFile]

        req = http.get options, (response) =>

            localFileTemp = localFile + ".download"

            # If status is not 200 or 304, it means something went wrong so do not proceed
            # with the download. Otherwise proceed and listen to the `data` and `end` events.
            if response.statusCode isnt 200 and response.statusCode isnt 304

                downloadError {code: response.statusCode, message: "Server returned an unexpected status code."}

            else

                # Create the file stream with a .download extension. This will be renamed after the
                # download has finished and the file is totally written.
                fileWriter = fs.createWriteStream localFileTemp, {"flags": "w+"}

                response.addListener "data", (data) =>
                    fileWriter.write data

                response.addListener "end", () =>
                    fileWriter.addListener "close", () =>

                        # If .download file can't be found, stop here but do not throw the error.
                        if not fs.existsSync localFileTemp
                            delete @currentDownloads[localFile]
                            return

                        # Delete the old file (if there's one) and rename the .download file to its original name.
                        fs.unlinkSync localFile if fs.existsSync localFile

                        # Remove .download extension.
                        fs.renameSync localFileTemp, localFile

                        # Proceed with the callback.
                        callback(errorMessage, localFile) if callback?

                        # Remove download reference from `currentDownloads` when finished.
                        delete @currentDownloads[localFile]

                        if settings.General.debug
                            logger.info "Sync.download", remoteUrl

                    fileWriter.end()
                    fileWriter.destroySoon()

        # Unhandled error, call the downloadError helper.
        req.on "error", (error) =>
            downloadError error


# Singleton implementation
# --------------------------------------------------------------------------
Sync.getInstance = ->
    @instance = new Sync() if not @instance?
    return @instance

module.exports = exports = Sync.getInstance()