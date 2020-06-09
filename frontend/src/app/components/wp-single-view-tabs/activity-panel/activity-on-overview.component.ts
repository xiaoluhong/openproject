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
import {ActivityPanelBaseController} from 'core-components/wp-single-view-tabs/activity-panel/activity-base.controller';
import {Component, Input} from '@angular/core';
import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {ActivityEntryInfo} from 'core-components/wp-single-view-tabs/activity-panel/activity-entry-info';
import {AngularTrackingHelpers} from "core-components/angular/tracking-functions";

@Component({
  selector: 'newest-activity-on-overview',
  templateUrl: './activity-on-overview.html'
})
export class NewestActivityOnOverviewComponent extends ActivityPanelBaseController {
  @Input('workPackage') public workPackage:WorkPackageResource;

  public latestActivityInfo:ActivityEntryInfo[] = [];
  public trackByHref = AngularTrackingHelpers.trackByHref;

  ngOnInit() {
    this.workPackageId = this.workPackage.id!;
    super.ngOnInit();
  }

  protected shouldShowToggler() {
    return false;
  }

  protected updateActivities(activities:any) {
    super.updateActivities(activities);
    this.latestActivityInfo = this.latestActivities();
  }

  private latestActivities(visible:number = 3) {

    if (this.reverse) {
      // In reverse, we already get reversed entries from API.
      // So simply take the first three
      let segment = this.unfilteredActivities.slice(0, visible);
      return segment.map((el:HalResource, i:number) => this.info(el, i));
    } else {
      // In ascending sort, take the last three items
      let segment = this.unfilteredActivities.slice(-visible);
      let startIndex = this.unfilteredActivities.length - segment.length;
      return segment.map((el:HalResource, i:number) => this.info(el, startIndex + i));
    }
  }
}
