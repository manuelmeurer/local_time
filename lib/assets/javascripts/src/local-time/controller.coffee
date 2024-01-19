import LocalTime from "./local_time"
import "./relative_time"
import "./page_observer"

{parseDate, strftime, getI18nValue, config} = LocalTime

class LocalTime.Controller
  SELECTOR = "time[data-local]:not([data-localized])"

  constructor: ->
    @pageObserver = new LocalTime.PageObserver SELECTOR, @processElements

  start: ->
    unless @started
      @processElements()
      @startTimer()
      @pageObserver.start()
      @started = true

  startTimer: ->
    if interval = config.timerInterval
      @timer ?= setInterval(@processElements, interval)

  processElements: (elements = document.querySelectorAll(SELECTOR)) =>
    @processElement(element) for element in elements
    elements.length

  processElement: (element) ->
    datetime = element.getAttribute("datetime")
    local = element.getAttribute("data-local")
    onPrefix = element.getAttribute("data-on-prefix") != "false"
    dateOnly = element.getAttribute("data-date-only") == "true"
    format = if config.useFormat24
      element.getAttribute("data-format24") || element.getAttribute("data-format")
    else
      element.getAttribute("data-format")

    time = parseDate(datetime)
    return if isNaN time

    unless element.hasAttribute("title")
      title_format = if config.useFormat24 then "default_24h" else "default"
      title = strftime(time, getI18nValue("datetime.formats.#{title_format}"))
      element.setAttribute("title", title)

    markAsProcessed(element)
    relativeTime = new LocalTime.RelativeTime(time, dateOnly, onPrefix)
    element.textContent = switch local
      when "time"
        markAsLocalized(element)
        strftime(time, format)
      when "date"
        markAsLocalized(element)
        relativeTime.toDateString()
      when "time-ago"
        relativeTime.toString()
      when "time-or-date"
        relativeTime.toTimeOrDateString()
      when "weekday"
        relativeTime.toWeekdayString()
      when "weekday-or-date"
        relativeTime.toWeekdayString() or relativeTime.toDateString()

  markAsLocalized = (element) ->
    element.setAttribute("data-localized", "")

  markAsProcessed = (element) ->
    element.setAttribute("data-processed-at", new Date().toISOString())
