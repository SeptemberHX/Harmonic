import { curves, window } from "@kit.ArkUI";
import { getLyrics, getStarred, searchEverything } from "../utils/Api";
import { Album, Artist, Playlist, SearchList, Song, StructuredLyric, Line } from "../utils/Interface";
import { media } from "@kit.MediaKit";
import { avSession as AVSessionManager } from '@kit.AVSessionKit';

@Component
export default struct SearchPage {

  @State searchText: string = ''
  @State statusBarHeight: number = 0
  @State songList: Song[] = []
  @State albumList: Album[] = []
  @State artistList: Artist[] = []

  @Consume showSearch: boolean

  @StorageLink('baseURL') baseURL: string = ''
  @StorageLink('username') username: string = ''
  @StorageLink('password') password: string = ''

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
  @Consume auth: string
  @Consume getCoverUrl: string
  @State albumPerRow: number = 3
  @State profileSize: number = 256
  @State coverSize: number = 256
  @Consume displayWidth: number
  @Consume pageStack: NavPathStack
  @Consume artist: Artist | null
  @Consume album: Album
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

  private getStatusBarHeight() {
    window.getLastWindow(getContext(this), (error, topWindow) => {
      if (topWindow) {
        let area = topWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
        this.statusBarHeight = px2vp(area.topRect.height)
      }
    });
  }

  async aboutToAppear() {
    this.getStatusBarHeight()
  }

  build() {
    Column() {
      Row() {
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.up'))
            .width(30)
            .height(30)
        }
        .width(40)
        .height(40)
        .backgroundColor('#00000000')
        .onClick(() => {
          if (this.showSearch === false) {
            this.showSearch = true
          }
          this.showSearch = false
        })

        Search({ value: this.searchText })
          .layoutWeight(1)
          .onSubmit(async (value: string) => {
            let searchResult: SearchList | null = await searchEverything(this.baseURL, this.username, this.password, value)
            if (searchResult) {
              this.songList = searchResult.song ?? [];
              this.albumList = searchResult.album ?? [];
              this.artistList = searchResult.artist ?? [];
            } else {
              this.songList = []
              this.albumList = []
              this.artistList = []
            }
          })
      }
      .padding({ left: 15, right: 15 })
      .width('100%')

      Tabs() {
        TabContent() {
          Column() {
            Grid() {
              ForEach(this.albumList, (album: Album, index) => {
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
            .visibility(this.albumList.length > 0 ? Visibility.Visible : Visibility.None)

            Text("这里空空如也")
              .fontSize(20)
              .fontColor($r('app.color.font'))
              .visibility(this.albumList.length == 0 ? Visibility.Visible : Visibility.None)
          }
        }
        .tabBar('专辑')

        TabContent() {
          Column() {
            List() {
              ForEach(this.songList, (song: Song, index) => {
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
            .visibility(this.songList.length > 0 ? Visibility.Visible : Visibility.None)

            Text("这里空空如也")
              .fontSize(20)
              .fontColor($r('app.color.font'))
              .visibility(this.songList.length == 0 ? Visibility.Visible : Visibility.None)
          }
        }
        .tabBar('歌曲')

        TabContent() {
          Column() {
            Grid() {
              ForEach(this.artistList, (artist: Artist, index) => {
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
                  .margin({ bottom: this.startPlaying === true && index === this.artistList.length - 1 ? 85 : 0 })
                  .animation({ curve: curves.springMotion(0.6, 1) })
                  .borderRadius(10)
                  .backgroundColor('#00000000')
                  .onClick(async () => {
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
            .edgeEffect(EdgeEffect.Fade)
            .padding({ left: 10, right: 10, bottom: 10 })
            .visibility(this.artistList.length > 0 ? Visibility.Visible : Visibility.None)

            Text("这里空空如也")
              .fontSize(20)
              .fontColor($r('app.color.font'))
              .visibility(this.artistList.length == 0 ? Visibility.Visible : Visibility.None)
          }
        }
        .tabBar('艺术家')
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding({ top: this.statusBarHeight })
    .justifyContent(FlexAlign.Start)
    .backgroundColor($r('app.color.content_background'))
  }
}
