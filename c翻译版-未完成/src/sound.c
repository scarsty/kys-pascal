/*******************************************************************************
* sound.c                                                   fileencoding=UTF-8 *
*******************************************************************************/

#include "claim.h"

/*******************************************************************************
* Headers                                                                      *
*******************************************************************************/

#include "game.h"

/*******************************************************************************
* Global Variables                                                             *
*******************************************************************************/

Mix_Music* g_music = NULL;
Mix_Chunk* g_sound = NULL;		//声音
int exitScenceMusicNum = 0;
//离开场景的音乐
char musicName[256] = {0};

/*******************************************************************************
* Static Function Declare                                                      *
*******************************************************************************/


/*******************************************************************************
* Functions                                                                    *
*******************************************************************************/

//初始化音频系统
void InitialAudio()
{
	if (SDL_Init(SDL_INIT_AUDIO) < 0) {
		printf("Can't initialize SDL : %s\n",  SDL_GetError());
		SDL_Quit();
		exit(1);
	}

	Mix_OpenAudio(MIX_DEFAULT_FREQUENCY, MIX_DEFAULT_FORMAT, 2, 4096);
	g_music = NULL;
}

void CloseAudio()
{
	if (g_sound) Mix_FreeChunk(g_sound);
	if (g_music) Mix_FreeMusic(g_music);
}

//播放音乐
void PlayXMI(int index, int times)
{
	char str[PATH_MAX];
	sprintf(str, "game%02d.xmi", index);

	if (g_music) Mix_FreeMusic(g_music);
	g_music = Mix_LoadMUS(str);
	Mix_VolumeMusic(MIX_MAX_VOLUME / 3);
	Mix_PlayMusic(g_music, times);
}

#if 0
void PlayMP3(filename: pchar; int times = 0); overload()
{
	if (fileexists(filename))
	{
		g_music = Mix_LoadMUS(filename);
		Mix_volumemusic(MIX_MAX_VOLUME / 3);
		Mix_PlayMusic(g_music, times);
	}
}
#endif

//停止当前播放的音乐
void StopXMI()
{
	if (g_music)
	{
		Mix_HaltMusic();
		Mix_FreeMusic(g_music);
		g_music = NULL;
	}
	//  Mix_HaltMusic;
	//Mix_CloseAudio;
}

//播放wav音效
void PlayWAV(int index, int times)
{
	char str[PATH_MAX];

	sprintf(str, "e%02d.wav", index);

	if (g_sound) Mix_FreeChunk(g_sound);
	g_sound = Mix_LoadWAV(str);
	Mix_PlayChannel(-1, g_sound, times);
}

#if 0
void int PlaySound(SoundNum = 0); overload()
var
int i = 0;
str: string;
{
	str = "g_sound/e" + format("%2d", [soundnum]) + ".wav";
	for i = 1 to length(str) do
		if (str[i] == " ") str[i] = "0";
	if (fileexists(pchar(str)))
	{
		g_sound = Mix_LoadWav(pchar(str));
		Mix_PlayChannel(-1, g_sound, 0);
	}
}
#endif

void PlayWAVFile(char* filename, int times)
{
	if (filename) {
		g_sound = Mix_LoadWAV(filename);
		Mix_PlayChannel(-1, g_sound, times);
	}
}
