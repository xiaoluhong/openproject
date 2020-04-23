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

#-- encoding: UTF-8

# This file is part of the acts_as_journalized plugin for the redMine
# project management software
#
# Copyright (C) 2010  Finn GmbH, http://finn.de
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either journal 2
# of the License, or (at your option) any later journal.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require 'journal_changes'
require 'journal_formatter'
Dir[File.expand_path('../redmine/acts/journalized/*.rb', __FILE__)].each { |f| require f }
Dir[File.expand_path('../acts/journalized/*.rb', __FILE__)].each { |f| require f }

module Redmine
  module Acts
    module Journalized
      def self.included(base)
        base.extend ClassMethods
        base.extend Journalized
      end

      module ClassMethods
        def plural_name
          name.underscore.pluralize
        end

        # This call will add an activity and, if neccessary, start the journaling and
        # add an event callback on the model.
        # Versioning and acting as an Event may only be applied once.
        # To apply more than on activity, use acts_as_activity
        def acts_as_journalized(options = {}, &block)
          return if journaled?

          include_aaj_modules

          journal_hash = prepare_journaled_options(options)

          has_many :journals, -> {
            order("#{Journal.table_name}.version ASC")
          }, journal_hash, &block
        end

        private

        def include_aaj_modules
          include Options
          include Creation
          include Reversion
          include Permissions
          include SaveHooks
          include FormatHooks

          # FIXME: When the transition to the new API is complete, remove me
          include Deprecated
        end
      end
    end
  end
end
