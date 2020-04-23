//-- copyright
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
//++

import {Component, Input, OnInit, Output} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {QueryFilterInstanceResource} from 'core-app/modules/hal/resources/query-filter-instance-resource';
import {DebouncedEventEmitter} from 'core-components/angular/debounced-event-emitter';
import {TimezoneService} from 'core-components/datetime/timezone.service';
import {Moment} from 'moment';
import {AbstractDateTimeValueController} from '../abstract-filter-date-time-value/abstract-filter-date-time-value.controller';
import {componentDestroyed} from "@w11k/ngx-componentdestroyed";

@Component({
  selector: 'filter-date-time-value',
  templateUrl: './filter-date-time-value.component.html'
})
export class FilterDateTimeValueComponent extends AbstractDateTimeValueController implements OnInit {
  @Input() public shouldFocus:boolean = false;
  @Input() public filter:QueryFilterInstanceResource;
  @Output() public filterChanged = new DebouncedEventEmitter<QueryFilterInstanceResource>(componentDestroyed(this));

  constructor(readonly I18n:I18nService,
              readonly timezoneService:TimezoneService) {
    super(I18n, timezoneService);
  }

  public get value():HalResource|string {
    return this.filter.values[0];
  }

  public get valueString() {
    return this.filter.values[0].toString();
  }

  public set value(val) {
    this.filter.values = [val as string];
    this.filterChanged.emit(this.filter);
  }

  public get lowerBoundary():Moment|null {
    if (this.value && this.timezoneService.isValidISODateTime(this.valueString)) {
      return this.timezoneService.parseDatetime(this.valueString);
    }

    return null;
  }

  public get upperBoundary():Moment|null {
    if (this.value && this.timezoneService.isValidISODateTime(this.valueString)) {
      return this.timezoneService.parseDatetime(this.valueString).add(24, 'hours');
    }

    return null;
  }
}
