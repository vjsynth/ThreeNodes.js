ThreeNodes = {}

# disable websocket by default since this makes firefox sometimes throw an exception if the server isn't available
# this makes the soundinput node not working
ThreeNodes.websocket_enabled = false

ThreeNodes.nodes = {}

ThreeNodes.mouseX = 0
ThreeNodes.mouseY = 0

ThreeNodes.fields =
  types: {}

ThreeNodes.svg = false
ThreeNodes.flash_sound_value =
  kick: 0
  snare: 0
  hat: 0

define [
  'jQuery',
  'Underscore',
  'Backbone',
  'order!threenodes/collections/Nodes',
  'order!threenodes/views/UI',
  'order!threenodes/views/Timeline',
  'order!threenodes/utils/AppWebsocket',
  'order!threenodes/utils/FileHandler',
  'order!threenodes/utils/UrlHandler',
  "order!threenodes/utils/WebglBase",
], ($, _, Backbone) ->
  "use strict"
  
  # use a global event dispatcher instead of the context/commandMap thing
  # it may be removed if all commands are converted to backbone class (event)
  ThreeNodes.events = _.extend({}, Backbone.Events)
  
  class ThreeNodes.App
    constructor: (testing_mode = false) ->
      # save settings in a global object
      # if you have a more elegant way to handle this don't hesitate
      ThreeNodes.settings =
        testing_mode: testing_mode
        player_mode: false
      
      @url_handler = new ThreeNodes.UrlHandler()
      @nodegraph = new ThreeNodes.NodeGraph([], {is_test: testing_mode})
      @socket = new ThreeNodes.AppWebsocket()
      @webgl = new ThreeNodes.WebglBase()
      @file_handler = new ThreeNodes.FileHandler(@nodegraph)
            
      ThreeNodes.events.on "ClearWorkspace", () => @clearWorkspace()
      
      @initUI(testing_mode)
      @initTimeline()
      
      # removing this would require to redirect path
      # for the node.js server and github page (if possible)
      # for simplicity disable pushState
      Backbone.history.start
        pushState: false
      
      return true
    
    initUI: (testing_mode) =>
      if testing_mode == false
        @ui = new ThreeNodes.UI
          el: $("body")
        @ui.on("render", @nodegraph.render)
        @ui.on("renderConnections", @nodegraph.renderAllConnections)
      else
        $("body").addClass "test-mode"
        ThreeNodes.events.trigger "InitUrlHandler"
      return this
    
    initTimeline: () =>
      $("#timeline-container, #keyEditDialog").remove()
      if @ui && @timelineView
        @ui.off("render", @timelineView.update)
        @ui.off("selectAnims", @timelineView.selectAnims)
      
      if @timelineView
        @timelineView.off("trackRebuild", @nodegraph.showNodesAnimation)
        @timelineView.off("startSound", @nodegraph.startSound)
        @timelineView.off("stopSound", @nodegraph.stopSound)
        @timelineView.remove()
      
      $("#timeline").html("")
      @timelineView = new ThreeNodes.AppTimeline
        el: $("#timeline")
      
      @nodegraph.timeline = @timelineView
      
      if @ui
        @ui.on("render", @timelineView.update)
        @ui.on("selectAnims", @timelineView.selectAnims)
        @ui.on("timelineResize", @timelineView.resize)
      
      @timelineView.on("trackRebuild", @nodegraph.showNodesAnimation)
      @timelineView.on("startSound", @nodegraph.startSound)
      @timelineView.on("stopSound", @nodegraph.stopSound)
      ThreeNodes.events.trigger("OnUIResize")
    
    clearWorkspace: () ->
      @reset_global_variables()
      @initTimeline()
    
    reset_global_variables: () ->
      ThreeNodes.uid = 0
      @nodegraph.node_connections = []
      ThreeNodes.selected_nodes = $([])
