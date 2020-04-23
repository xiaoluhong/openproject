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

module OpenProject::TextFormatting
  module Filters
    class SanitizationFilter < HTML::Pipeline::SanitizationFilter
      def context
        super.merge(whitelist: WHITELIST.merge(
          elements: WHITELIST[:elements] + ['macro'],
          # Whitelist class and data-* attributes on all macros
          attributes: WHITELIST[:attributes].merge('macro' => ['class', :data]),
          transformers: WHITELIST[:transformers] + [
            # Add rel attribute to prevent tabnabbing
            lambda { |env|
              name = env[:node_name]
              node = env[:node]
              if name == 'a'
                node['rel'] = 'noopener noreferrer'
              end
            },
            # Replace to do lists in tables with their markdown equivalent
            lambda { |env|
              name = env[:node_name]
              table = env[:node]

              next unless name == 'table'

              table.css('label.todo-list__label').each do |label|
                checkbox = label.css('input[type=checkbox]').first
                checked = checkbox.attr('checked') == 'checked' ? 'x' : ' '
                checkbox.unlink

                # assign all children of the label to its parent
                # that might be the LI, or another element (code, link)
                parent = label.parent
                # However the task list text must be added to the LI
                li_node = label.ancestors.detect { |node| node.name == 'li' }
                li_node.prepend_child " [#{checked}] "

                # Prepend if there is a parent in between
                if parent == li_node
                  parent.add_child label.children
                else
                  parent.prepend_child label.children
                end
              end
            }
          ]
        ))
      end
    end
  end
end
