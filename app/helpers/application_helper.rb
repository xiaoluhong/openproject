#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'forwardable'
require 'cgi'

module ApplicationHelper
  include OpenProject::TextFormatting
  include OpenProject::ObjectLinking
  include OpenProject::SafeParams
  include I18n
  include ERB::Util
  include Redmine::I18n
  include HookHelper
  include IconsHelper
  include AdditionalUrlHelpers
  include OpenProject::PageHierarchyHelper

  # Return true if user is authorized for controller/action, otherwise false
  def authorize_for(controller, action, project: @project)
    User.current.allowed_to?({ controller: controller, action: action }, project)
  end

  # Display a link if user is authorized
  #
  # @param [String] name Anchor text (passed to link_to)
  # @param [Hash] options Hash params. This will checked by authorize_for to see if the user is authorized
  # @param [optional, Hash] html_options Options passed to link_to
  # @param [optional, Hash] parameters_for_method_reference Extra parameters for link_to
  #
  # When a block is given, skip the name parameter
  def link_to_if_authorized(*args, &block)
    name = args.shift unless block_given?
    options = args.shift || {}
    html_options = args.shift
    parameters_for_method_reference = args

    return unless authorize_for(options[:controller] || params[:controller], options[:action])

    if block_given?
      link_to(options, html_options, *parameters_for_method_reference, &block)
    else
      link_to(name, options, html_options, *parameters_for_method_reference)
    end
  end

  def required_field_name(name = '')
    safe_join [name, ' ', content_tag('span', '*', class: 'required')]
  end

  def li_unless_nil(link, options = {})
    content_tag(:li, link, options) if link
  end

  # Show a sorted linkified (if active) comma-joined list of users
  def list_users(users, options = {})
    users.sort.map { |u| link_to_user(u, options) }.join(', ')
  end

  # returns a class name based on the user's status
  def user_status_class(user)
    'status_' + user.status_name
  end

  def user_status_i18n(user)
    t "status_#{user.status_name}"
  end

  def delete_link(url, options = {})
    options = {
      method: :delete,
      data: { confirm: I18n.t(:text_are_you_sure) },
      class: 'icon icon-delete'
    }.merge(options)

    link_to I18n.t(:button_delete), url, options
  end

  def format_activity_title(text)
    h(truncate_single_line(text, length: 100))
  end

  def format_activity_day(date)
    date == User.current.today ? l(:label_today).titleize : format_date(date)
  end

  def format_activity_description(text)
    html_escape_once(truncate(text.to_s, length: 120).gsub(%r{[\r\n]*<(pre|code)>.*$}m, '...'))
      .gsub(/[\r\n]+/, '<br />')
      .html_safe
  end

  def due_date_distance_in_words(date)
    if date
      label = date < Date.today ? :label_roadmap_overdue : :label_roadmap_due_in
      l(label, distance_of_date_in_words(Date.today, date))
    end
  end

  # Renders flash messages
  def render_flash_messages
    messages = flash
      .reject { |k,_| k.start_with? '_' }
      .map { |k, v| render_flash_message(k, v) }

    safe_join messages, "\n"
  end

  def join_flash_messages(messages)
    if messages.respond_to?(:join)
      safe_join(messages, '<br />'.html_safe)
    else
      messages
    end
  end

  def render_flash_message(type, message, html_options = {})
    css_classes  = ["flash #{type} icon icon-#{type}", html_options.delete(:class)]

    # Add autohide class to notice flashes if configured
    if type.to_s == 'notice' && User.current.pref.auto_hide_popups?
      css_classes << 'autohide-notification'
    end

    html_options = { class: css_classes.join(' '), role: 'alert' }.merge(html_options)

    content_tag :div, html_options do
      concat(join_flash_messages(message))
      concat(content_tag(:i, '', class: 'icon-close close-handler',
                                 tabindex: '0',
                                 role: 'button',
                                 aria: { label: ::I18n.t('js.close_popup_title') }))
    end
  end

  def project_tree_options_for_select(projects, selected: nil, disabled: {}, &_block)
    options = ''.html_safe
    Project.project_level_list(projects).each do |element|
      identifier = element[:project].id
      tag_options = {
        value: h(identifier),
        title: h(element[:project].name),
      }

      if !selected.nil? && selected.id == identifier
        tag_options[:selected] = true
      end

      tag_options[:disabled] = true if disabled.include? identifier

      content = ''.html_safe
      content << ('&nbsp;' * 3 * element[:level] + '&#187; ').html_safe if element[:level] > 0
      content << element[:project].name

      options << content_tag('option', content, tag_options)
    end

    options
  end

  # Yields the given block for each project with its level in the tree
  #
  # Wrapper for Project#project_tree
  def project_tree(projects, &block)
    Project.project_tree(projects, &block)
  end

  def project_nested_ul(projects, &_block)
    s = ''
    if projects.any?
      ancestors = []
      Project.project_tree(projects) do |project, _level|
        if ancestors.empty? || project.is_descendant_of?(ancestors.last)
          s << "<ul>\n"
        else
          ancestors.pop
          s << '</li>'
          while ancestors.any? && !project.is_descendant_of?(ancestors.last)
            ancestors.pop
            s << "</ul></li>\n"
          end
        end
        s << '<li>'
        s << yield(project).to_s
        ancestors << project
      end
      s << ("</li></ul>\n" * ancestors.size)
    end
    s.html_safe
  end

  def principals_check_box_tags(name, principals)
    labeled_check_box_tags(name, principals,
                           title: :user_status_i18n,
                           class: :user_status_class)
  end

  def labeled_check_box_tags(name, collection, options = {})
    collection.sort.map { |object|
      id = name.gsub(/[\[\]]+/, '_') + object.id.to_s

      object_options = options.inject({}) { |h, (k, v)|
        h[k] = v.is_a?(Symbol) ? send(v, object) : v
        h
      }

      object_options[:class] = Array(object_options[:class]) + %w(form--label-with-check-box)

      content_tag :div, class: 'form--field' do
        label_tag(id, object, object_options) do
          styled_check_box_tag(name, object.id, false, id: id) + object
        end
      end
    }.join.html_safe
  end

  def html_hours(text)
    text.gsub(%r{(\d+)\.(\d+)},
              '<span class="hours hours-int">\1</span><span class="hours hours-dec">.\2</span>')
      .html_safe
  end

  def authoring(created, author, options = {})
    label = options[:label] || :label_added_time_by
    l(label, author: link_to_user(author), age: time_tag(created)).html_safe
  end

  def time_tag(time)
    text = distance_of_time_in_words(Time.now, time)
    if @project and @project.module_enabled?('activity')
      link_to(text, { controller: '/activities',
                      action: 'index',
                      project_id: @project,
                      from: time.to_date },
              title: format_time(time))
    else
      datetime = time.acts_like?(:time) ? time.xmlschema : time.iso8601
      content_tag(:time, text, datetime: datetime,
                               title: format_time(time), class: 'timestamp')
    end
  end

  def syntax_highlight(name, content)
    highlighted = OpenProject::SyntaxHighlighting.highlight_by_filename(content, name)
    highlighted.each_line do |line|
      yield highlighted.html_safe? ? line.html_safe : line
    end
  end

  def to_path_param(path)
    path.to_s
  end

  def other_formats_links(&block)
    formats = capture(Redmine::Views::OtherFormatsBuilder.new(self), &block)
    unless formats.nil? || formats.strip.empty?
      content_tag 'p', class: 'other-formats' do
        (l(:label_export_to) + formats).html_safe
      end
    end
  end

  # Returns the theme, controller name, and action as css classes for the
  # HTML body.
  def body_css_classes
    css = ['theme-' + OpenProject::CustomStyles::Design.identifier.to_s]

    if params[:controller] && params[:action]
      css << 'controller-' + params[:controller]
      css << 'action-' + params[:action]
    end

    css << "ee-banners-#{EnterpriseToken.show_banners? ? 'visible' : 'hidden'}"

    # Add browser specific classes to aid css fixes
    css += browser_specific_classes

    css.join(' ')
  end

  def accesskey(s)
    OpenProject::AccessKeys.key_for s
  end

  # Same as Rails' simple_format helper without using paragraphs
  def simple_format_without_paragraph(text)
    text.to_s
      .gsub(/\r\n?/, "\n")                    # \r\n and \r -> \n
      .gsub(/\n\n+/, '<br /><br />')          # 2+ newline  -> 2 br
      .gsub(/([^\n]\n)(?=[^\n])/, '\1<br />')  # 1 newline   -> br
      .html_safe
  end

  def lang_options_for_select(blank = true)
    auto = if blank && (valid_languages - all_languages) == (all_languages - valid_languages)
             [['(auto)', '']]
           else
             []
           end

    mapped_languages = valid_languages.map { |lang| translate_language(lang) }

    auto + mapped_languages.sort_by(&:last)
  end

  def all_lang_options_for_select(blank = true)
    initial_lang_options = blank ? [['(auto)', '']] : []

    mapped_languages = all_languages.map { |lang| translate_language(lang) }

    initial_lang_options + mapped_languages.sort_by(&:last)
  end

  def labelled_tabular_form_for(record, options = {}, &block)
    options.reverse_merge!(builder: TabularFormBuilder, html: {})
    options[:html][:class] = 'form' unless options[:html].has_key?(:class)
    form_for(record, options, &block)
  end

  def back_url_hidden_field_tag
    back_url = params[:back_url] || request.env['HTTP_REFERER']
    back_url = CGI.unescape(back_url.to_s)
    hidden_field_tag('back_url', CGI.escape(back_url), id: nil) unless back_url.blank?
  end

  def back_url_to_current_page_hidden_field_tag
    back_url = params[:back_url]
    if back_url.present?
      back_url = back_url.to_s
    elsif request.get? and !params.blank?
      back_url = request.url
    end

    hidden_field_tag('back_url', back_url) unless back_url.blank?
  end

  def check_all_links(form_name)
    link_to_function(t(:button_check_all), "checkAll('#{form_name}', true)") +
      ' | ' +
      link_to_function(t(:button_uncheck_all), "checkAll('#{form_name}', false)")
  end

  def current_layout
    controller.send :_layout, ["html"]
  end

  # Generates the HTML for a progress bar
  # Params:
  # * pcts:
  #   * a number indicating the percentage done
  #   * or an array of two numbers -> [percentage_closed, percentage_done]
  #     where percentage_closed <= percentage_done
  #     and   percentage_close + percentage_done <= 100
  # * options:
  #   A hash containing the following keys:
  #   * width: (default '100px') the css-width for the progress bar
  #   * legend: (default: '') the text displayed alond with the progress bar
  def progress_bar(pcts, options = {})
    pcts = Array(pcts).map(&:round)
    closed = pcts[0]
    done   = (pcts[1] || closed) - closed
    width = options[:width] || '100px;'
    legend = options[:legend] || ''
    total_progress = options[:hide_total_progress] ? '' : t(:total_progress)
    percent_sign = options[:hide_percent_sign] ? '' : '%'

    content_tag :span do
      progress = content_tag :span, class: 'progress-bar', style: "width: #{width}" do
        concat content_tag(:span, '', class: 'inner-progress closed', style: "width: #{closed}%")
        concat content_tag(:span, '', class: 'inner-progress done',   style: "width: #{done}%")
      end
      progress + content_tag(:span, "#{legend}#{percent_sign} #{total_progress}", class: 'progress-bar-legend')
    end
  end

  def checked_image(checked = true)
    if checked
      icon_wrapper('icon-context icon-checkmark', t(:label_checked))
    end
  end

  def calendar_for(*args)
    ActiveSupport::Deprecation.warn "calendar_for has been removed. Please add the class '-augmented-datepicker' instead.", caller
  end

  def locale_first_day_of_week
    case Setting.start_of_week.to_i
    when 1
      '1' # Monday
    when 7
      '0' # Sunday
    when 6
      '6' # Saturday
    else
      # use language (pass a blank string into the JSON object,
      # as the datepicker implementation checks for numbers in
      # /frontend/app/misc/datepicker-defaults.js:34)
      ''
    end
  end

  # To avoid the menu flickering, disable it
  # by default unless we're in test mode
  def initial_menu_styles
    Rails.env.test? ? '' : 'display:none'
  end

  def initial_menu_classes(side_displayed, show_decoration)
    classes = 'can-hide-navigation'
    classes << ' nosidebar' unless side_displayed
    classes << ' nomenus' unless show_decoration

    classes
  end

  # Add a HTML meta tag to control robots (web spiders)
  #
  # @param [optional, String] content the content of the ROBOTS tag.
  #   defaults to no index, follow, and no archive
  def robot_exclusion_tag(content = 'NOINDEX,FOLLOW,NOARCHIVE')
    "<meta name='ROBOTS' content='#{h(content)}' />".html_safe
  end

  # Returns true if arg is expected in the API response
  def include_in_api_response?(arg)
    unless @included_in_api_response
      param = params[:include]
      @included_in_api_response = param.is_a?(Array) ? param.map(&:to_s) : param.to_s.split(',')
      @included_in_api_response.map!(&:strip)
    end
    @included_in_api_response.include?(arg.to_s)
  end

  # Returns options or nil if nometa param or X-OpenProject-Nometa header
  # was set in the request
  def api_meta(options)
    if params[:nometa].present? || request.headers['X-OpenProject-Nometa']
      # compatibility mode for activeresource clients that raise
      # an error when deserializing an array with attributes
      nil
    else
      options
    end
  end

  #
  # Returns the footer text displayed in the layout file.
  #
  def footer_content
    elements = []
    elements << I18n.t(:text_powered_by, link: link_to(OpenProject::Info.app_name,
                                                       OpenProject::Info.url))
    unless OpenProject::Footer.content.nil?
      OpenProject::Footer.content.each do |name, value|
        content = value.respond_to?(:call) ? value.call : value
        if content
          elements << content_tag(:span, content, class: "footer_#{name}")
        end
      end
    end
    elements << Setting.additional_footer_content if Setting.additional_footer_content.present?
    elements.join(', ').html_safe
  end

  def permitted_params
    PermittedParams.new(params, current_user)
  end

  def translate_language(lang_code)
    # rename in-context translation language name for the language select box
    if lang_code == Redmine::I18n::IN_CONTEXT_TRANSLATION_CODE &&
       ::I18n.locale != Redmine::I18n::IN_CONTEXT_TRANSLATION_CODE
      [Redmine::I18n::IN_CONTEXT_TRANSLATION_NAME, lang_code.to_s]
    else
      [ll(lang_code.to_s, :general_lang_name), lang_code.to_s]
    end
  end

  def link_to_content_update(text, url_params = {}, html_options = {})
    link_to(text, url_params, html_options)
  end

  def password_complexity_requirements
    rules = OpenProject::Passwords::Evaluator.rules_description
    # use 0..0, so this doesn't fail if rules is an empty string
    rules[0] = rules[0..0].upcase

    s = raw '<em>' + OpenProject::Passwords::Evaluator.min_length_description + '</em>'
    s += raw '<br /><em>' + rules + '</em>' unless rules.empty?
    s
  end
end
