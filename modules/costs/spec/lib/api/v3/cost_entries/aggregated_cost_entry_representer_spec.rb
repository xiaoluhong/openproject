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

describe ::API::V3::CostEntries::AggregatedCostEntryRepresenter do
  include API::V3::Utilities::PathHelper

  let(:cost_entry) { FactoryBot.build_stubbed(:cost_entry) }
  let(:representer) { described_class.new(cost_entry.cost_type, cost_entry.units) }

  subject { representer.to_json }

  it 'has a type' do
    is_expected.to be_json_eql('AggregatedCostEntry'.to_json).at_path('_type')
  end

  it_behaves_like 'has a titled link' do
    let(:link) { 'costType' }
    let(:href) { api_v3_paths.cost_type cost_entry.cost_type.id }
    let(:title) { cost_entry.cost_type.name }
  end

  it 'has spent units' do
    is_expected.to be_json_eql(cost_entry.units.to_json).at_path('spentUnits')
  end
end
