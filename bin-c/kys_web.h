#pragma once

#include <string>

bool WebEnterString(std::string& text);
void WebLoading(const char* label);
bool WebMusicReady(int track);
void WebDeferMusic(int track, int times, int fromBeginning);
void WebPollMusic();
void WebCancelMusic();
