import { getPlaylists } from '../utils/Api'
import { Playlist } from '../utils/Interface'
import createPlaylistBuilder from './dialogs/CreatePlaylist'

@Component
export default struct Playlists {
  @StorageLink('baseURL') baseURL: string = ''
  @StorageLink('username') username: string = ''
  @StorageLink('password') password: string = ''
  @Consume pageStack: NavPathStack
  @Consume startPlaying: boolean
  @Consume showSidebar: boolean
  @Consume playlists: Playlist[]
  @Consume playlist: Playlist | null
  createPlaylist: CustomDialogController = new CustomDialogController({
    builder: createPlaylistBuilder(),
    width: 340,
    height: 310,
    backgroundColor: $r('app.color.content_background')
  })

  build() {
    Column() {
      Row() {
        Image("")
        Text("歌单")
          .fontSize(20)
          .fontColor($r('app.color.font'))
      }
      .width('100%')
      .height(60)
      .backgroundColor($r('app.color.bar_background'))
      .justifyContent(FlexAlign.Center)

      Divider()
        .width('90%')
        .height(1)
        .color($r('app.color.divider'))

      List() {
        ForEach(this.playlists, (playlist: Playlist, index) => {
          ListItem() {
            Button({ type: ButtonType.Normal }) {
              Row() {
                Text(playlist.name)
                  .fontSize(19)
                  .fontColor($r('app.color.font'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%')
              .height('100%')
              .padding({ left: 20, right: 20 })
            }
            .width('100%')
            .height(50)
            .borderRadius(15)
            .backgroundColor('#00000000')
            .padding({ left: 20, right: 20 })
            .onClick(() => {
              animateTo({
                duration: 300,
                curve: Curve.EaseOut,
              }, () => {
                this.showSidebar = false
              })
              this.playlist = playlist
              this.pageStack.pushPathByName('PlaylistDetail', null);
            })
          }
        })
      }
      .width('100%')
      .height('100%')
      .layoutWeight(1)
      .listDirection(Axis.Vertical)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Fade)
      .visibility(this.playlists.length > 0 ? Visibility.Visible : Visibility.None)

      Column() {
        Text("没有歌单")
          .fontSize(19)
          .fontColor($r('app.color.font'))
      }
      .width('100%')
      .height('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .visibility(this.playlists.length > 0 ? Visibility.None : Visibility.Visible)

      Divider()
        .width('90%')
        .height(1)
        .color($r('app.color.divider'))

      Row() {
        Button({type:ButtonType.Normal}) {
          Text("新建")
            .fontSize(20)
            .fontColor($r('app.color.font'))
        }
        .width('90%')
        .height(50)
        .borderRadius(15)
        .backgroundColor($r('app.color.content_background'))
        .onClick(() => {
          animateTo({
            duration: 300,
            curve: Curve.EaseOut,
          }, () => {
            this.showSidebar = false
          })
          this.createPlaylist.open()
        })
      }
      .width('100%')
      .height(60)
      .backgroundColor($r('app.color.bar_background'))
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .onVisibleAreaChange(
      // Define thresholds: e.g., [0.0, 0.1, 0.9, 1.0] or just a single value
      // Using [0.01] triggers when it becomes even slightly visible
      [0.01],
      // Callback function
      async (isVisible: boolean, currentRatio: number) => {
        console.log(`PlaylistsComponent Visibility Changed: isVisible=${isVisible}, currentRatio=${currentRatio.toFixed(2)}`);
        // Check if component is becoming visible and data hasn't been loaded yet
        if (isVisible && currentRatio > 0) {
          // Call the data fetching function
          console.log('Loading remote playlists...')
          this.playlists = await getPlaylists(this.baseURL, this.username, this.password)
          console.log('Fetched')
        }
        // Note: We check 'this.hasLoaded' inside the fetch function too,
        // but checking here prevents unnecessary calls to the async function itself.
      }
    )
  }
}