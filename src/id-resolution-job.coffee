# This module supplies the **IDResolutionJob** class for the **im.js**
# web-service client.
#
# These objects represent jobs submitted to the service. They supply mechanisms for
# checking the status of the job and retrieving the results, or cancelling
# the job if that is required.
#
# This library is designed to be compatible with both node.js
# and browsers.
#

IS_NODE = typeof exports isnt 'undefined'
__root__ = exports ? this

if IS_NODE
  {Deferred} = require('underscore.deferred')
  funcutils = require './util'
  intermine = __root__
else
  {Deferred} = __root__.jQuery
  {intermine} = __root__
  {funcutils} = intermine

{get} = funcutils

class IDResolutionJob

  constructor: (@uid, @service) ->

  fetchStatus:       (cb) => @service.get("ids/#{ @uid }/status").pipe(get 'status').done(cb)

  fetchErrorMessage: (cb) => @service.get("ids/#{ @uid }/status").pipe(get 'message').done(cb)

  fetchResults:      (cb) => @service.get("ids/#{ @uid }/result").pipe(get 'results').done(cb)

  del: (cb) => @service.makeRequest 'DELETE', "ids/#{ @uid }", {}, cb
 
  # Poll the service until the results are available.
  #
  # @example Poll a job
  #   job.poll().then (results) -> handle results
  #
  # @param [Function] onSuccess The success handler (optional)
  # @param [Function] onError The error handler for if the job fails (optional).
  # @param [Function] onProgress The progress handler to receive status updates.
  #
  # @return [Promise<Object>] A promise to yield the results.
  # @see Service#resolveIds
  poll: (onSuccess, onError, onProgress) ->
    ret = Deferred().done(onSuccess).fail(onError).progress(onProgress)
    resp = @fetchStatus()
    resp.fail ret.reject
    resp.done (status) =>
      ret.notify(status)
      switch status
        when 'SUCCESS' then @fetchResults().then(ret.resolve, ret.reject)
        when 'ERROR' then @fetchErrorMessage().then(ret.reject, ret.reject)
        else @poll ret.resolve, ret.reject, ret.notify
    return ret.promise()

IDResolutionJob.create = (service) -> (uid) -> new IDResolutionJob(uid, service)

intermine.IDResolutionJob = IDResolutionJob