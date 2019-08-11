#-- copyright
# OpenProject Backlogs Plugin
#
# Copyright (C)2013-2014 the OpenProject Foundation (OPF)
# Copyright (C)2011 Stephan Eckardt, Tim Felgentreff, Marnen Laibow-Koser, Sandro Munda
# Copyright (C)2010-2011 friflaj
# Copyright (C)2010 Maxime Guilbot, Andrew Vit, Joakim Kolsjö, ibussieres, Daniel Passos, Jason Vasquez, jpic, Emiliano Heyns
# Copyright (C)2009-2010 Mark Maglana
# Copyright (C)2009 Joe Heck, Nate Lowrie
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License version 3.
#
# OpenProject Backlogs is a derivative work based on ChiliProject Backlogs.
# The copyright follows:
# Copyright (C) 2010-2011 - Emiliano Heyns, Mark Maglana, friflaj
# Copyright (C) 2011 - Jens Ulferts, Gregor Schmidt - Finn GmbH - Berlin, Germany
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require_dependency 'work_package'

module OpenProject::Backlogs::Patches::WorkPackagePatch
  def self.included(base)
    base.class_eval do
      prepend InstanceMethods
      extend ClassMethods

      before_validation :backlogs_before_validation, if: lambda { backlogs_enabled? }

      register_on_journal_formatter(:fraction, 'remaining_hours')
      register_on_journal_formatter(:decimal, 'story_points')
      register_on_journal_formatter(:decimal, 'position')

      validates_numericality_of :story_points, only_integer:            true,
                                               allow_nil:               true,
                                               greater_than_or_equal_to: 0,
                                               less_than:               10_000,
                                               if: lambda { backlogs_enabled? }

      validates_numericality_of :remaining_hours, only_integer: false,
                                                  allow_nil: true,
                                                  greater_than_or_equal_to: 0,
                                                  if: lambda { backlogs_enabled? }

      include OpenProject::Backlogs::List
    end
  end

  module ClassMethods
    def backlogs_types
      # Unfortunately, this is not cachable so the following line would be wrong
      # @backlogs_types ||= Story.types << Task.type
      # Caching like in the line above would prevent the types selected
      # for backlogs to be changed without restarting all app server.
      (Story.types << Task.type).compact
    end

    def children_of(ids)
      includes(:parent_relation)
        .where(relations: { from_id: ids })
    end

    # Prevent problems with subclasses of WorkPackage
    # not having a TypedDag configuration
    def _dag_options
      TypedDag::Configuration[WorkPackage]
    end
  end

  module InstanceMethods
    def done?
      project.done_statuses.to_a.include?(status)
    end

    def to_story
      Story.find(id) if is_story?
    end

    def is_story?
      backlogs_enabled? && Story.types.include?(type_id)
    end

    def to_task
      Task.find(id) if is_task?
    end

    def is_task?
      backlogs_enabled? && (parent_id && type_id == Task.type && Task.type.present?)
    end

    def is_impediment?
      backlogs_enabled? && (parent_id.nil? && type_id == Task.type && Task.type.present?)
    end

    def types
      case
      when is_story?
        Story.types
      when is_task?
        Task.types
      else
        []
      end
    end

    def story
      if self.is_story?
        return Story.find(id)
      elsif self.is_task?
        # Make sure to get the closest ancestor that is a Story, i.e. the one with the highest lft
        # otherwise, the highest parent that is a Story is returned
        story_work_package = ancestors.find_by(type_id: Story.types).order(Arel.sql('lft DESC'))
        return Story.find(story_work_package.id) if story_work_package
      end
      nil
    end

    def blocks
      # return work_packages that I block that aren't closed
      return [] if closed?
      blocks_relations.includes(:to).merge(WorkPackage.with_status_open).map(&:to)
    end

    def blockers
      # return work_packages that block me
      return [] if closed?
      blocked_by_relations.includes(:from).merge(WorkPackage.with_status_open).map(&:from)
    end

    def backlogs_enabled?
      !!project.try(:module_enabled?, 'backlogs')
    end

    def in_backlogs_type?
      backlogs_enabled? && WorkPackage.backlogs_types.include?(type.try(:id))
    end

    private

    def backlogs_before_validation
      if type_id == Task.type
        self.estimated_hours = remaining_hours if estimated_hours.blank? && !remaining_hours.blank?
        self.remaining_hours = estimated_hours if remaining_hours.blank? && !estimated_hours.blank?
      end
    end
  end
end

WorkPackage.send(:include, OpenProject::Backlogs::Patches::WorkPackagePatch)
