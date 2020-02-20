import {Component} from "@angular/core";
import {BoardCacheService} from "core-app/modules/boards/board/board-cache.service";

@Component({
  selector: 'boards-entry',
  template: '<router-outlet></router-outlet>',
  providers: [
    BoardCacheService
  ]
})
export class BoardsRootComponent {
}
