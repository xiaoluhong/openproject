import {Injectable, Inject, Injector} from '@angular/core';
import {XeokitServer} from "core-app/modules/bim/ifc_models/xeokit/xeokit-server";
import {BcfViewpointInterface} from "core-app/modules/bim/bcf/api/viewpoints/bcf-viewpoint.interface";
import {ViewerBridgeService} from "core-app/modules/bim/bcf/bcf-viewer-bridge/viewer-bridge.service";
import {Observable, Subject} from "rxjs";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {BcfApiService} from "core-app/modules/bim/bcf/api/bcf-api.service";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";
import {ViewpointsService} from "core-app/modules/bim/bcf/helper/viewpoints.service";
import {of} from 'rxjs';


export interface XeokitElements {
  canvasElement:HTMLElement;
  explorerElement:HTMLElement;
  toolbarElement:HTMLElement;
  navCubeCanvasElement:HTMLElement;
  busyModelBackdropElement:HTMLElement;
}

export interface BCFCreationOptions {
  spacesVisible?:boolean;
  spaceBoundariesVisible?:boolean;
  openingsVisible?:boolean;
}

export interface BCFLoadOptions {
  rayCast?:boolean;
  immediate?:boolean;
  duration?:number;
}

@Injectable()
export class IFCViewerService extends ViewerBridgeService {
  @InjectField() pathHelper:PathHelperService;
  @InjectField() bcfApi:BcfApiService;
  @InjectField() viewpointsService:ViewpointsService;  

  private _viewer:any;

  // private _loaded:BehaviorSubject<boolean> = new BehaviorSubject(false);
  // readonly loaded$:Observable<boolean> = this._loaded.asObservable().pipe(shareReplay({refCount: true, bufferSize: 1}));

  private $loaded = new Subject<void>();

  constructor(readonly injector:Injector){
    super(injector);
  }

  public newViewer(elements:XeokitElements, projects:any[]) {
    import('@xeokit/xeokit-bim-viewer/dist/main').then((XeokitViewerModule:any) => {
      let server = new XeokitServer();
      let viewerUI = new XeokitViewerModule.BIMViewer(server, elements);

      viewerUI.on("queryPicked", (event:any) => {
        alert(`IFC Name = "${event.objectName}"\nIFC class = "${event.objectType}"\nIFC GUID = ${event.objectId}`);
      });

      viewerUI.on("modelLoaded", () => this.$loaded.complete());

      viewerUI.loadProject(projects[0]["id"]);

      this.viewer = viewerUI;
    });
  }

  public destroy() {
    this.$loaded.complete();

    if (!this.viewer) {
      return;
    }

    this.viewer.destroy();
    this.viewer = undefined;
  }

  public get viewer() {
    return this._viewer;
  }

  public set viewer(viewer:any) {
    this._viewer = viewer;
  }

  public setKeyboardEnabled(val:boolean) {
    this.viewer.setKeyboardEnabled(val);
  }

  public getViewpoint$():Observable<BcfViewpointInterface> {
    const viewpoint = this.viewer.saveBCFViewpoint({ spacesVisible: true });

    // The backend rejects viewpoints with bitmaps
    delete viewpoint.bitmaps;

    return of(viewpoint);
  }

  public showViewpoint(workPackage:WorkPackageResource, index:number) {
    // Avoid reload the app when there is a place to show the viewer
    // ('bim.partitioned.split')
    if (this.routeWithViewer) {
      if (this.viewer) {
        this.viewpointsService
              .getViewPoint$(workPackage, index)
              .subscribe(viewpoint => this.viewer.loadBCFViewpoint(viewpoint, {}));
      }
    } else {
      // Reload the whole app to get the correct menus and GON data
      // and redirect to a route with a place to show viewer
      // ('bim.partitioned.split')
      window.location.href = this.pathHelper.bimDetailsPath(
        workPackage.project.idFromLink,
        workPackage.id!,
        index
      );
    }
  }

  public viewerVisible():boolean {
    return !!this.viewer;
  }

  // TODO: Remove this?
  public onLoad$():Observable<void> {
    return this.$loaded;
  }
}