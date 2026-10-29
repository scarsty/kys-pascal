// Shared native event interpreter: SDL and headless frontends run the same opcodes.
#include "kys_script.h"
#include "kys_frontend.h"
#include "kys_main.h"
#include "kys_event.h"
#include "kys_engine.h"
#include "kys_draw.h"
#include <cstring>
#include <stdexcept>
#include <vector>

void CallEvent(int num)
{
    if (num < 0 || num >= static_cast<int>(KIdx.size()))
        throw std::runtime_error("Invalid event script: " + std::to_string(num));
    SStep = 0;
    SceneRolePic = BEGIN_WALKPIC + SFace * 7;
    NeedRefreshScene = 0;

    auto RunKDefEvent = [&]()
    {
        int offset, len;
        if (num == 0)
        {
            offset = 0;
            len = KIdx[0];
        }
        else
        {
            offset = KIdx[num - 1];
            len = KIdx[num] - offset;
        }
        if (offset < 0 || len < 0 || len % 2 != 0 || static_cast<size_t>(offset) + len > KDef.size())
            throw std::runtime_error("Invalid event byte range: script " + std::to_string(num));
        int ecount = len / 2 + 1;
        std::vector<int16_t> e(ecount, 0);
        if (len > 0)
        {
            memcpy(e.data(), KDef.data() + offset, len);
        }
        int i = 0;

        while (i >= 0 && i < ecount - 1)
        {
            if (Frontend) Frontend->instruction(num, i, e[i]);
            else { SDL_PollEvent(&event); CheckBasicEvent(); }
            if (e[i] < 0)
            {
                break;
            }
            if (e[i] >= EventWidths.size() || i + EventWidths[e[i]] > len / 2)
                throw std::runtime_error("Invalid/truncated event opcode at script " + std::to_string(num) + " pc " + std::to_string(i));
            switch (e[i])
            {
            case 0:
                instruct_0();
                i += 1;
                break;
            case 1:
                instruct_1(e[i + 1], e[i + 2], e[i + 3]);
                i += 4;
                break;
            case 2:
                instruct_2(e[i + 1], e[i + 2]);
                i += 3;
                break;
            case 3:
            {
                std::vector<int> list(13);
                for (int j = 0; j < 13; j++)
                {
                    list[j] = e[i + 1 + j];
                }
                instruct_3(list);
                i += 14;
                break;
            }
            case 4:
                i += instruct_4(e[i + 1], e[i + 2], e[i + 3]);
                i += 4;
                break;
            case 5:
                i += instruct_5(e[i + 1], e[i + 2]);
                i += 3;
                break;
            case 6:
                i += instruct_6(e[i + 1], e[i + 2], e[i + 3], e[i + 4]);
                i += 5;
                break;
            case 7:
                i += 1;
                return;
            case 8:
                instruct_8(e[i + 1]);
                i += 2;
                break;
            case 9:
                i += instruct_9(e[i + 1], e[i + 2]);
                i += 3;
                break;
            case 10:
                instruct_10(e[i + 1]);
                i += 2;
                break;
            case 11:
                i += instruct_11(e[i + 1], e[i + 2]);
                i += 3;
                break;
            case 12:
                instruct_12();
                i += 1;
                break;
            case 13:
                instruct_13();
                i += 1;
                break;
            case 14:
                instruct_14();
                i += 1;
                break;
            case 15:
                instruct_15();
                i += 1;
                return;
            case 16:
                i += instruct_16(e[i + 1], e[i + 2], e[i + 3]);
                i += 4;
                break;
            case 17:
            {
                std::vector<int> list(5);
                for (int j = 0; j < 5; j++)
                {
                    list[j] = e[i + 1 + j];
                }
                instruct_17(list);
                i += 6;
                break;
            }
            case 18:
                i += instruct_18(e[i + 1], e[i + 2], e[i + 3]);
                i += 4;
                break;
            case 19:
                instruct_19(e[i + 1], e[i + 2]);
                i += 3;
                break;
            case 20:
                i += instruct_20(e[i + 1], e[i + 2]);
                i += 3;
                break;
            case 21:
                instruct_21(e[i + 1]);
                i += 2;
                break;
            case 22:
                instruct_22();
                i += 1;
                break;
            case 23:
                instruct_23(e[i + 1], e[i + 2]);
                i += 3;
                break;
            case 24:
                instruct_24();
                i += 1;
                break;
            case 25:
                instruct_25(e[i + 1], e[i + 2], e[i + 3], e[i + 4]);
                i += 5;
                break;
            case 26:
                instruct_26(e[i + 1], e[i + 2], e[i + 3], e[i + 4], e[i + 5]);
                i += 6;
                break;
            case 27:
                instruct_27(e[i + 1], e[i + 2], e[i + 3]);
                i += 4;
                break;
            case 28:
                i += instruct_28(e[i + 1], e[i + 2], e[i + 3], e[i + 4], e[i + 5]);
                i += 6;
                break;
            case 29:
                i += instruct_29(e[i + 1], e[i + 2], e[i + 3], e[i + 4], e[i + 5]);
                i += 6;
                break;
            case 30:
                instruct_30(e[i + 1], e[i + 2], e[i + 3], e[i + 4]);
                i += 5;
                break;
            case 31:
                i += instruct_31(e[i + 1], e[i + 2], e[i + 3]);
                i += 4;
                break;
            case 32:
                instruct_32(e[i + 1], e[i + 2]);
                i += 3;
                break;
            case 33:
                instruct_33(e[i + 1], e[i + 2], e[i + 3]);
                i += 4;
                break;
            case 34:
                instruct_34(e[i + 1], e[i + 2]);
                i += 3;
                break;
            case 35:
                instruct_35(e[i + 1], e[i + 2], e[i + 3], e[i + 4]);
                i += 5;
                break;
            case 36:
                i += instruct_36(e[i + 1], e[i + 2], e[i + 3]);
                i += 4;
                break;
            case 37:
                instruct_37(e[i + 1]);
                i += 2;
                break;
            case 38:
                instruct_38(e[i + 1], e[i + 2], e[i + 3], e[i + 4]);
                i += 5;
                break;
            case 39:
                instruct_39(e[i + 1]);
                i += 2;
                break;
            case 40:
                instruct_40(e[i + 1]);
                i += 2;
                break;
            case 41:
                instruct_41(e[i + 1], e[i + 2], e[i + 3]);
                i += 4;
                break;
            case 42:
                i += instruct_42(e[i + 1], e[i + 2]);
                i += 3;
                break;
            case 43:
                i += instruct_43(e[i + 1], e[i + 2], e[i + 3]);
                i += 4;
                break;
            case 44:
                instruct_44(e[i + 1], e[i + 2], e[i + 3], e[i + 4], e[i + 5], e[i + 6]);
                i += 7;
                break;
            case 45:
                instruct_45(e[i + 1], e[i + 2]);
                i += 3;
                break;
            case 46:
                instruct_46(e[i + 1], e[i + 2]);
                i += 3;
                break;
            case 47:
                instruct_47(e[i + 1], e[i + 2]);
                i += 3;
                break;
            case 48:
                instruct_48(e[i + 1], e[i + 2]);
                i += 3;
                break;
            case 49:
                instruct_49(e[i + 1], e[i + 2]);
                i += 3;
                break;
            case 50:
            {
                std::vector<int> list(7);
                for (int j = 0; j < 7; j++)
                {
                    list[j] = e[i + 1 + j];
                }
                int p = instruct_50(list);
                i += 8;
                if (p < 622592)
                {
                    i += p;
                }
                else
                {
                    e[i + ((p + 32768) / 655360) - 1] = p % 655360;
                }
                break;
            }
            case 51:
                instruct_51();
                i += 1;
                break;
            case 52:
                instruct_52();
                i += 1;
                break;
            case 53:
                instruct_53();
                i += 1;
                break;
            case 54:
                instruct_54();
                i += 1;
                break;
            case 55:
                i += instruct_55(e[i + 1], e[i + 2], e[i + 3], e[i + 4]);
                i += 5;
                break;
            case 56:
                instruct_56(e[i + 1]);
                i += 2;
                break;
            case 57:
                instruct_57();
                i += 1;
                break;
            case 58:
                instruct_58();
                i += 1;
                break;
            case 59:
                instruct_59();
                i += 1;
                break;
            case 60:
                i += instruct_60(e[i + 1], e[i + 2], e[i + 3], e[i + 4], e[i + 5]);
                i += 6;
                break;
            case 61:
                i += instruct_61(e[i + 1], e[i + 2]);
                i += 3;
                break;
            case 62:
                instruct_62(e[i + 1], e[i + 2], e[i + 3], e[i + 4], e[i + 5], e[i + 6]);
                i += 7;
                return;
            case 63:
                instruct_63(e[i + 1], e[i + 2]);
                i += 3;
                break;
            case 64:
                instruct_64();
                i += 1;
                break;
            case 65: i += 1; break;    // NOP
            case 66:
                instruct_66(e[i + 1]);
                i += 2;
                break;
            case 67:
                instruct_67(e[i + 1]);
                i += 2;
                break;
            default: i += 1; break;
            }
        }
    };

    RunKDefEvent();

    if (Headless()) { NeedRefreshScene = 1; return; }
    if (NeedRefreshScene == 1)
    {
        InitialScene(0);
    }
    NeedRefreshScene = 1;
    if (MMAPAMI * SCENEAMI == 0)
    {
        Redraw();
        UpdateScreen(screen, 0, 0, ScreenWidth(), ScreenHeight());
    }
}
