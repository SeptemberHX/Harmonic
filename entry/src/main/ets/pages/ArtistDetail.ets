import { Album, Artist, Playlist, Song, StructuredLyric, Line } from '../utils/Interface';
import { curves } from '@kit.ArkUI';
import { getArtistAlbums, getArtistSongs, getLyrics, getStarred } from '../utils/Api';
import { media } from '@kit.MediaKit';
import { avSession as AVSessionManager } from '@kit.AVSessionKit';

@Builder
export function ArtistDetailBuilder() {
  ArtistDetail()
}

@Entry
@Component
export default struct ArtistDetail {
  @Consume playlist: Playlist | null
  @Consume nowPlayingSong: Song | null
  @Consume nowPlayingLyrics: StructuredLyric | null
  @Consume nowPlayingLyricsByGroup: Line[][]
  @Consume nowPlayingList: Song[]
  @Consume nowPlayingListOriginal: Song[]
  @Consume nowPlayingIndex: number
  @Consume starredSongs: Song[]
  @Consume nowPlayingStar: boolean
  @Consume isPlaying: boolean
  @Consume startPlaying: boolean
  @Consume avPlayer: media.AVPlayer | null
  @Consume showMenu: boolean
  @Consume longPressSong: Song | null
  @Consume longPressStar: boolean
  @Consume longPressIndex: number
  @StorageLink('playMode') playMode: number = 0
  @Consume session: AVSessionManager.AVSession | null

  @Consume displayWidth: number
  @Consume pageStack: NavPathStack
  @Consume showControlButton: boolean
  @StorageLink('baseURL') baseURL: string = ''
  @StorageLink('username') username: string = ''
  @StorageLink('password') password: string = ''
  @Consume salt: string
  @Consume version: string
  @Consume client: string
  @Consume auth: string
  @Consume getCoverUrl: string
  @Consume artist: Artist | null
  @Consume album: Album
  @State albumPerRow: number = 3
  @State profileSize: number = 256
  @State coverSize: number = 256

  private artistSongs: Song[] = []

  groupLyrics() {
    this.nowPlayingLyricsByGroup = []
    let index = -1
    for (let line of this.nowPlayingLyrics!.line) {
      if (this.nowPlayingLyricsByGroup.length === 0 || line.start !== this.nowPlayingLyricsByGroup[index][0].start) {
        index++
        this.nowPlayingLyricsByGroup.push([])
        this.nowPlayingLyricsByGroup[index].push(line)
      } else {
        this.nowPlayingLyricsByGroup[index].push(line)
      }
    }
  }

  getNowPlayingIndex(song: Song, list: Song[]) {
    for (let index = 0; index < list.length; index++) {
      if (list[index].id === song.id) {
        this.nowPlayingIndex = index
        break;
      }
    }
  }

  async getStar(song: Song) {
    let starredSongs: Song[] = []
    let starred = await getStarred(this.baseURL, this.username, this.password)
    if (starred !== null) {
      starredSongs = starred!.song!
    }
    if (starredSongs.length > 0) {
      for (let starredSong of starredSongs) {
        if (song.id === starredSong.id) {
          return true
        }
      }
    }
    return false
  }

  shuffleList<T>(array: T[]): T[] {
    for (let i = array.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      let temp = array[i];
      array[i] = array[j];
      array[j] = temp;
    }
    return array;
  }

  async aboutToAppear(): Promise<void> {
    if (this.artist) {
      this.artist.album = await getArtistAlbums(this.baseURL, this.username, this.password, this.artist.id);
    }
  }

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          Image(this.baseURL + this.getCoverUrl + this.auth + `&id=${this.artist!.id}&size=${this.profileSize}`)
            .alt($rawfile('noprofile.jpg'))
            .objectFit(ImageFit.Cover)
            .width(120)
            .aspectRatio(1)
            .borderRadius(100)
          Column() {
            Text(this.artist!.name)
              .fontSize(24)
              .fontColor($r('app.color.font'))
              .fontWeight(FontWeight.Bold)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.artist!.biography)
              .fontSize(18)
              .fontColor($r('app.color.font_secondary'))
              .margin({ top: 10 })
              .maxLines(3)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .textAlign(TextAlign.JUSTIFY)
          }
          .width('100%')
          .height('auto')
          .padding({
            top: 20,
            bottom: 20,
            left: 40,
            right: 40
          })

          Divider()
            .width('90%')
            .height(1)
            .color($r('app.color.divider'))

          Tabs() {
            TabContent() {
              Grid() {
                ForEach(this.artist!.album, (album: Album, index) => {
                  GridItem() {
                    Button({ type: ButtonType.Normal }) {
                      Column() {
                        Image(this.baseURL + this.getCoverUrl + this.auth + `&id=${album.id}&size=${this.coverSize}`)
                          .alt($rawfile('nocover.png'))
                          .objectFit(ImageFit.Contain)
                          .width('100%')
                          .aspectRatio(1)
                          .borderRadius(10)
                          .margin(10)
                      }
                      .width('100%')
                      .aspectRatio(1)
                    }
                    .width('100%')
                    .aspectRatio(1)
                    .borderRadius(10)
                    .backgroundColor('#00000000')
                    .onClick(() => {
                      this.album = album
                      this.pageStack.replacePathByName('AlbumDetail', null);
                    })
                  }
                })
              }
              .width('100%')
              .columnsTemplate(this.displayWidth > 1000 ? "1fr 1fr 1fr 1fr 1fr" : "1fr 1fr 1fr")
              .columnsGap(0)
              .rowsGap(0)
              .scrollBar(BarState.Off)
              .edgeEffect(EdgeEffect.Fade)
              .padding({ left: 10, right: 10, bottom: 10 })
            }
            .tabBar('专辑')

            TabContent() {
              List() {
                ForEach(this.artistSongs, (song: Song, index) => {
                  ListItem() {
                    Row() {
                      Text((index + 1).toString())
                        .fontSize(18)
                        .fontColor($r('app.color.font_secondary'))
                        .width(70)
                        .textAlign(TextAlign.Center)
                      Image(this.baseURL + this.getCoverUrl + this.auth + `&id=${song.id}&size=${this.coverSize}`)
                        .alt($rawfile('nocover.png'))
                        .objectFit(ImageFit.Contain)
                        .width(60)
                        .aspectRatio(1)
                        .borderRadius(5)
                      Column() {
                        Text(song.title)
                          .fontSize(18)
                          .fontColor($r('app.color.font'))
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                        Text(song.artist)
                          .fontSize(15)
                          .fontColor($r('app.color.font_secondary'))
                          .margin({ top: 5 })
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                      }
                      .alignItems(HorizontalAlign.Start)
                      .padding({ left: 15, right: 15 })
                      .width('100%')
                      .layoutWeight(1)
                    }
                    .width('100%')
                    .height('100%')
                  }
                  .width('100%')
                  .height(80)
                  .borderRadius(10)
                  .backgroundColor('#00000000')
                  .onClick(async () => {
                    this.startPlaying = true
                    await this.avPlayer!.reset()
                    this.isPlaying = true
                    this.nowPlayingSong = song
                    this.nowPlayingLyrics = await getLyrics(this.baseURL, this.username, this.password, song.id)

                    console.log(this.nowPlayingLyrics?.lang)

                    if (this.nowPlayingLyrics !== null) {
                      this.groupLyrics()
                    }

                    this.nowPlayingListOriginal = this.artistSongs!.slice()
                    if (this.playMode === AVSessionManager.LoopMode.LOOP_MODE_SHUFFLE) {
                      this.nowPlayingList = this.shuffleList(this.nowPlayingListOriginal.slice())
                    } else {
                      this.nowPlayingList = this.nowPlayingListOriginal.slice()
                    }

                    console.log(this.nowPlayingSong.title)

                    this.getNowPlayingIndex(song, this.nowPlayingList)
                    this.nowPlayingStar = await this.getStar(song)
                    this.avPlayer!.url = this.baseURL + '/rest/stream' + this.auth + `&id=${song.id}&format=raw`;
                  })
                  .gesture(
                    LongPressGesture()
                      .onAction(async (event: GestureEvent) => {
                        this.longPressSong = song
                        this.longPressIndex = index
                        this.showMenu = true
                        this.longPressStar = await this.getStar(song)
                      })
                  )
                })
              }
              .width('100%')
              .height('100%')
              .listDirection(Axis.Vertical)
              .edgeEffect(EdgeEffect.Fade)
            }
            .tabBar('歌曲')
          }
          .layoutWeight(1)
        }
        .width('100%')
        .height('auto')
      }
      .width('100%')
      .height('100%')
      .padding({ bottom: this.startPlaying === true ? 85 : 0 })
      .animation({ curve: curves.springMotion(0.6, 1) })
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .backgroundColor($r('app.color.content_background'))
    .onVisibleAreaChange(
      // Define thresholds: e.g., [0.0, 0.1, 0.9, 1.0] or just a single value
      // Using [0.01] triggers when it becomes even slightly visible
      [0.01],
      // Callback function
      async (isVisible: boolean, currentRatio: number) => {
        console.log(`ArtistDetailComponent Visibility Changed: isVisible=${isVisible}, currentRatio=${currentRatio.toFixed(2)}`);
        // Check if component is becoming visible and data hasn't been loaded yet
        if (isVisible && currentRatio > 0) {
          // Call the data fetching function
          console.log('Loading remote artist detail...')
          this.artistSongs = await getArtistSongs(this.baseURL, this.username, this.password, this.artist!.name)
          console.log('Fetched')
        }
        // Note: We check 'this.hasLoaded' inside the fetch function too,
        // but checking here prevents unnecessary calls to the async function itself.
      }
    )
  }
}