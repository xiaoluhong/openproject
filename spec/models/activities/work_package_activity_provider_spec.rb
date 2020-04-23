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

require 'spec_helper'

describe Activities::WorkPackageActivityProvider, type: :model do
  let(:event_scope)               { 'work_packages' }
  let(:work_package_edit_event)   { 'work_package-edit' }
  let(:work_package_closed_event) { 'work_package-closed' }

  let(:user) { FactoryBot.create :admin }
  let(:role) { FactoryBot.create :role }
  let(:status_closed) { FactoryBot.create :closed_status }
  let!(:work_package) { FactoryBot.create :work_package }
  let!(:workflow) do
    FactoryBot.create :workflow,
                      old_status: work_package.status,
                      new_status: status_closed,
                      type_id: work_package.type_id,
                      role: role
  end

  before do
    allow(ActionMailer::Base).to receive(:perform_deliveries).and_return(false)
  end

  describe '#event_type' do
    describe 'latest events' do
      context 'when a work package has been created' do
        let(:subject) do
          Activities::WorkPackageActivityProvider
            .find_events(event_scope, user, Date.yesterday, Date.tomorrow, {})
            .last
            .try :event_type
        end

        it { is_expected.to eq(work_package_edit_event) }
      end

      context 'should be selected and ordered correctly' do
        let!(:work_packages) { (1..20).map { (FactoryBot.create :work_package, author: user).id.to_s } }
        let(:subject) do
          Activities::WorkPackageActivityProvider
            .find_events(event_scope, user, Date.yesterday, Date.tomorrow, limit: 10)
            .map { |a| a.journable_id.to_s }
        end
        it { is_expected.to eq(work_packages.reverse.first(10)) }
      end

      context 'when a work package has been created and then closed' do
        let(:subject) do
          Activities::WorkPackageActivityProvider
            .find_events(event_scope, user, Date.yesterday, Date.tomorrow, limit: 10)
            .first
            .try :event_type
        end

        before do
          login_as(user)

          work_package.status = status_closed
          work_package.save!
        end

        it { is_expected.to eq(work_package_closed_event) }
      end
    end
  end
end
