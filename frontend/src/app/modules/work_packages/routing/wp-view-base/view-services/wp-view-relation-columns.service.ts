// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See docs/COPYRIGHT.rdoc for more details.
// ++

import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {WorkPackageViewColumnsService} from './wp-view-columns.service';
import {WorkPackageViewBaseService} from './wp-view-base.service';
import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {HalResourceService} from 'core-app/modules/hal/services/hal-resource.service';
import {RelationResource} from 'core-app/modules/hal/resources/relation-resource';
import {WorkPackageViewRelationColumns} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-table-relation-columns";
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {WorkPackageCacheService} from "core-components/work-packages/work-package-cache.service";
import {RelationsStateValue, WorkPackageRelationsService} from "core-components/wp-relations/wp-relations.service";
import {Injectable} from "@angular/core";
import {
  QueryColumn,
  queryColumnTypes,
  RelationQueryColumn,
  TypeRelationQueryColumn
} from "core-components/wp-query/query-column";

export type RelationColumnType = 'toType'|'ofType';

@Injectable()
export class WorkPackageViewRelationColumnsService extends WorkPackageViewBaseService<WorkPackageViewRelationColumns> {
  constructor(public querySpace:IsolatedQuerySpace,
              public wpTableColumns:WorkPackageViewColumnsService,
              public halResourceService:HalResourceService,
              public wpCacheService:WorkPackageCacheService,
              public wpRelations:WorkPackageRelationsService) {
    super(querySpace);
  }

  public valueFromQuery(query:QueryResource):WorkPackageViewRelationColumns {
    // Take over current expanded values
    // which are not yet saved
    return this.current;
  }

  /**
   * Returns a subset of all relations that the user has currently expanded.
   *
   * @param workPackage
   * @param relation
   */
  public relationsToExtendFor(workPackage:WorkPackageResource,
                              relations:RelationsStateValue|undefined,
                              eachCallback:(relation:RelationResource, column:QueryColumn, type:RelationColumnType) => void) {
    // Only if any relation columns or stored expansion state exist
    if (!(this.wpTableColumns.hasRelationColumns() && this.lastUpdatedState.hasValue())) {
      return;
    }

    // Only if any relations exist for this work package
    if (_.isNil(relations)) {
      return;
    }

    // Only if the work package has anything expanded
    const expanded = this.getExpandFor(workPackage.id!);
    if (expanded === undefined) {
      return;
    }

    const column = this.wpTableColumns.findById(expanded)!;
    const type = this.relationColumnType(column);

    if (type !== null) {
      _.each(this.relationsForColumn(workPackage, relations, column),
        (relation) => eachCallback(relation, column, type));
    }
  }

  /**
   * Get the subset of relations for the work package that belong to this relation column
   *
   * @param workPackage A work package resource
   * @param relations The RelationStateValue of this work package
   * @param column The relation column to filter for
   * @return The filtered relations
   */
  public relationsForColumn(workPackage:WorkPackageResource, relations:RelationsStateValue|undefined, column:QueryColumn) {
    if (_.isNil(relations)) {
      return [];
    }

    // Get the type of TO work package
    const type = this.relationColumnType(column);
    if (type === 'toType') {
      const typeHref = (column as TypeRelationQueryColumn).type.href;

      return _.filter(relations, (relation:RelationResource) => {
        const denormalized = relation.denormalized(workPackage);
        const target = this.wpCacheService.state(denormalized.targetId).value;

        return _.get(target, 'type.href') === typeHref;
      });
    }

    // Get the relation types for OF relation columns
    if (type === 'ofType') {
      const relationType = (column as RelationQueryColumn).relationType;

      return _.filter(relations, (relation:RelationResource) => {
        return relation.denormalized(workPackage).relationType === relationType;
      });
    }

    return [];
  }

  public relationColumnType(column:QueryColumn):RelationColumnType|null {
    switch (column._type) {
      case queryColumnTypes.RELATION_TO_TYPE:
        return 'toType';
      case queryColumnTypes.RELATION_OF_TYPE:
        return 'ofType';
      default:
        return null;
    }
  }

  public getExpandFor(workPackageId:string):string|undefined {
    return this.current[workPackageId];
  }

  public setExpandFor(workPackageId:string, columnId:string) {
    const nextState = { ...this.current };
    nextState[workPackageId] = columnId;

    this.update(nextState);
  }

  public collapse(workPackageId:string) {
    const nextState = { ...this.current };
    delete nextState[workPackageId];

    this.update(nextState);
  }

  public get current():WorkPackageViewRelationColumns {
    return this.lastUpdatedState.getValueOr({});
  }
}

