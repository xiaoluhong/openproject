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

import {NgModule} from '@angular/core';
import {OpenprojectCommonModule} from "core-app/modules/common/openproject-common.module";
import {Ng2StateDeclaration, UIRouter, UIRouterModule} from "@uirouter/angular";
import {OpenprojectGridsModule} from "core-app/modules/grids/openproject-grids.module";
import {OverviewComponent} from "core-app/modules/overview/overview.component";

const menuItemClass = 'overview-menu-item';

export const OVERVIEW_ROUTES:Ng2StateDeclaration[] = [
  {
    name: 'overview',
    parent: 'root',
    // The trailing slash is important
    // cf., https://community.openproject.com/wp/29754
    url: '/',
    data: {
      menuItem: menuItemClass
    },
    component: OverviewComponent
  }
];

export function uiRouterOverviewConfiguration(uiRouter:UIRouter) {
  // Ensure projects/:project_id/ are being redirected correctly
  // cf., https://community.openproject.com/wp/29754
  uiRouter.urlService.rules
    .when(
      new RegExp("^/projects(?!/new$)/([^/]+)$"),
      match => `/projects/${match[1]}/`
    );
}

@NgModule({
  imports: [
    OpenprojectCommonModule,

    OpenprojectGridsModule,

    UIRouterModule.forChild({
      states: OVERVIEW_ROUTES,
      config: uiRouterOverviewConfiguration
    }),
  ],
  providers: [
  ],
  declarations: [
    OverviewComponent
  ]
})
export class OpenprojectOverviewModule {
}

