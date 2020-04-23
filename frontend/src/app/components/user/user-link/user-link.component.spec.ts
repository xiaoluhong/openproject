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

import {UserLinkComponent} from './user-link.component';

import {async, ComponentFixture, TestBed} from '@angular/core/testing';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {UserResource} from '../../../modules/hal/resources/user-resource';
import {PathHelperService} from 'core-app/modules/common/path-helper/path-helper.service';

describe('UserLinkComponent component test', () => {
  const PathHelperStub = {
    userPath: (id:string) => `/users/${id}`
  };

  const I18nStub = {
    t: (key:string, args:any) => `Author: ${args.user}`
  };

  let app:UserLinkComponent;
  let fixture:ComponentFixture<UserLinkComponent>;
  let element:HTMLElement;
  let user:UserResource;

  beforeEach(async(() => {

    // noinspection JSIgnoredPromiseFromCall
    TestBed.configureTestingModule({
      declarations: [
        UserLinkComponent
      ],
      providers: [
        { provide: I18nService, useValue: I18nStub },
        { provide: PathHelperService, useValue: PathHelperStub },
      ]
    }).compileComponents();

    fixture = TestBed.createComponent(UserLinkComponent);
    app = fixture.debugElement.componentInstance;
    element = fixture.elementRef.nativeElement;
  }));

  describe('inner element', function() {
    describe('with the uer having the showUserPath attribute', function() {
      beforeEach(async(() => {
        user = {
          name: 'First Last',
          showUserPath: '/users/1'
        } as UserResource;

        app.user = user;
        fixture.detectChanges();
      }));

      it('should render an inner link with specified classes', function () {
        const link = element.querySelector('a')!;

        expect(link.textContent).toEqual('First Last');
        expect(link.getAttribute('title')).toEqual('Author: First Last');
        expect(link.getAttribute('href')).toEqual('/users/1');
      });
    });

    describe('with the user not having the showUserPath attribute', function() {
      beforeEach(async(() => {
        user = {
          name: 'First Last',
          showUserPath: null
        } as UserResource;

        app.user = user;
        fixture.detectChanges();
      }));

      it('renders only the name', function () {
        const link = element.querySelector('a');

        expect(link).toBeNull();
        expect(element.textContent).toEqual(' First Last ');
      });
    });
  });
});
