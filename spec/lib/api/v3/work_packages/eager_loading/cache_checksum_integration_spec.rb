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
#++require 'rspec'

require 'spec_helper'
require_relative './eager_loading_mock_wrapper'

describe ::API::V3::WorkPackages::EagerLoading::Checksum do
  let(:responsible) { FactoryBot.create(:user) }
  let(:assignee) { FactoryBot.create(:user) }
  let(:category) { FactoryBot.create(:category) }
  let(:version) { FactoryBot.create(:version) }
  let!(:work_package) do
    FactoryBot.create(:work_package,
                      responsible: responsible,
                      assigned_to: assignee,
                      version: version,
                      category: category)
  end
  let!(:type) { work_package.type }
  let!(:project) { work_package.project }

  describe '.apply' do
    let!(:orig_checksum) do
      EagerLoadingMockWrapper
        .wrap(described_class, [work_package])
        .first
        .cache_checksum
    end

    let(:new_checksum) do
      EagerLoadingMockWrapper
        .wrap(described_class, [work_package])
        .first
        .cache_checksum
    end

    it 'produces a different checksum on changes to the status id' do
      WorkPackage.where(id: work_package.id).update_all(status_id: 0)

      expect(new_checksum)
        .not_to eql orig_checksum
    end

    it 'produces a different checksum on changes to the status' do
      work_package.status.update_attribute(:updated_at, Time.now + 10.seconds)

      expect(new_checksum)
        .not_to eql orig_checksum
    end

    it 'produces a different checksum on changes to the author id' do
      WorkPackage.where(id: work_package.id).update_all(author_id: 0)

      expect(new_checksum)
        .not_to eql orig_checksum
    end

    it 'produces a different checksum on changes to the author' do
      work_package.author.update_attribute(:updated_on, Time.now + 10.seconds)

      expect(new_checksum)
        .not_to eql orig_checksum
    end

    it 'produces a different checksum on changes to the assigned_to id' do
      WorkPackage.where(id: work_package.id).update_all(assigned_to_id: 0)

      expect(new_checksum)
        .not_to eql orig_checksum
    end

    it 'produces a different checksum on changes to the assigned_to' do
      work_package.assigned_to.update_attribute(:updated_on, Time.now + 10.seconds)

      expect(new_checksum)
        .not_to eql orig_checksum
    end

    it 'produces a different checksum on changes to the responsible id' do
      WorkPackage.where(id: work_package.id).update_all(responsible_id: 0)

      expect(new_checksum)
        .not_to eql orig_checksum
    end

    it 'produces a different checksum on changes to the responsible' do
      work_package.responsible.update_attribute(:updated_on, Time.now + 10.seconds)

      expect(new_checksum)
        .not_to eql orig_checksum
    end

    it 'produces a different checksum on changes to the version id' do
      WorkPackage.where(id: work_package.id).update_all(version_id: 0)

      expect(new_checksum)
        .not_to eql orig_checksum
    end

    it 'produces a different checksum on changes to the version' do
      work_package.version.update_attribute(:updated_on, Time.now + 10.seconds)

      expect(new_checksum)
        .not_to eql orig_checksum
    end

    it 'produces a different checksum on changes to the type id' do
      WorkPackage.where(id: work_package.id).update_all(type_id: 0)

      expect(new_checksum)
        .not_to eql orig_checksum
    end

    it 'produces a different checksum on changes to the type' do
      work_package.type.update_attribute(:updated_at, Time.now + 10.seconds)

      expect(new_checksum)
        .not_to eql orig_checksum
    end

    it 'produces a different checksum on changes to the priority id' do
      WorkPackage.where(id: work_package.id).update_all(priority_id: 0)

      expect(new_checksum)
        .not_to eql orig_checksum
    end

    it 'produces a different checksum on changes to the priority' do
      work_package.priority.update_attribute(:updated_at, Time.now + 10.seconds)

      expect(new_checksum)
        .not_to eql orig_checksum
    end

    it 'produces a different checksum on changes to the category id' do
      WorkPackage.where(id: work_package.id).update_all(category_id: 0)

      expect(new_checksum)
        .not_to eql orig_checksum
    end

    it 'produces a different checksum on changes to the category' do
      work_package.category.update_attribute(:updated_at, Time.now + 10.seconds)

      expect(new_checksum)
        .not_to eql orig_checksum
    end
  end
end
