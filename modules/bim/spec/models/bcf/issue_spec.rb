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

describe ::Bim::Bcf::Issue, type: :model do
  let(:type) { FactoryBot.create :type, name: "Issue [BCF]" }
  let(:work_package) { FactoryBot.create :work_package, type: type }
  let(:issue) { FactoryBot.create :bcf_issue, work_package: work_package }

  context '#markup_doc' do
    subject { issue }

    it "returns a Nokogiri::XML::Document" do
      expect(subject.markup_doc).to be_a Nokogiri::XML::Document
    end

    it "caches the document" do
      first_fetched_doc = subject.markup_doc
      expect(subject.markup_doc).to be_eql(first_fetched_doc)
    end

    it "invalidates the cache after an update of the issue" do
      first_fetched_doc = subject.markup_doc
      subject.markup = subject.markup + ' '
      subject.save
      expect(subject.markup_doc).to_not be_eql(first_fetched_doc)
    end
  end

  describe '.of_project' do
    let!(:other_work_package) { FactoryBot.create :work_package, type: type }
    let!(:other_issue) { FactoryBot.create :bcf_issue, work_package: other_work_package }

    it 'returns all issues of the provided project' do
      expect(described_class.of_project(issue.project))
        .to match_array [issue]
    end
  end
end
