import LocalTime from "./local_time"
import "./calendar_date"

{strftime, translate, getI18nValue, config} = LocalTime

class LocalTime.RelativeTime
  constructor: (@value, @dateOnly, @onPrefix) ->
    @calendarDate = LocalTime.CalendarDate.fromDate(@value)

  toString: ->
    if @dateOnly
      if day = @toDayString()
        day
      else
        date = @toDateString()
        if @onPrefix
          translate("date.on", {date})
        else
          date
    else if time = @toTimeElapsedString()
      translate("time.elapsed", {time})
    else
      time = @toTimeString()
      if date = @toDayString()
        key = "datetime.at"
      else
        date = @toDateString()
        key  = if @onPrefix then "datetime.on_at" else "datetime.at"
      translate(key, {date, time})

  toTimeOrDateString: ->
    if @calendarDate.isToday()
      @toTimeString()
    else
      @toDateString()

  toTimeElapsedString: ->
    ms = new Date().getTime() - @value.getTime()
    seconds = Math.round ms / 1000
    minutes = Math.round seconds / 60
    hours = Math.round minutes / 60

    if ms < 0
      null
    else if seconds < 10
      time = translate("time.second")
      translate("time.singular", {time})
    else if seconds < 45
      "#{seconds} #{translate("time.seconds")}"
    else if seconds < 90
      time = translate("time.minute")
      translate("time.singular", {time})
    else if minutes < 45
      "#{minutes} #{translate("time.minutes")}"
    else if minutes < 90
      time = translate("time.hour")
      translate("time.singularAn", {time})
    else if hours < 24
      "#{hours} #{translate("time.hours")}"
    else
      ""

  toDayString: ->
    switch @calendarDate.daysPassed()
      when 0
        translate("date.today")
      when 1
        translate("date.yesterday")
      when -1
        translate("date.tomorrow")
      else
        ""

  toWeekdayString: ->
    @toDayString() or
      switch @calendarDate.daysPassed()
        when 2,3,4,5,6
          strftime(@value, "%A")
        else
          ""

  toDateString: ->
    format = if @calendarDate.occursThisYear()
      getI18nValue("date.formats.thisYear")
    else
      getI18nValue("date.formats.default")

    strftime(@value, format)

  toTimeString: ->
    format = if config.useFormat24 then "default_24h" else "default"
    strftime(@value, getI18nValue("time.formats.#{format}"))
