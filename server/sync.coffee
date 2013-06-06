# SERVER SYNC
# --------------------------------------------------------------------------
# Handles syncing data (downloads and uploads) to external resources.

class Sync

    # Require Expresser.
    expresser = require "expresser"
    settings = expresser.settings

    # Required modules.
    fs = require "fs"
    http = require "http"
    moment = require "moment"
    url = require "url"

    # Holds a copy of all files being downloaded.
    currentDownloads: {}

    # Holds how many errors happened for downloads.
    # If a download throws errors too many times, it will cancel all downloads for
    # that specific URL for a brief period of time.
    errorCounters: {}

    # Download an external file and save it to the local disk.
    # Do not proceed if `remoteUrl` is not valid, or if the file is already being
    # downloaded at the moment.
    download: (remoteUrl, localFile, callback, contentType) =>
        if not remoteUrl?
            expresser.logger.warn "Download aborted, remoteUrl is not defined.", localFile
            return

        now = new Date()
        existing = @currentDownloads[localFile]

        # Check existing download time.
        if existing? and now.getTime() - existing.date.getTime() < settings.web.downloadTimeout
            expresser.logger.warn "Download aborted, already downloading!", localFile, existing
            return

        # Check if the specified `remoteUrl` has failed to download repeatedly. If so, proceed
        # only after some time (defined by the `connRestartInterval` web setting).
        errorCount = @errorCounters[remoteUrl]
        if errorCount?
            if errorCount > settings.web.connRestartInterval
                if moment().valueOf() < errorCount
                    if settings.general.debug
                        expresser.logger.warn "Sync.download", "Abort because failed too many times before.", remoteUrl
                    return
                else
                    delete @errorCounters[remoteUrl]

        # Add it to the `currentDownloads` object to avoid having multiple downloads
        # of the same file at the same time.
        @currentDownloads[localFile] = {url: remoteUrl, date: now}

        # If no content type was passed, set the default to JSON.
        contentType = "application/json" if not contentType?

        # Check if `Settings.Web.downloaderHeaders` is not null, and if so append
        # it to the content type header.
        if settings.web.downloaderHeaders? and settings.web.downloaderHeaders isnt ""
            headers = settings.web.downloaderHeaders
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
        if not options.auth? and settings.web.downloaderUser? and settings.web.downloaderUser isnt ""
            options.auth = "#{settings.web.downloaderUser}:#{settings.web.downloaderPassword}"

        # Helper function to proccess and notify the user about download errors.
        downloadError = (error) =>
            counter = @errorCounters[remoteUrl]

            # Add up to the error counter.
            if counter? and counter < settings.web.alertAfterFailedDownloads
                counter = counter + 1
            else
                counter = 1

            # If download has failed many times, log and error instead of warning and
            # update the `errorCounters` reference value with the current time plus
            # the value specified on the `connRestartInterval` web setting.
            if counter is settings.web.alertAfterFailedDownloads
                time = moment().add("ms", settings.web.connRestartInterval).valueOf()
                @errorCounters[remoteUrl] = time
                expresser.logger.error "Sync.download", remoteUrl, error
            else
                @errorCounters[remoteUrl] = counter
                expresser.logger.warn "Sync.download", remoteUrl, error

            # Send error using Socket.IO.
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
                        delete @errorCounters[remoteUrl]

                        if settings.general.debug
                            expresser.logger.info "Sync.download", remoteUrl, localFile

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