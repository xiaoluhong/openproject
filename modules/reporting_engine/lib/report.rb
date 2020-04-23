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

class Report < ApplicationRecord
  extend Forwardable
  include Enumerable
  include Engine

  belongs_to :user
  belongs_to :project

  before_save :serialize
  serialize :serialized, Hash

  self.abstract_class = true # lets have subclasses have their own SQL tables

  def self.accepted_properties
    @@accepted_properties ||= []
  end

  def self.reporting_connection
    connection
  end

  def self.chain_initializer
    @chain_initializer ||= []
  end

  def self.deserialize(hash, object = new)
    object.tap do |q|
      hash[:filters].each { |name, opts| q.filter(name, opts) }
      hash[:group_bys].each { |name, opts| q.group_by(name, opts) }
    end
  end

  def serialize
    # have to take the reverse group_bys to retain the original order when deserializing
    self.serialized = { filters: (filters.map(&:serialize).reject(&:nil?).sort { |a, b| a.first <=> b.first }),
                        group_bys: group_bys.map(&:serialize).reject(&:nil?).reverse }
  end

  def deserialize
    unless @chain
      hash = serialized || serialize
      self.class.deserialize(hash, self)
    else
      raise ArgumentError, 'Cannot deserialize a report which already has a chain'
    end
  end

  # Convenience method to generate a params hash readable by Controller#determine_settings
  def to_params
    params = {}
    filters.select { |f| f.class.display? }.each do |f|
      filter_name = f.class.underscore_name
      params[:fields] << filter_name
      params[:operators].merge! filter_name => f.operator.to_s
      params[:values].merge! filter_name => f.values
    end
    group_bys.each do |g|
      params[:groups] ||= { rows: [], columns: [] }
      params[:groups][g.row? ? :rows : :columns] << g.class.underscore_name
    end
    params
  end

  ##
  # Migrates this report to look like the given report.
  # This may be used to alter report properties without
  # creating a new report in a database.
  def migrate(report)
    [:@chain, :@query, :@transformer, :@walker, :@table, :@depths, :@chain_initializer].each do |inst_var|
      instance_variable_set inst_var, (report.instance_variable_get inst_var)
    end
  end

  def available_filters
    self.class::Filter.all
  end

  def transformer
    @transformer ||= self.class::Transformer.new self
  end

  def walker
    @walker ||= self.class::Walker.new self
  end

  def add_chain(type, name, options)
    chain type.const_get(name.to_s.camelcase), options
    @transformer, @table, @depths, @walker = nil, nil, nil, nil
    self
  end

  def chain(klass = nil, options = {})
    build_new_chain unless @chain
    if klass
      @chain = klass.new @chain, options
      @chain.engine = self.class
    end
    @chain = @chain.parent until @chain.top?
    @chain
  end

  def build_new_chain
    # FIXME: is there a better way to load all filter and groups?
    self.class::Filter.all && self.class::GroupBy.all

    minimal_chain!
    self.class.chain_initializer.each { |block| block.call self }
    self
  end

  def filter(name, options = {})
    add_chain self.class::Filter, name, options
  end

  def group_by(name, options = {})
    add_chain self.class::GroupBy, name, options.reverse_merge(type: :column)
  end

  def column(name, options = {})
    group_by name, options.merge(type: :column)
  end

  def row(name, options = {})
    group_by name, options.merge(type: :row)
  end

  def table
    @table = self.class::Table.new(self)
  end

  def group_bys(type = nil)
    chain.select { |c| c.group_by? && (type.nil? || c.type == type) }
  end

  def filters
    chain.select(&:filter?)
  end

  def depth_of(name)
    @depths ||= {}
    @depths[name] ||= chain.inject(0) { |sum, child| child.type == name ? sum + 1 : sum }
  end

  def_delegators :transformer, :column_first, :row_first
  def_delegators :chain, :empty_chain, :top, :bottom, :chain_collect, :sql_statement, :all_group_fields, :child, :clear, :result
  def_delegators :result, :each_direct_result, :recursive_each, :recursive_each_with_level, :each, :each_row, :count,
                 :units, :final_number
  def_delegators :table, :row_index, :colum_index

  def to_a
    chain.to_a
  end

  def to_s
    chain.to_s
  end

  def size
    size = 0
    recursive_each { |r| size += r.size }
    size
  end

  def cache_key
    deserialize unless @chain
    parts = [self.class.table_name.sub('_reports', '')]
    parts.concat [filters.sort, group_bys].map { |l| l.map(&:cache_key).join(' ') }
    parts.join '/'
  end

  def self.engine
    self
  end

  def minimal_chain!
    @chain = self.class::Filter::NoFilter.new
  end

  def public!
    self.is_public = true
  end

  def public?
    is_public
  end

  def private!
    self.is_public = false
  end

  def private?
    !public?
  end
end
