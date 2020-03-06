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

require_relative '../../support/pages/ifc_models/show_default'

describe 'Show viewpoint in model viewer', type: :feature, js: true do
  let(:project) { FactoryBot.create :project, enabled_module_names: [:bim, :work_package_tracking] }
  let(:user) { FactoryBot.create :admin }

  let!(:work_package) { FactoryBot.create(:work_package, project: project) }
  let!(:bcf) { FactoryBot.create :bcf_issue, work_package: work_package }
  let!(:viewpoint) { FactoryBot.create :bcf_viewpoint, issue: bcf, viewpoint_name: 'minimal_hidden_except_one' }

  let!(:model) do
    FactoryBot.create(:ifc_model_minimal_converted,
                      title: 'minimal',
                      project: project,
                      uploader: user)
  end

  let(:show_model_page) { Pages::IfcModels::ShowDefault.new(project) }
  let(:card_view) { ::Pages::WorkPackageCards.new(project) }

  before do
    login_as(user)
    show_model_page.visit!
    show_model_page.finished_loading
  end

  it 'loads the viewpoint in the viewer when clicking on the wp card' do
    card_view.expect_work_package_listed work_package
    card_view.select_work_package work_package

    card_view.expect_work_package_selected work_package, true

    # Idea: Check whether the storeys are correctly set and thus the viewpoint correctly loaded
    # For convenience only, our viewpoint selected nothing, so no Storey should be selected
    show_model_page.select_sidebar_tab 'Objects'
    show_model_page.expand_tree
    show_model_page.expect_checked 'minimal'
    show_model_page.all_checkboxes.each do |label, checkbox|
      if label.text == 'minimal' || label.text == 'LUB_Segment_new:S_WHG_Ess:7243035'
        expect(checkbox.checked?).to eq(true)
      else
        expect(checkbox.checked?).to eq(false)
      end
    end
  end
end
