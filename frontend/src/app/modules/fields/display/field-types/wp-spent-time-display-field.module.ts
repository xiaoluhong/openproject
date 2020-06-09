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

import { DurationDisplayField } from './duration-display-field.module';
import { PathHelperService } from 'core-app/modules/common/path-helper/path-helper.service';
import { ProjectCacheService } from "core-components/projects/project-cache.service";
import { ProjectResource } from "core-app/modules/hal/resources/project-resource";
import { InjectField } from "core-app/helpers/angular/inject-field.decorator";
import * as URI from 'urijs';
import { TimeEntryCreateService } from 'core-app/modules/time_entries/create/create.service';
import { WorkPackageResource } from "core-app/modules/hal/resources/work-package-resource";

export class WorkPackageSpentTimeDisplayField extends DurationDisplayField {
  public text = {
    linkTitle: this.I18n.t('js.work_packages.message_view_spent_time'),
    logTime: this.I18n.t('js.button_log_time')
  };

  @InjectField() PathHelper:PathHelperService;
  @InjectField() projectCacheService:ProjectCacheService;
  @InjectField() timeEntryCreateService:TimeEntryCreateService;

  public render(element:HTMLElement, displayText:string):void {
    if (!this.value) {
      return;
    }

    const link = document.createElement('a');
    link.textContent = displayText;
    link.setAttribute('title', this.text.linkTitle);
    link.setAttribute('class', 'time-logging--value');

    if (this.resource.project) {
      const wpID = this.resource.id.toString();
      this.projectCacheService
        .require(this.resource.project.idFromLink)
        .then((project:ProjectResource) => {
          const href = URI(this.PathHelper.projectTimeEntriesPath(project.identifier))
            .search({ work_package_id: wpID })
            .toString();

          link.href = href;
        });
    }

    element.innerHTML = '';
    element.appendChild(link);

    this.appendTimelogLink(element);
  }

  private appendTimelogLink(element:HTMLElement) {
    if (this.resource.logTime) {
      const timelogElement = document.createElement('a');
      timelogElement.setAttribute('class', 'icon icon-time');
      timelogElement.setAttribute('href', '');
      timelogElement.textContent = this.text.logTime;

      element.appendChild(timelogElement);

      timelogElement.addEventListener('click', this.showTimelogWidget.bind(this, this.resource));
    }
  }

  private showTimelogWidget(wp:WorkPackageResource) {
    this.timeEntryCreateService
      .create(moment(new Date()), wp, false)
      .catch(() => {
        // do nothing, the user closed without changes
      });
  }
}
