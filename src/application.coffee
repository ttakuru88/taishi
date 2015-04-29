class SeekBar
  constructor: ->
    @$el = $('#seek-bar')
    @setMinSeconds(0)
    @setValue(0)

  setSource: (@source) ->
    @setMaxSeconds(@source.buffer.duration)
    @setValue(0)

  setValue: (value) ->
    @$el[0].value = value

  seconds: ->
    @$el[0].value

  setMaxSeconds: (max) ->
    @$el[0].setAttribute('max', max)

  setMinSeconds: (min) ->
    @$el[0].setAttribute('min', min)

  onChange: (func) ->
    @$el.off().on('change', func)

$ ->
  window.seekBar = new SeekBar
  source = null
  animationId = null
  audioContext = new (window.AudioContext || window.webkitAudioContext)
  fileReader   = new FileReader

  gainNode = audioContext.createGain()
  gainNode.connect(audioContext.destination)

  analyser = audioContext.createAnalyser()
  analyser.fftSize = 32

  canvas        = document.getElementById('visualizer')
  canvasContext = canvas.getContext('2d')
  canvas.setAttribute('width', analyser.frequencyBinCount * 10)

  saveBuffer = null
  fileReader.onload = ->
    audioContext.decodeAudioData fileReader.result, (buffer) ->
      saveBuffer = buffer
      restart(0)

  seekBar.onChange ->
    if saveBuffer
      gainNode.gain.value = 0
      restart(seekBar.seconds())

  restart = (offsetSec) ->
    if source
      source.stop()
      cancelAnimationFrame(animationId)

    source = audioContext.createBufferSource()

    source.buffer = saveBuffer
    source.connect(gainNode)
    source.connect(analyser)

    seekBar.setSource(source)
    seekBar.setValue(offsetSec)

    source.start(0, offsetSec)

    animationId = requestAnimationFrame(render)

  document.getElementById('file').addEventListener 'change', (e) ->
    fileReader.readAsArrayBuffer(e.target.files[0])

  render = ->
    spectrums = new Uint8Array(analyser.frequencyBinCount)
    analyser.getByteFrequencyData(spectrums)

    canvasContext.clearRect(0, 0, canvas.width, canvas.height)

    spectrumSum = 0
    len = spectrums.length
    for spectrum, i in spectrums
      canvasContext.fillRect((len - i - 1)*10, canvas.height - spectrum, 5, spectrum)
      spectrumSum += spectrum

    if spectrumSum > 0
      ratio = 1500.0 / spectrumSum
      gainNode.gain.value = Math.pow(ratio, 1.4)

      canvasContext.fillText("x #{Math.round(ratio * 100) / 100}", 10, 10)

    animationId = requestAnimationFrame(render)
