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

import {Injector, NgModule} from '@angular/core';
import {OpenprojectCommonModule} from "core-app/modules/common/openproject-common.module";
import {NgxGalleryModule} from "@kolkov/ngx-gallery";
import {DisplayFieldService} from "core-app/modules/fields/display/display-field.service";
import {BcfThumbnailDisplayField} from "core-app/modules/bim/bcf/fields/display/bcf-thumbnail-field.module";
import {HTTP_INTERCEPTORS} from "@angular/common/http";
import {OpenProjectHeaderInterceptor} from "core-app/modules/hal/http/openproject-header-interceptor";
import {BcfDetectorService} from "core-app/modules/bim/bcf/helper/bcf-detector.service";
import {BcfPathHelperService} from "core-app/modules/bim/bcf/helper/bcf-path-helper.service";
import {BcfImportButtonComponent} from "core-app/modules/bim/ifc_models/toolbar/import-export-bcf/bcf-import-button.component";
import {BcfExportButtonComponent} from "core-app/modules/bim/ifc_models/toolbar/import-export-bcf/bcf-export-button.component";
import {RevitBridgeService} from "core-app/modules/bim/bcf/bcf-viewer-bridge/revit-bridge.service";
import {IFCViewerService} from "core-app/modules/bim/ifc_models/ifc-viewer/ifc-viewer.service";
import {ViewerBridgeService} from "core-app/modules/bim/bcf/bcf-viewer-bridge/viewer-bridge.service";
import {HookService} from "core-app/modules/plugins/hook-service";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {BcfWpAttributeGroupComponent} from "core-app/modules/bim/bcf/bcf-wp-attribute-group/bcf-wp-attribute-group.component";
import {BcfNewWpAttributeGroupComponent} from "core-app/modules/bim/bcf/bcf-wp-attribute-group/bcf-new-wp-attribute-group.component";

/**
 * Determines based on the current user agent whether
 * we're running in Revit or not.
 *
 * Depending on that, we use the IFC viewer service for showing/saving viewpoints.
 */
export const viewerBridgeServiceFactory = (injector:Injector) => {
  if (window.navigator.userAgent.search('Revit') > -1) {
    return new RevitBridgeService();
  } else {
    return injector.get(IFCViewerService, new IFCViewerService());
  }
};

@NgModule({
  imports: [
    OpenprojectCommonModule,
    NgxGalleryModule,
  ],
  providers: [
    { provide: HTTP_INTERCEPTORS, useClass: OpenProjectHeaderInterceptor, multi: true },
    {
      provide: ViewerBridgeService,
      useFactory: viewerBridgeServiceFactory,
      deps: [Injector]
    },
    BcfDetectorService,
    BcfPathHelperService
  ],
  declarations: [
    BcfWpAttributeGroupComponent,
    BcfNewWpAttributeGroupComponent,
    BcfImportButtonComponent,
    BcfExportButtonComponent,
  ],
  exports: [
    BcfImportButtonComponent,
    BcfExportButtonComponent,
  ]
})
export class OpenprojectBcfModule {
  static bootstrapCalled = false;

  constructor(injector:Injector) {
    OpenprojectBcfModule.bootstrap(injector);
  }

  // The static property prevents running the function
  // multiple times. This happens e.g. when the module is included
  // into a plugin's module.
  public static bootstrap(injector:Injector) {
    if (this.bootstrapCalled) {
      return;
    }

    this.bootstrapCalled = true;

    const displayFieldService = injector.get(DisplayFieldService);
    displayFieldService
      .addFieldType(BcfThumbnailDisplayField, 'bcfThumbnail', [
        'BCF Thumbnail'
      ]);


    const hookService = injector.get(HookService);
    hookService.register('prependedAttributeGroups', (workPackage:WorkPackageResource) => {
      if (!window.OpenProject.isBimEdition) {
        return;
      }

      if (workPackage.isNew) {
        return BcfNewWpAttributeGroupComponent;
      } else {
        return BcfWpAttributeGroupComponent;
      }
    });
  }
}

