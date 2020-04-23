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

import {Moment} from 'moment';
import {QueryFilterInstanceResource} from 'core-app/modules/hal/resources/query-filter-instance-resource';
import {TimezoneService} from 'core-components/datetime/timezone.service';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {OnInit} from '@angular/core';
import {UntilDestroyedMixin} from "core-app/helpers/angular/until-destroyed.mixin";

export abstract class AbstractDateTimeValueController extends UntilDestroyedMixin implements OnInit {
  public filter:QueryFilterInstanceResource;

  constructor(protected I18n:I18nService,
              protected timezoneService:TimezoneService) {
    super();
  }

  ngOnInit() {
    _.remove(this.filter.values as string[], value => !this.timezoneService.isValidISODateTime(value));
  }

  public abstract get lowerBoundary():Moment|null;

  public abstract get upperBoundary():Moment|null;

  public isoDateParser(data:any) {
    if (!this.timezoneService.isValidISODate(data)) {
      return '';
    }
    var d = this.timezoneService.parseISODatetime(data);
    return this.timezoneService.formattedISODateTime(d);
  }

  public isoDateFormatter(data:any) {
    if (!this.timezoneService.isValidISODateTime(data)) {
      return '';
    }
    var d = this.timezoneService.parseISODatetime(data);
    return this.timezoneService.formattedISODate(d);
  }

  public get isTimeZoneDifferent() {
    let value = this.lowerBoundary || this.upperBoundary;

    if (!value) {
      return false;
    } else {
      return value.hours() !== 0 || value.minutes() !== 0;
    }
  }

  public get timeZoneText() {
    if (this.lowerBoundary && this.upperBoundary) {
      return this.I18n.t('js.filter.time_zone_converted.two_values',
        {
          from: this.lowerBoundary.format('YYYY-MM-DD HH:mm'),
          to: this.upperBoundary.format('YYYY-MM-DD HH:mm')
        });
    } else if (this.upperBoundary) {
      return this.I18n.t('js.filter.time_zone_converted.only_end',
        { to: this.upperBoundary.format('YYYY-MM-DD HH:mm') });

    } else if (this.lowerBoundary) {
      return this.I18n.t('js.filter.time_zone_converted.only_start',
        { from: this.lowerBoundary.format('YYYY-MM-DD HH:mm') });

    }

    return '';
  }
}
