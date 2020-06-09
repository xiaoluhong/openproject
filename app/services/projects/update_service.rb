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

module Projects
  class UpdateService < ::BaseServices::Update
    private

    attr_accessor :memoized_changes

    def set_attributes(params)
      ret = super

      # Because awesome_nested_set reloads the model after saving, we cannot rely
      # on saved_changes.
      self.memoized_changes = model.changes

      ret
    end

    def after_perform(service_call)
      touch_on_custom_values_update
      notify_on_identifier_renamed
      send_update_notification
      update_wp_versions_on_parent_change
      persist_status

      service_call
    end

    def touch_on_custom_values_update
      model.touch if only_custom_values_updated?
    end

    def notify_on_identifier_renamed
      return unless memoized_changes['identifier']

      OpenProject::Notifications.send(OpenProject::Events::PROJECT_RENAMED, project: model)
    end

    def send_update_notification
      OpenProject::Notifications.send(OpenProject::Events::PROJECT_UPDATED, project: model)
    end

    def only_custom_values_updated?
      !model.saved_changes? && model.custom_values.any?(&:saved_changes?)
    end

    def update_wp_versions_on_parent_change
      return unless memoized_changes['parent_id']

      WorkPackage.update_versions_from_hierarchy_change(model)
    end

    def persist_status
      model.status.save if model.status.changed?
    end
  end
end
