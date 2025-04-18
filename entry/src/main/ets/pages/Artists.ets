import { Artist } from '../utils/Interface'
import { curves } from '@kit.ArkUI'
import { getIndexes } from '../utils/Api'
import { GenericLazyDataSource } from '../data/GenericLazyDataSource'

@Component
export default struct Artists {
  @StorageLink('baseURL') baseURL: string = ''
  @StorageLink('username') username: string = ''
  @StorageLink('password') password: string = ''
  @Consume salt: string
  @Consume version: string
  @Consume client: string
  @Consume auth: string
  @Consume getCoverUrl: string
  // @Consume artists: Artist[]
  @Consume pageStack: NavPathStack
  @Consume startPlaying: boolean
  @Consume showSidebar: boolean
  @Consume artist: Artist | null
  @Consume serverStatus: boolean
  @Consume displayWidth: number
  @Consume showProgress: boolean
  @State profileSize: number = 256
  @State artists: Artist[] = []

  private artistDataSource: GenericLazyDataSource<Artist> = new GenericLazyDataSource();

  build() {
    Column() {
      Grid() {
        LazyForEach(this.artistDataSource, (artist: Artist, index) => {
          GridItem() {
            Button({ type: ButtonType.Normal }) {
              Column() {
                Image(this.baseURL + this.getCoverUrl + this.auth + `&id=${artist.id}&size=${this.profileSize}`)
                  .alt($rawfile('noprofile.jpg'))
                  .objectFit(ImageFit.Cover)
                  .width('100%')
                  .aspectRatio(1)
                  .borderRadius(100)
                  .margin({ top: 10, left: 10, right: 10 })
                Text(artist.name)
                  .width('100%')
                  .fontSize(16)
                  .fontColor($r('app.color.font'))
                  .margin(10)
                  .maxLines(1)
                  .textAlign(TextAlign.Center)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%')
              .height('auto')
            }
            .width('100%')
            .height('auto')
            .margin({ bottom: this.startPlaying === true && index === this.artists.length - 1 ? 85 : 0 })
            .animation({ curve: curves.springMotion(0.6, 1) })
            .borderRadius(10)
            .backgroundColor('#00000000')
            .onClick(async () => {
              animateTo({
                duration: 300,
                curve: Curve.EaseOut,
              }, () => {
                this.showSidebar = false
              })
              this.artist = artist
              this.pageStack.pushPathByName('ArtistDetail', null);
            })
          }
        })
      }
      .width('100%')
      .height('100%')
      .columnsTemplate(this.displayWidth > 1000 ? "1fr 1fr 1fr 1fr 1fr" : "1fr 1fr 1fr")
      .columnsGap(0)
      .rowsGap(0)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Fade)
      .padding({ left: 10, right: 10, bottom: 10 })
      .visibility(this.artists.length > 0 ? Visibility.Visible : Visibility.None)

      Column() {
        Text("没有艺术家")
          .fontSize(32)
          .fontColor($r('app.color.font'))
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .visibility(this.artists.length === 0 && this.serverStatus === true ? Visibility.Visible : Visibility.None)
    }
    .width('100%')
    .height('100%')
    .onVisibleAreaChange(
      // Define thresholds: e.g., [0.0, 0.1, 0.9, 1.0] or just a single value
      // Using [0.01] triggers when it becomes even slightly visible
      [0.01],
      // Callback function
      async (isVisible: boolean, currentRatio: number) => {
        console.log(`ArtistsComponent Visibility Changed: isVisible=${isVisible}, currentRatio=${currentRatio.toFixed(2)}`);
        // Check if component is becoming visible and data hasn't been loaded yet
        if (isVisible && currentRatio > 0) {
          // Call the data fetching function
          console.log('Loading remote artists...')
          this.artists = await getIndexes(this.baseURL, this.username, this.password)
          this.artistDataSource.updateData(this.artists);
          console.log('Fetched')
        }
        // Note: We check 'this.hasLoaded' inside the fetch function too,
        // but checking here prevents unnecessary calls to the async function itself.
      }
    )
  }
}