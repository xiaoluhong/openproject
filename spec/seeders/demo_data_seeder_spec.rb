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

require 'spec_helper'

def translate_with_base_url(string)
  I18n.t(string, deep_interpolation: true, base_url: OpenProject::Configuration.rails_relative_url_root)
end

describe 'seeds' do
  before do
    allow(OpenProject::Configuration).to receive(:[]).and_call_original
    allow(OpenProject::Configuration).to receive(:[]).with('edition').and_return(edition)
  end

  context 'standard edition' do
    let(:edition) { 'standard' }

    it 'create the demo data' do
      perform_deliveries = ActionMailer::Base.perform_deliveries
      ActionMailer::Base.perform_deliveries = false

      begin
        # Avoid asynchronous DeliverWorkPackageCreatedJob
        Delayed::Worker.delay_jobs = false

        expect { StandardSeeder::BasicDataSeeder.new.seed! }.not_to raise_error
        expect { AdminUserSeeder.new.seed! }.not_to raise_error
        expect { DemoDataSeeder.new.seed! }.not_to raise_error

        expect(User.where(admin: true).count).to eq 1
        expect(Project.count).to eq 2
        expect(WorkPackage.count).to eq 41
        expect(Wiki.count).to eq 2
        expect(Query.where.not(hidden: true).count).to eq 8
        expect(Query.count).to eq 24
        expect(Projects::Status.count).to eq 2
      ensure
        ActionMailer::Base.perform_deliveries = perform_deliveries
      end
    end
  end
end
