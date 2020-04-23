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

describe Attachment, type: :model do
  let(:stubbed_author) { FactoryBot.build_stubbed(:user) }
  let(:author) { FactoryBot.create :user }
  let(:long_description) { 'a' * 300 }
  let(:work_package) { FactoryBot.create :work_package }
  let(:stubbed_work_package) { FactoryBot.build_stubbed :stubbed_work_package }
  let(:file) { FactoryBot.create :uploaded_jpg, name: 'test.jpg' }
  let(:second_file) { FactoryBot.create :uploaded_jpg, name: 'test2.jpg' }
  let(:container) { stubbed_work_package }

  let(:attachment) do
    FactoryBot.build(
      :attachment,
      author:       author,
      container:    container,
      content_type: nil, # so that it is detected
      file:         file
    )
  end
  let(:stubbed_attachment) do
    FactoryBot.build_stubbed(
      :attachment,
      author:       stubbed_author,
      container:    container
    )
  end

  describe 'validations' do
    it 'is valid' do
      expect(stubbed_attachment)
        .to be_valid
    end

    context 'with a long description' do
      before do
        stubbed_attachment.description = long_description
        stubbed_attachment.valid?
      end

      it 'raises an error regarding description length' do
        expect(stubbed_attachment.errors[:description])
          .to match_array [I18n.t('activerecord.errors.messages.too_long', count: 255)]
      end
    end

    context 'without a container' do
      let(:container) { nil }

      it 'is valid' do
        expect(stubbed_attachment)
          .to be_valid
      end
    end

    context 'without a container first and then setting a container' do
      let(:container) { nil }

      before do
        stubbed_attachment.container = work_package
      end

      it 'is valid' do
        expect(stubbed_attachment)
          .to be_valid
      end
    end

    context 'with a container first and then removing the container' do
      before do
        stubbed_attachment.container = nil
      end

      it 'notes the field as unchangeable' do
        stubbed_attachment.valid?

        expect(stubbed_attachment.errors.symbols_for(:container))
          .to match_array [:unchangeable]
      end
    end

    context 'with a container first and then changing the container_id' do
      before do
        stubbed_attachment.container_id = stubbed_attachment.container_id + 1
      end

      it 'notes the field as unchangeable' do
        stubbed_attachment.valid?

        expect(stubbed_attachment.errors.symbols_for(:container))
          .to match_array [:unchangeable]
      end
    end

    context 'with a container first and then changing the container_type' do
      before do
        stubbed_attachment.container_type = 'WikiPage'
      end

      it 'notes the field as unchangeable' do
        stubbed_attachment.valid?

        expect(stubbed_attachment.errors.symbols_for(:container))
          .to match_array [:unchangeable]
      end
    end
  end

  describe '#containered?' do
    it 'is false if the attachment has no container' do
      stubbed_attachment.container = nil

      expect(stubbed_attachment)
        .not_to be_containered
    end

    it 'is true if the attachment has a container' do
      expect(stubbed_attachment)
        .to be_containered
    end
  end

  describe 'create' do
    it('creates a jpg file called test') do
      expect(File.exists?(attachment.diskfile.path)).to eq true
    end

    it('has the content type "image/jpeg"') do
      expect(attachment.content_type).to eq 'image/jpeg'
    end

    context 'with wrong content-type' do
      let(:file) { FactoryBot.create :uploaded_jpg, content_type: 'text/html' }

      it 'detects the correct content-type' do
        expect(attachment.content_type).to eq 'image/jpeg'
      end
    end

    it 'has the correct filesize' do
      expect(attachment.filesize)
        .to eql file.size
    end

    it 'creates an md5 digest' do
      expect(attachment.digest)
        .to eql Digest::MD5.file(file.path).hexdigest
    end

    it 'adds no cleanup job' do
      expect(Attachments::CleanupUncontaineredJob).not_to receive(:perform_later)

      attachment.save!
    end

    context 'with an unclaimed attachment' do
      let(:container) { nil }

      it 'adds a cleanup job' do
        expect(Attachments::CleanupUncontaineredJob).to receive(:perform_later)
        attachment.save!
      end
    end
  end

  describe 'two attachments with same file name' do
    let(:second_file) { FactoryBot.create :uploaded_jpg, name: file.original_filename }
    it 'does not interfere' do
      a1 = Attachment.create!(container: work_package,
                              file: file,
                              author: author)
      a2 = Attachment.create!(container: work_package,
                              file: second_file,
                              author: author)

      expect(a1.diskfile.path)
        .not_to eql a2.diskfile.path
    end
  end

  ##
  # The tests assumes the default, file-based storage is configured and tests against that.
  # I.e. it does not test fog attachments being deleted from the cloud storage (such as S3).
  describe '#destroy' do
    before do
      attachment.save!

      expect(File.exists?(attachment.file.path)).to eq true

      attachment.destroy
      attachment.run_callbacks(:commit)
      # triggering after_commit callbacks manually as they are not triggered during rspec runs
      # though in dev/production mode destroy does trigger these callbacks
    end

    it "deletes the attachment's file" do
      expect(File.exists?(attachment.file.path)).to eq false
    end
  end

  describe "#external_url" do
    let(:author) { FactoryBot.create :user }

    let(:image_path) { Rails.root.join("spec/fixtures/files/image.png") }
    let(:text_path) { Rails.root.join("spec/fixtures/files/testfile.txt") }
    let(:binary_path) { Rails.root.join("spec/fixtures/files/textfile.txt.gz") }

    let(:fog_attachment_class) do
      class FogAttachment < Attachment
        # Remounting the uploader overrides the original file setter taking care of setting,
        # among other things, the content type. So we have to restore that original
        # method this way.
        # We do this in a new, separate class, as to not interfere with any other specs.
        alias_method :set_file, :file=
        mount_uploader :file, FogFileUploader
        alias_method :file=, :set_file
      end

      FogAttachment
    end

    let(:image_attachment) { fog_attachment_class.new author: author, file: File.open(image_path) }
    let(:text_attachment) { fog_attachment_class.new author: author, file: File.open(text_path) }
    let(:binary_attachment) { fog_attachment_class.new author: author, file: File.open(binary_path) }

    before do
      Fog.mock!

      connection = Fog::Storage.new provider: "AWS"
      connection.directories.create key: "my-bucket"

      CarrierWave::Configuration.configure_fog! credentials: {}, directory: "my-bucket", public: false
    end

    shared_examples "it has a temporary download link" do
      let(:url_options) { {} }
      let(:query) { attachment.external_url(url_options).to_s.split("?").last }

      it "should have a default expiry time" do
        expect(query).to include "X-Amz-Expires="
        expect(query).not_to include "X-Amz-Expires=3600"
      end

      context "with a custom expiry time" do
        let(:url_options) { { expires_in: 1.hour } }

        it "should use that time" do
          expect(query).to include "X-Amz-Expires=3600"
        end
      end

      context 'with expiry time exeeding maximum' do
        let(:url_options) { { expires_in: 1.year } }

        it "uses the allowed max" do
          expect(query).to include "X-Amz-Expires=604799"
        end
      end
    end

    describe "for an image file" do
      before { image_attachment.save! }

      it "should make S3 use content_disposition inline" do
        expect(image_attachment.content_disposition).to eq "inline"
        expect(image_attachment.external_url.to_s).to include "response-content-disposition=inline"
      end

      # this is independent from the type of file uploaded so we just test this for the first one
      it_behaves_like "it has a temporary download link" do
        let(:attachment) { image_attachment }
      end
    end

    describe "for a text file" do
      before { text_attachment.save! }

      it "should make S3 use content_disposition inline" do
        expect(text_attachment.content_disposition).to eq "inline"
        expect(text_attachment.external_url.to_s).to include "response-content-disposition=inline"
      end
    end

    describe "for a binary file" do
      before { binary_attachment.save! }

      it "should make S3 use content_disposition 'attachment; filename=...'" do
        expect(binary_attachment.content_disposition).to eq "attachment"
        expect(binary_attachment.external_url.to_s).to include "response-content-disposition=attachment"
      end
    end
  end

  describe 'full text extraction job on commit' do
    let(:created_attachment) do
      FactoryBot.create(:attachment,
                        author: author,
                        container: container)
    end

    shared_examples_for 'runs extraction' do
      it 'runs extraction' do
        extraction_with_id = nil

        allow(ExtractFulltextJob)
          .to receive(:perform_later) do |id|
          extraction_with_id = id
        end

        attachment.save

        expect(extraction_with_id).to eql attachment.id
      end
    end

    shared_examples_for 'does not run extraction' do
      it 'does not run extraction' do
        created_attachment

        expect(ExtractFulltextJob)
          .not_to receive(:perform_later)

        created_attachment.save
      end
    end

    context 'for a work package' do
      let(:work_package) { FactoryBot.create(:work_package) }
      let(:container) { work_package }

      context 'on create' do
        it_behaves_like 'runs extraction'
      end

      context 'on update' do
        it_behaves_like 'does not run extraction'
      end
    end

    context 'for a wiki page' do
      let(:wiki_page) { FactoryBot.create(:wiki_page) }
      let(:container) { wiki_page }

      context 'on create' do
        it_behaves_like 'does not run extraction'
      end

      context 'on update' do
        it_behaves_like 'does not run extraction'
      end
    end

    context 'without a container' do
      let(:container) { nil }

      context 'on create' do
        it_behaves_like 'runs extraction'
      end

      context 'on update' do
        it_behaves_like 'does not run extraction'
      end
    end
  end
end
