module LocalTimeHelper
  def local_time(time, **options)
    time = utc_time(time)

    format12 = options[:format]
    format12, format24 = find_12h_and_24h_formats(format12)

    options[:data] ||= {}
    options[:data].merge! local: :time, format: format12, format24: format24

    time_tag \
      time,
      time.strftime(format12),
      options
  end

  def local_date(time, **options)
    format = options[:format]
    format, _ = find_12h_and_24h_formats(format, prefer: :date)

    local_time \
      time,
      **options.merge(format: format)
  end

  def local_relative_time(time, **options)
    time = utc_time(time)

    unless type = options.delete(:type)
      raise "type param is required"
    end

    data = {
      local:     type,
      on_prefix: options.delete(:on_prefix),
      date_only: options.delete(:date_only)
    }.compact

    options[:data] ||= {}
    options[:data].merge! data

    time_tag \
      time,
      time.strftime(LocalTime.default_time_format),
      options
  end

  def local_time_ago(time_or_date, **options)
    options[:type] = "time-ago"

    if time_or_date.is_a?(Date) && !options.key?(:date_only)
      options[:date_only] = true
    end

    local_relative_time \
      time_or_date,
      **options
  end

  def utc_time(time_or_date)
    time_or_date
      .then { _1.try(:in_time_zone) || _1.to_time }
      .utc
  end

  private

    def find_12h_and_24h_formats(format12, prefer: :time)
      if format12.is_a?(Symbol)
        find_time_formats_by_name(format12, prefer: prefer)
      else
        [ format12.presence || default_time_format(prefer), nil ]
      end
    end

    def find_time_formats_by_name(name, prefer:)
      if use_i18n_time_formats?(name)
        find_i18_time_formats(name, prefer: prefer)
      elsif use_ruby_time_formats?(name)
        find_ruby_time_formats(name, prefer: prefer)
      else
        [ default_time_format(prefer), nil ]
      end
    end

    def default_time_format(prefer = :time)
      if prefer == :time
        LocalTime.default_time_format
      else
        LocalTime.default_date_format
      end
    end

    def use_i18n_time_formats?(name)
      i18n_time_or_date_format(name).present?
    end

    def i18n_time_or_date_format(name, prefer: :time)
      if prefer == :time
        I18n.t("time.formats.#{name}", default: [ :"date.formats.#{name}", "" ]).presence
      else
        I18n.t("date.formats.#{name}", default: [ :"time.formats.#{name}", "" ]).presence
      end
    end

    def find_i18_time_formats(name, prefer:)
      [ i18n_time_or_date_format(name, prefer: prefer),
        i18n_time_or_date_format("#{name}_24h", prefer: prefer) ]
    end

    def use_ruby_time_formats?(name)
      ruby_time_or_date_format(name).present?
    end

    def ruby_time_or_date_format(name, prefer: :time)
      if prefer == :time
        Time::DATE_FORMATS.with_indifferent_access[name] || Date::DATE_FORMATS.with_indifferent_access[name]
      else
        Date::DATE_FORMATS.with_indifferent_access[name] || Time::DATE_FORMATS.with_indifferent_access[name]
      end
    end

    def find_ruby_time_formats(name, prefer:)
      format12 = ruby_time_or_date_format(name, prefer: prefer)

      if format12.is_a?(Proc)
        [ default_time_format(prefer), nil ]
      else
        [ format12, ruby_time_or_date_format("#{name}_24h", prefer: prefer) ]
      end
    end
end
