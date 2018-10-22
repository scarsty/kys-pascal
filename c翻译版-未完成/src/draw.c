/*******************************************************************************
* game.c                                                    fileencoding=UTF-8 *
*******************************************************************************/

#include "claim.h"

/*******************************************************************************
* Headers                                                                      *
*******************************************************************************/

#include "game.h"

#include "draw.h"

/*******************************************************************************
* Global Variables                                                             *
*******************************************************************************/

SDL_Surface* g_screenSurface = NULL;

//默认调色板数据
T_RGB g_palette[256];

uint32* g_faceIdxBuff = NULL;
byte* g_facePicBuff = NULL;

TTF_Font* g_HanFont = NULL;
uint16 g_HanFontSize = 20;

iconv_t g_utf8ToBig5 = 0;
iconv_t g_big5ToUtf8 = 0;

/*******************************************************************************
* Static Functions                                                             *
*******************************************************************************/

static uint32 GetRGBAPixel(uint8 color, uint8 alpha, int highlight);
static uint32 GetPalettePixel(SDL_PixelFormat* format, uint8 color, uint8 alpha, int highlight);
#define COLOR(c)		GetRGBAPixel((c), 255, 0)
#define COLORA(c, a)	GetRGBAPixel((c), (a), 0)
#define COLORH(c, h)	GetRGBAPixel((c), 255, (h))

/*******************************************************************************
* Functions                                                                    *
*******************************************************************************/

//初始化视频系统
void InitialVedio()
{
	if (SDL_Init(SDL_INIT_VIDEO) < 0) {
		printf("Can't initialize SDL : %s\n",  SDL_GetError());
		SDL_Quit();
		exit(1);
	}

	g_screenSurface = SDL_SetVideoMode(SCREEN_WIDTH, SCREEN_HEIGHT, 32,
		SDL_SWSURFACE | g_fullScreen ? SDL_FULLSCREEN : 0);

	if (g_screenSurface == NULL) {
		printf("Can't set %dx%d video mode : %s\n", SCREEN_WIDTH, SCREEN_HEIGHT, SDL_GetError());
		SDL_Quit();
		exit(1);
	}

	SDL_WM_SetCaption("金庸群侠传", "金庸群侠传");
}

void CloseVedio()
{
	TTF_CloseFont(g_HanFont);
	TTF_Quit();

	iconv_close(g_utf8ToBig5);
	iconv_close(g_big5ToUtf8);
}

static SDL_Color GetSDLColor(uint8 color)
{
	uint32 rgba = COLOR(color);
	SDL_Color sdlColor = {
		.r = (rgba & 0xff000000) >> 24,
		.g = (rgba & 0x00ff0000) >> 16,
		.b = (rgba & 0x0000ff00) >> 8
	};

	return sdlColor;
}

static uint32 GetRGBAPixel(uint8 color, uint8 alpha, int highlight)
{
	uint32 pixel = 0;

	pixel = (((g_palette[color].r << 2) + (g_palette[color].r >> 4) - highlight) << 24)
		+ (((g_palette[color].g << 2) + (g_palette[color].g >> 4) - highlight) << 16)
		+ (((g_palette[color].b << 2) + (g_palette[color].b >> 4) - highlight) << 8)
		+ alpha;

	return pixel;
}

static uint32 GetPalettePixel(SDL_PixelFormat* format, uint8 color, uint8 alpha, int highlight)
{
	uint32 pixel = 0;

	if (format) {
		pixel = SDL_MapRGBA(format,
			(g_palette[color].r << 2) + (g_palette[color].r >> 4) - highlight,
			(g_palette[color].g << 2) + (g_palette[color].g >> 4) - highlight,
			(g_palette[color].b << 2) + (g_palette[color].b >> 4) - highlight,
			alpha);
	}

	return pixel;
}

//画不含边框的矩形, 用于对话和黑屏
void DrawRectangle(int x, int y, int w, int h, uint8 color, uint8 alpha)
{
	boxColor(g_screenSurface, x, y, x + w, y + h, COLORA(color, alpha));
}

//画带边框矩形(x坐标, y坐标, 宽, 高, 内部颜色, 边框颜色, 透明度)
void DrawFrameRectangle(int x, int y, int w, int h, uint8 frmColor, uint8 insColor, uint8 alpha)
{
	sint16 vx[RECTANGLE_N] = {x + RECTANGLE_D, x + w - RECTANGLE_D, x + w, x + w, x + w - RECTANGLE_D, x + RECTANGLE_D, x, x};
	sint16 vy[RECTANGLE_N] = {y, y, y + RECTANGLE_D, y + h - RECTANGLE_D, y + h, y + h, y + h - RECTANGLE_D, y + RECTANGLE_D};

	filledPolygonColor(g_screenSurface, vx, vy, RECTANGLE_N, COLORA(insColor, alpha));
	polygonColor(g_screenSurface, vx, vy, RECTANGLE_N, COLOR(frmColor));
}

static void PutPixel(SDL_Surface* surface, int x, int y, uint32 pixel)
{
	if (surface && x >= 0 && x < surface->w && y >= 0 && y < surface->h) {
		byte* pixels = surface->pixels;
		*(uint32*)(pixels + y * surface->pitch + x * surface->format->BytesPerPixel) = pixel;
	}
}

//RLE8图片绘制子程，所有相关子程均对此封装
void DrawPic(SDL_Surface* surface, int index, int x, int y, uint32* idxBuffer, byte* picBuffer, int highlight)
{
	T_PicRect* picRect = NULL;
	byte* nextPicBuffer = NULL;

	if (idxBuffer && picBuffer) {
		if (index) {
			picBuffer += *(idxBuffer + index - 1);
		}

		picRect = (T_PicRect*)picBuffer;
		picBuffer += sizeof(T_PicRect);
		nextPicBuffer = picBuffer + *(idxBuffer + index);

		int l = x - picRect->dx;
		int t = y - picRect->dy;
		int r = x + picRect->w - picRect->dx;
		int b = y + picRect->h - picRect->dy;
		if (surface
			&& ((l < surface->w && t < surface->h) || (r >= 0 && b >= 0))) {
			uint8 px = 0;
			uint8 py = 0;
			for (py = 0; py < picRect->h; py++) {
				if (picBuffer < nextPicBuffer) {
					byte* nextLine = picBuffer + (uint8)*picBuffer + 1;
					picBuffer++;

					px = 0;
					while (picBuffer < nextLine) {
						px += *(picBuffer++);

						byte* next = picBuffer + (uint8)*picBuffer + 1;
						picBuffer++;
						for (; picBuffer < next; picBuffer++) {
							PutPixel(surface, l + px++, t + py, GetPalettePixel(surface->format, *picBuffer, 255, highlight));
						}
					}

					picBuffer = nextLine;
				}
			}
		}
	}
}

void DrawBigPicOnScreen(int index, byte* buffer)
{
	SDL_Surface* surface = NULL;
	int px;
	int py;

	if (buffer) {
		if ((surface = SDL_CreateRGBSurface(SDL_HWSURFACE, BIG_PIC_WIDTH, BIG_PIC_HEIGHT,
			32, 0xff000000, 0x00ff0000, 0x0000ff00, 0x00000000))) {
			buffer += index * BIG_PIC_SIZE;
			for (py = 0; py < BIG_PIC_HEIGHT; py++) {
				for (px = 0; px < BIG_PIC_WIDTH; px++) {
					PutPixel(surface, px, py, GetPalettePixel(surface->format, *(buffer++), 255, 0));
				}
			}

			float zoom = (float)SCREEN_WIDTH / BIG_PIC_WIDTH;
			int h = BIG_PIC_HEIGHT * zoom;
			int y = (SCREEN_HEIGHT - h) / 2;
			SDL_Surface* zoomedSurface = NULL;
			if ((zoomedSurface = zoomSurface(surface, zoom, zoom, TRUE))) {
				SDL_BlitSurface(zoomedSurface, NULL, g_screenSurface, &(SDL_Rect){0, y, SCREEN_WIDTH, SCREEN_HEIGHT});
				SDL_FreeSurface(zoomedSurface);
			}

			SDL_FreeSurface(surface);
		}
	}
}

#if 0
//获取场景中坐标在Buffer上的位置
static T_Position GetScenceBufferXYPos(int sx, int sy)
{
	T_Position pos = {.x = 0, .y = 0};
	pos.x = -sx * CELL_WIDTH / 2 + sy * CELL_WIDTH / 2 + SCENCE_PIC_WIDTH / 2;
	pos.y = sx * CELL_HEIGHT / 2 + sy * CELL_HEIGHT / 2 + CELL_HEIGHT / 2;

	return pos;
}

//获取屏幕原点在场景Pic中的坐标
static T_Position GetScreenPosInScence(int sx, int sy)
{
	T_Position pos = {.x = 0, .y = 0};
	pos.x = -sx * CELL_WIDTH / 2 + sy * CELL_WIDTH / 2 + SCENCE_PIC_WIDTH / 2 - SCREEN_CENTER_X;
	pos.y = sx * CELL_HEIGHT / 2 + sy * CELL_HEIGHT / 2 + CELL_HEIGHT / 2 - SCREEN_CENTER_Y;

	return pos;
}
#endif

//获取地图中坐标在屏幕上的位置(中心参照)
T_Position MapScenceXYToScreenPos(int mx, int my, int cx, int cy)
{
	T_Position pos = {.x = 0, .y = 0};
	pos.x = -(mx - cx) * CELL_WIDTH / 2 + (my - cy) * CELL_WIDTH / 2 + SCREEN_CENTER_X;
	pos.y = (mx - cx) * CELL_HEIGHT / 2 + (my - cy) * CELL_HEIGHT / 2 + SCREEN_CENTER_Y;

	return pos;
}

T_Position ScreenXYToMapScencePos(int x, int y, int cx, int cy)
{
	T_Position pos = {.x = 0, .y = 0};
	pos.x = -(x - SCREEN_CENTER_X) / CELL_WIDTH + (y - SCREEN_CENTER_Y) / CELL_HEIGHT + cx;
	pos.y = (x - SCREEN_CENTER_X) / CELL_WIDTH + (y - SCREEN_CENTER_Y) / CELL_HEIGHT + cy;

	return pos;
}

#if 0
//显示title.grp的内容(即开始的选单)
static void DrawTitlePic(int index, int x, int y)
{
	uint32* idxBuffer = NULL;
	byte* grpBuffer = NULL;

	idxBuffer = LoadFile("title.idx", NULL, 0);
	grpBuffer = LoadFile("title.grp", NULL, 0);

	if (idxBuffer && grpBuffer) {
		DrawPicOnScreen(index, x, y, idxBuffer, grpBuffer, 0);
		UpdateScreen(0);

		free(idxBuffer);
		free(grpBuffer);
	}
}
#endif

//显示头像
void DrawFacePic(int index, int x, int y)
{
	DrawPicOnScreen(index, x, y, g_faceIdxBuff, g_facePicBuff, 0);
}

#if 0
//仅在某区域显示战场图片

void DrawBFPicInRect(num, px, py, highlight, x, y, w, int h = 0)()
	var
	Area: TRect;
{
	Area.x = x;
	Area.y = y;
	Area.w = w;
	Area.h = h;
	DrawPic(num, px, py, @g_bfIdxBuff[0], @g_bfPicBuff[0], Area, NULL, highlight);

}

//将战场图片画到映像
static void DrawPicToBFPic(int index, int x, int y)
{
	DrawPic(g_bfSurface, index, x, y, g_bfIdxBuff, g_bfPicBuff, 0);
}

//显示效果图片
static void DrawEffect(int index, int x, int y)
{
	DrawPicOnScreen(index, x, y, g_effIdxBuff, g_effectBuff, 0);
}

//显示人物动作图片
static void DrawAction(int index, int x, int y)
{
	DrawPicOnScreen(index, x, y, g_actIdxBuff, g_actionBuff, 0);
}
#endif

//初始化字体
void InitialFont()
{
	g_utf8ToBig5 = iconv_open("BIG5", "UTF-8");
	g_big5ToUtf8 = iconv_open("UTF-8", "BIG5");

	TTF_Init();
	g_HanFont = TTF_OpenFont(HAN_FONT, g_HanFontSize);
	if (g_HanFont == NULL) {
		printf("Can\'t initialize font: %s\n", HAN_FONT);
		exit(-1);
	}
}

T_Position DrawText(char* str, int x, int y, uint8 color)
{
	T_Position pos = {.x = 0, .y = 0};

	SDL_Surface* text = TTF_RenderUTF8_Blended(g_HanFont, str, GetSDLColor(color));
	if (text) {
		pos.x = x + text->w;
		pos.y = y + text->h;

		SDL_BlitSurface(text, NULL, g_screenSurface, &(SDL_Rect){x, y, text->w, text->h});

		SDL_FreeSurface(text);
	}

	return pos;
}

//显示UTF8中文阴影文字, 即将同样内容显示2次, 间隔1像素
T_Position DrawShadowText(char* str, int x, int y, uint8 color)
{
	T_Position pos = {.x = 0, .y = 0};

	if (color >= 2) {
		DrawText(str, x + 1, y, color - 2);
	}

	pos = DrawText(str, x, y, color);

	return pos;
}

//显示big5阴影文字
T_Position DrawBig5ShadowText(char* big5, int x, int y, uint8 color)
{
	T_Position pos = {.x = 0, .y = 0};

	if (big5) {
		char* utf8 = Utf8ToBig5(big5);
		if (color >= 2) {
			DrawText(utf8, x + 1, y, color - 2);
		}
		pos = DrawText(utf8, x, y, color);
	}

	return pos;
}

//显示带边框的文字, 仅用于UTF8
void DrawFrameText(char* str, uint8 txtColor, uint8 frmColor)
{
	uint8 shdColor = txtColor >= 2 ? txtColor - 2 : 0xff;

	SDL_Surface* shadow = TTF_RenderUTF8_Blended(g_HanFont, str, GetSDLColor(shdColor));
	SDL_Surface* text = TTF_RenderUTF8_Blended(g_HanFont, str, GetSDLColor(txtColor));
	if (shadow && text) {
		int w = text->w + FRAME_TEXT_PADDING * 2 + 1;
		int h = text->h + FRAME_TEXT_PADDING * 2;
		int x = SCREEN_CENTER_X - w / 2;
		int y = SCREEN_CENTER_Y - h / 2;

		DrawFrameRectangle(x, y, w, h, frmColor, 0, FRAME_TEXT_ALPHA);
		//DrawFrameRectangle(x + 1, y + 1, text->w + FRAME_TEXT_PADDING * 2 + 1 -2 , text->h + FRAME_TEXT_PADDING * 2 - 2, frmColor, 0, FRAME_TEXT_ALPHA);

		SDL_BlitSurface(shadow, NULL, g_screenSurface, &(SDL_Rect){x + FRAME_TEXT_PADDING + 1, y + FRAME_TEXT_PADDING, g_screenSurface->w, g_screenSurface->h});
		SDL_BlitSurface(text, NULL, g_screenSurface, &(SDL_Rect){x + FRAME_TEXT_PADDING, y + FRAME_TEXT_PADDING, g_screenSurface->w, g_screenSurface->h});

		SDL_FreeSurface(shadow);
		SDL_FreeSurface(text);
	}
}

//显示
void DrawYesNoBox(char* boxStr[3], bool yesNo)
{
	SDL_Surface* title = TTF_RenderUTF8_Blended(g_HanFont, boxStr[0], GetSDLColor(TEXT_NORMAL_COLOR));

	SDL_Surface* yes = TTF_RenderUTF8_Blended(g_HanFont, boxStr[1], GetSDLColor(yesNo ? TEXT_SELECT_COLOR : TEXT_DESELECT_COLOR));
	SDL_Surface* no = TTF_RenderUTF8_Blended(g_HanFont, boxStr[2], GetSDLColor(!yesNo ? TEXT_SELECT_COLOR : TEXT_DESELECT_COLOR));

	SDL_Surface* slash = TTF_RenderUTF8_Blended(g_HanFont, " / ", GetSDLColor(TEXT_NORMAL_COLOR));

	if (title, yes && no && slash) {
		int w = max(title->w, yes->w + slash->w + no->w) + FRAME_TEXT_PADDING * 2;
		int h = title->h + FRAME_TEXT_PADDING + max(max(yes->h, slash->h), no->h) + FRAME_TEXT_PADDING * 2;
		int x = SCREEN_CENTER_X - w / 2;
		int y = SCREEN_CENTER_Y - h / 2;

		DrawFrameRectangle(x, y, w, h, TEXT_COLOR, 0, FRAME_TEXT_ALPHA);

		x += FRAME_TEXT_PADDING;
		y += FRAME_TEXT_PADDING;
		SDL_BlitSurface(title, NULL, g_screenSurface, &(SDL_Rect){x, y, g_screenSurface->w, g_screenSurface->h});

		y += title->h + FRAME_TEXT_PADDING;
		SDL_BlitSurface(yes, NULL, g_screenSurface, &(SDL_Rect){x, y, g_screenSurface->w, g_screenSurface->h});

		x += yes->w;
		SDL_BlitSurface(slash, NULL, g_screenSurface, &(SDL_Rect){x, y, g_screenSurface->w, g_screenSurface->h});

		x += slash->w;
		SDL_BlitSurface(no, NULL, g_screenSurface, &(SDL_Rect){x, y, g_screenSurface->w, g_screenSurface->h});

		SDL_FreeSurface(title);
		SDL_FreeSurface(yes);
		SDL_FreeSurface(no);
		SDL_FreeSurface(slash);
	} 
}

//显示BIG5文字
T_Position DrawBig5Text(char* big5, int x, int y, uint8 color)
{
	T_Position pos = {.x = 0, .y = 0};

	if (big5) {
		pos = DrawText(Big5ToUtf8(big5), x, y, color);
	}

	return pos;
}

//UTF8转为BIG5
char* Utf8ToBig5(char* utf8)
{
	static char big5[TEXT_BIG5_LEN];
	memset(big5, 0, TEXT_BIG5_LEN);

	if (utf8) {
		size_t utf8Len = strlen(utf8);
		size_t big5Len = TEXT_BIG5_LEN;

		char* in = utf8;
		char* out = big5;
		iconv(g_utf8ToBig5, &in, &utf8Len, &out, &big5Len);
	}

	return big5;
}

//big5转为UTF8
char* Big5ToUtf8(char* big5)
{
	static char utf8[TEXT_UTF8_LEN];
	memset(utf8, 0, TEXT_UTF8_LEN);

	if (big5) {
		size_t big5Len = strlen(big5);
		size_t utf8Len = TEXT_UTF8_LEN;

		char* in = big5;
		char* out = utf8;
		iconv(g_big5ToUtf8, &in, &big5Len, &out, &utf8Len);
	}

	return utf8;
}

void DrawTalk(char* str, int x, int y, int w, int h, int face, int fx, int fy, int tx, int ty, int tw, int th)
{
	byte character[3] = {'\0'};
	int currentTx = tx;
	int currentTy = ty;
	SDL_Surface* text = NULL;

	Redraw();
	DrawRectangle(x, y, w, h, 0, TALK_ALPHA);
	if (face > 0) {
		DrawFacePic(face, fx, fy);
	}

	while (*str) {
		if (*str < 0 && *(str + 1)) {
			character[0] = *(str++);
			character[1] = *str;
		} else {
			character[0] = *str;
			character[1] = (byte)'\0';
		}

		if ((text = TTF_RenderUTF8_Blended(g_HanFont, Big5ToUtf8((char*)character), GetSDLColor(TEXT_COLOR)))) {
			if (currentTx + text->w > tx + tw) {
				currentTx = tx;
				if ((currentTy += text->h) > ty + th) {
					UpdateScreen();
					WaitKey();
					currentTx = tx;
					currentTy = ty;
					Redraw();
					DrawRectangle(x, y, w, h, 0, TALK_ALPHA);
					if (face > 0) {
						DrawFacePic(face, fx, fy);
					}
				}
			}

			SDL_BlitSurface(text, NULL, g_screenSurface, &(SDL_Rect){currentTx, currentTy, text->w, text->h});
			SDL_FreeSurface(text);
			currentTx += text->w;
		}
		str++;
	}
	UpdateScreen();
	WaitKey();
}
